import 'package:flutter/foundation.dart';
import '../providers/fuel_provider.dart';
import 'api_service.dart';

/// جسر تحويل بيانات API إلى نماذج Flutter المحلية والعكس
/// يدير: جلب البيانات من السيرفر، تحويلها، ومزامنتها مع FuelProvider
class ApiDataBridge {
  static final ApiDataBridge _instance = ApiDataBridge._();
  factory ApiDataBridge() => _instance;
  ApiDataBridge._();

  final ApiService _api = ApiService();
  bool _isOnline = false;
  bool get isOnline => _isOnline;

  // ===================================================================
  // فحص الاتصال بالسيرفر
  // ===================================================================
  Future<bool> checkConnection() async {
    _isOnline = await _api.checkHealth();
    debugPrint(_isOnline ? '🟢 متصل بالسيرفر' : '🔴 غير متصل بالسيرفر');
    return _isOnline;
  }

  // ===================================================================
  // تحميل الخزانات من API
  // ===================================================================
  Future<List<Tank>?> fetchTanks() async {
    try {
      final res = await _api.getTanks();
      if (!res.success || res.data == null) return null;
      final list = res.data as List;
      return list.map((m) => _apiTankToLocal(Map<String, dynamic>.from(m))).toList();
    } catch (e) {
      debugPrint('❌ خطأ تحميل الخزانات: $e');
      return null;
    }
  }

  Tank _apiTankToLocal(Map<String, dynamic> m) {
    final capacity = _toDouble(m['capacity']);
    final current = _toDouble(m['current_level']);
    final fillPct = capacity > 0 ? (current / capacity) * 100 : 0.0;
    TankStatus status;
    if (fillPct >= 80) { status = TankStatus.excellent; }
    else if (fillPct >= 50) { status = TankStatus.good; }
    else if (fillPct >= 25) { status = TankStatus.medium; }
    else { status = TankStatus.low; }

    return Tank(
      id: m['id'] ?? '',
      name: m['name'] ?? '',
      location: m['location'] ?? m['branch_name'] ?? '',
      fuelType: m['fuel_type'] ?? '',
      capacity: capacity,
      current: current,
      temperature: _toDouble(m['max_temperature'], 22.0),
      lastFill: DateTime.tryParse(m['last_fill']?.toString() ?? '') ?? DateTime.now(),
      status: status,
    );
  }

  // ===================================================================
  // تحميل معاملات الوقود (incoming records)
  // ===================================================================
  Future<List<IncomingRecord>?> fetchFuelTransactions({String? type, int limit = 100}) async {
    try {
      final res = await _api.getFuelTransactions(limit: limit, type: type);
      if (!res.success || res.data == null) return null;
      final list = res.data as List;
      return list.map((m) => _apiTransactionToIncoming(Map<String, dynamic>.from(m))).toList();
    } catch (e) {
      debugPrint('❌ خطأ تحميل المعاملات: $e');
      return null;
    }
  }

  IncomingRecord _apiTransactionToIncoming(Map<String, dynamic> m) {
    return IncomingRecord(
      id: m['id'] ?? '',
      date: DateTime.tryParse(m['created_at']?.toString() ?? '') ?? DateTime.now(),
      supplier: m['supplier'] ?? '',
      fuelType: m['fuel_type'] ?? '',
      quantity: _toDouble(m['quantity']),
      unitPrice: _toDouble(m['unit_price']),
      tankName: m['tank_name'] ?? '',
      driverName: m['driver_name'] ?? '',
      truckNumber: m['truck_number'] ?? '',
      status: _mapStatus(m['status']),
      color: m['color_rating']?.toString() ?? '2.0',
      density: _toDouble(m['density'], 0.85),
    );
  }

  String _mapStatus(dynamic s) {
    if (s == null) return 'معلق';
    switch (s.toString()) {
      case 'approved': return 'مكتمل';
      case 'pending': return 'معلق';
      case 'rejected': return 'مرفوض';
      default: return s.toString();
    }
  }

  // ===================================================================
  // تحميل إحصائيات الوقود
  // ===================================================================
  Future<Map<String, dynamic>?> fetchFuelStats() async {
    try {
      final res = await _api.getFuelStats();
      if (!res.success || res.data == null) return null;
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      debugPrint('❌ خطأ تحميل الإحصائيات: $e');
      return null;
    }
  }

  // ===================================================================
  // تحميل المستخدمين
  // ===================================================================
  Future<List<Map<String, dynamic>>?> fetchUsers() async {
    try {
      final res = await _api.getUsers();
      if (!res.success || res.data == null) return null;
      final list = res.data as List;
      return list.map((m) => Map<String, dynamic>.from(m)).toList();
    } catch (e) {
      debugPrint('❌ خطأ تحميل المستخدمين: $e');
      return null;
    }
  }

  // ===================================================================
  // تحميل الفروع
  // ===================================================================
  Future<List<Map<String, dynamic>>?> fetchBranches() async {
    try {
      final res = await _api.getBranches();
      if (!res.success || res.data == null) return null;
      final list = res.data as List;
      return list.map((m) => Map<String, dynamic>.from(m)).toList();
    } catch (e) {
      debugPrint('❌ خطأ تحميل الفروع: $e');
      return null;
    }
  }

  // ===================================================================
  // تحميل سجل العمليات (Audit)
  // ===================================================================
  Future<List<Map<String, dynamic>>?> fetchAuditLogs({int limit = 50}) async {
    try {
      final res = await _api.getAuditLogs(limit: limit);
      if (!res.success || res.data == null) return null;
      final list = res.data as List;
      return list.map((m) => Map<String, dynamic>.from(m)).toList();
    } catch (e) {
      debugPrint('❌ خطأ تحميل سجل العمليات: $e');
      return null;
    }
  }

  // ===================================================================
  // تحميل الاشتراك الحالي
  // ===================================================================
  Future<Map<String, dynamic>?> fetchCurrentSubscription() async {
    try {
      final res = await _api.getCurrentSubscription();
      if (!res.success || res.data == null) return null;
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      debugPrint('❌ خطأ تحميل الاشتراك: $e');
      return null;
    }
  }

  // ===================================================================
  // إنشاء معاملة وقود عبر API
  // ===================================================================
  Future<IncomingRecord?> createFuelTransaction({
    required String type,
    required String fuelType,
    required double quantity,
    double? unitPrice,
    String? supplier,
    String? tankId,
    String? destinationTankId,
    String? driverName,
    String? truckNumber,
    double? density,
    double? colorRating,
    String? notes,
  }) async {
    try {
      final res = await _api.createFuelTransaction(
        type: type,
        fuelType: fuelType,
        quantity: quantity,
        unitPrice: unitPrice,
        supplier: supplier,
        tankId: tankId,
        destinationTankId: destinationTankId,
        driverName: driverName,
        truckNumber: truckNumber,
        density: density,
        colorRating: colorRating,
        notes: notes,
      );
      if (!res.success || res.data == null) return null;
      return _apiTransactionToIncoming(Map<String, dynamic>.from(res.data));
    } catch (e) {
      debugPrint('❌ خطأ إنشاء معاملة: $e');
      return null;
    }
  }

  // ===================================================================
  // إنشاء/تعديل خزان عبر API
  // ===================================================================
  Future<Tank?> createTank({
    required String name,
    required String fuelType,
    required double capacity,
    double? currentLevel,
    String? location,
    String? branchId,
  }) async {
    try {
      final res = await _api.createTank(
        name: name,
        fuelType: fuelType,
        capacity: capacity,
        currentLevel: currentLevel,
        location: location,
        branchId: branchId,
      );
      if (!res.success || res.data == null) return null;
      return _apiTankToLocal(Map<String, dynamic>.from(res.data));
    } catch (e) {
      debugPrint('❌ خطأ إنشاء خزان: $e');
      return null;
    }
  }

  // ===================================================================
  // مزامنة شاملة مع FuelProvider
  // ===================================================================
  Future<SyncResult> syncAll(FuelProvider provider) async {
    final result = SyncResult();

    // فحص الاتصال أولاً
    final online = await checkConnection();
    if (!online) {
      result.error = 'السيرفر غير متاح';
      return result;
    }

    try {
      // 1) مزامنة الخزانات
      final tanks = await fetchTanks();
      if (tanks != null && tanks.isNotEmpty) {
        provider.updateTanksFromApi(tanks);
        result.tanksCount = tanks.length;
        debugPrint('✅ تم مزامنة ${tanks.length} خزان');
      }

      // 2) مزامنة معاملات الوقود (الوارد)
      final transactions = await fetchFuelTransactions(limit: 100);
      if (transactions != null && transactions.isNotEmpty) {
        provider.updateIncomingFromApi(transactions);
        result.transactionsCount = transactions.length;
        debugPrint('✅ تم مزامنة ${transactions.length} معاملة');
      }

      // 3) مزامنة الإحصائيات
      final stats = await fetchFuelStats();
      if (stats != null) {
        provider.updateStatsFromApi(stats);
        result.statsUpdated = true;
        debugPrint('✅ تم تحديث الإحصائيات');
      }

      result.success = true;
      result.syncTime = DateTime.now();
    } catch (e) {
      result.error = e.toString();
      debugPrint('❌ خطأ المزامنة: $e');
    }

    return result;
  }

  // ===================================================================
  // أدوات مساعدة
  // ===================================================================
  double _toDouble(dynamic v, [double fallback = 0.0]) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }
}

/// نتيجة عملية المزامنة
class SyncResult {
  bool success = false;
  String? error;
  int tanksCount = 0;
  int transactionsCount = 0;
  bool statsUpdated = false;
  DateTime? syncTime;

  @override
  String toString() => success
    ? '✅ مزامنة ناجحة: $tanksCount خزان، $transactionsCount معاملة'
    : '❌ فشل المزامنة: $error';
}

