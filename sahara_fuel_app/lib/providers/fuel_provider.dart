import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';
import '../services/api_data_bridge.dart';
import '../models/report_models.dart';
import '../models/union_transaction.dart' as union_model;

class FuelProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final ApiDataBridge _bridge = ApiDataBridge();
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;
  DateTime? _lastApiSync;
  DateTime? get lastApiSync => _lastApiSync;

  // ===== مزامنة مع API =====
  /// تحميل جميع البيانات من السيرفر
  Future<bool> syncWithApi() async {
    if (_isSyncing) return false;
    _isSyncing = true;
    notifyListeners();

    try {
      final result = await _bridge.syncAll(this);
      _lastApiSync = result.syncTime;
      _isSyncing = false;
      notifyListeners();
      debugPrint(result.toString());
      return result.success;
    } catch (e) {
      _isSyncing = false;
      notifyListeners();
      debugPrint('❌ خطأ المزامنة: $e');
      return false;
    }
  }

  /// تحديث الخزانات من API
  void updateTanksFromApi(List<Tank> apiTanks) {
    if (apiTanks.isEmpty) return;
    _tanks.clear();
    _tanks.addAll(apiTanks);
  }

  /// تحديث سجلات الوارد من API
  void updateIncomingFromApi(List<IncomingRecord> apiRecords) {
    if (apiRecords.isEmpty) return;
    _incomingRecords.clear();
    _incomingRecords.addAll(apiRecords);
  }

  /// تحديث الإحصائيات من API
  void updateStatsFromApi(Map<String, dynamic> stats) {
    final today = stats['today'];
    if (today != null) {
      final inc = today['today_incoming'];
      final out = today['today_outgoing'];
      if (inc != null)
        _todayIncoming = (inc is num)
            ? inc.toDouble()
            : double.tryParse(inc.toString()) ?? _todayIncoming;
      if (out != null)
        _todayOutgoing = (out is num)
            ? out.toDouble()
            : double.tryParse(out.toString()) ?? _todayOutgoing;
    }
  }

  /// إضافة شحنة وارد عبر API ثم محلياً
  Future<bool> addIncomingRecordViaApi({
    required String supplier,
    required String fuelType,
    required double quantity,
    required double unitPrice,
    required String tankId,
    required String tankName,
    required String driverName,
    required String truckNumber,
    String color = '2.0',
    double density = 0.85,
  }) async {
    if (!_api.hasToken) {
      // غير متصل، أضف محلياً
      addIncomingRecord(
          supplier: supplier,
          fuelType: fuelType,
          quantity: quantity,
          unitPrice: unitPrice,
          tankName: tankName,
          driverName: driverName,
          truckNumber: truckNumber,
          color: color,
          density: density);
      return true;
    }
    try {
      final record = await _bridge.createFuelTransaction(
        type: 'incoming',
        fuelType: fuelType,
        quantity: quantity,
        unitPrice: unitPrice,
        supplier: supplier,
        tankId: tankId,
        driverName: driverName,
        truckNumber: truckNumber,
        density: density,
        colorRating: double.tryParse(color),
      );
      if (record != null) {
        _incomingRecords.insert(0, record);
        _todayIncoming += quantity;
        _saharaBalance += quantity;
        _updateTankLevel(tankName, quantity);
        _recentActivities.insert(
            0,
            RecentActivity(
                type: ActivityType.incoming,
                description:
                    'استلام ${formatNumber(quantity)} لتر $fuelType - $supplier',
                amount: quantity,
                time: DateTime.now()));
        _notifications.insert(
            0,
            AppNotification(
                id: 'n_${DateTime.now().millisecondsSinceEpoch}',
                title: 'شحنة وارد جديدة',
                message:
                    'تم استلام ${formatNumber(quantity)} لتر $fuelType من $supplier',
                type: NotificationType.success,
                time: DateTime.now(),
                category: 'تحديثات'));
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('❌ خطأ إرسال معاملة API: $e');
    }
    // fallback للمحلي
    addIncomingRecord(
        supplier: supplier,
        fuelType: fuelType,
        quantity: quantity,
        unitPrice: unitPrice,
        tankName: tankName,
        driverName: driverName,
        truckNumber: truckNumber,
        color: color,
        density: density);
    return true;
  }

  final DatabaseService _db = DatabaseService();
  bool _dbReady = false;

  // ===== تحميل البيانات من قاعدة البيانات =====
  Future<void> loadFromDatabase() async {
    if (!_db.isInitialized) return;

    // تحميل الأرصدة
    if (_db.hasBalances()) {
      final b = _db.loadBalances();
      _saharaBalance = b['saharaBalance']!;
      _unionBalance = b['unionBalance']!;
      _stationsBalance = b['stationsBalance']!;
      _todayIncoming = b['todayIncoming']!;
      _todayOutgoing = b['todayOutgoing']!;
      _saharaChangePercent = b['saharaChange']!;
      _unionChangePercent = b['unionChange']!;
      _stationsChangePercent = b['stationsChange']!;
    }

    // تحميل الخزانات
    if (_db.hasTanks()) {
      _tanks.clear();
      _tanks.addAll(_db.loadTanks().map((m) => TankSerializer.fromMap(m)));
    }

    // تحميل سجلات الوارد
    if (_db.hasIncoming()) {
      _incomingRecords.clear();
      _incomingRecords.addAll(_db
          .loadIncomingRecords()
          .map((m) => IncomingRecordSerializer.fromMap(m)));
    }

    // تحميل الإشعارات
    final notifMaps = _db.loadNotifications();
    if (notifMaps.isNotEmpty) {
      _notifications.clear();
      _notifications
          .addAll(notifMaps.map((m) => NotificationSerializer.fromMap(m)));
    }

    // تحميل الأنشطة
    final actMaps = _db.loadActivities();
    if (actMaps.isNotEmpty) {
      _recentActivities.clear();
      _recentActivities
          .addAll(actMaps.map((m) => ActivitySerializer.fromMap(m)));
    }

    // تحميل تحويلات الاتحاد
    if (_db.hasUnionTransfers()) {
      _unionTransfers.clear();
      _unionTransfers.addAll(_db
          .loadUnionTransfers()
          .map((m) => UnionTransferSerializer.fromMap(m)));
    }

    // تحميل عمليات الخزانات
    final topMaps = _db.loadTankOperations();
    if (topMaps.isNotEmpty) {
      _tankOperations.clear();
      _tankOperations
          .addAll(topMaps.map((m) => TankOperationSerializer.fromMap(m)));
    }

    _dbReady = true;
    debugPrint('✅ تم تحميل البيانات من القاعدة');
    notifyListeners();
  }

  // ===== حفظ البيانات في قاعدة البيانات =====
  Future<void> _saveToDatabase() async {
    if (!_db.isInitialized || !_dbReady) return;
    try {
      await Future.wait([
        _db.saveBalances(
          saharaBalance: _saharaBalance,
          unionBalance: _unionBalance,
          stationsBalance: _stationsBalance,
          todayIncoming: _todayIncoming,
          todayOutgoing: _todayOutgoing,
          saharaChange: _saharaChangePercent,
          unionChange: _unionChangePercent,
          stationsChange: _stationsChangePercent,
        ),
        _db.saveTanks(_tanks.map((t) => TankSerializer.toMap(t)).toList()),
        _db.saveIncomingRecords(_incomingRecords
            .map((r) => IncomingRecordSerializer.toMap(r))
            .toList()),
        _db.saveNotifications(_notifications
            .map((n) => NotificationSerializer.toMap(n))
            .toList()),
        _db.saveActivities(
            _recentActivities.map((a) => ActivitySerializer.toMap(a)).toList()),
        _db.saveUnionTransfers(_unionTransfers
            .map((t) => UnionTransferSerializer.toMap(t))
            .toList()),
        _db.saveTankOperations(_tankOperations
            .map((o) => TankOperationSerializer.toMap(o))
            .toList()),
      ]);
    } catch (e) {
      debugPrint('⚠️ خطأ في الحفظ: $e');
    }
  }

  /// حفظ تلقائي مع كل تغيير
  @override
  void notifyListeners() {
    super.notifyListeners();
    _saveToDatabase();
  }

  // ===== أرصدة رئيسية =====
  double _saharaBalance = 12571853;
  double get saharaBalance => _saharaBalance;
  double _saharaChangePercent = 5;
  double get saharaChangePercent => _saharaChangePercent;

  double _unionBalance = 8500000;
  double get unionBalance => _unionBalance;
  double _unionChangePercent = -2;
  double get unionChangePercent => _unionChangePercent;

  double _stationsBalance = 4200000;
  double get stationsBalance => _stationsBalance;
  double _stationsChangePercent = 12;
  double get stationsChangePercent => _stationsChangePercent;

  double _todayIncoming = 85000;
  double get todayIncoming => _todayIncoming;
  double _todayOutgoing = 62000;
  double get todayOutgoing => _todayOutgoing;
  int _activeStations = 7;
  int get activeStations => _activeStations;
  int _totalStations = 8;
  int get totalStations => _totalStations;

  // ===== الخزانات =====
  final List<Tank> _tanks = [
    Tank(
        id: 't1',
        name: 'خزان الديزل الرئيسي',
        location: 'محطة الطاقة',
        fuelType: 'ديزل',
        capacity: 500000,
        current: 420000,
        temperature: 23.5,
        lastFill: DateTime(2026, 2, 10),
        status: TankStatus.excellent),
    Tank(
        id: 't2',
        name: 'خزان البنزين',
        location: 'محطة التسمين',
        fuelType: 'بنزين',
        capacity: 300000,
        current: 195000,
        temperature: 22.0,
        lastFill: DateTime(2026, 2, 8),
        status: TankStatus.good),
    Tank(
        id: 't3',
        name: 'خزان الكاز',
        location: 'محطة البوادي',
        fuelType: 'كاز',
        capacity: 250000,
        current: 125000,
        temperature: 24.1,
        lastFill: DateTime(2026, 2, 9),
        status: TankStatus.medium),
    Tank(
        id: 't4',
        name: 'خزان الديزل الاحتياطي',
        location: 'محطة البياض',
        fuelType: 'ديزل',
        capacity: 400000,
        current: 350000,
        temperature: 21.8,
        lastFill: DateTime(2026, 2, 11),
        status: TankStatus.excellent),
    Tank(
        id: 't5',
        name: 'خزان النفط الأبيض',
        location: 'محطة الأجداد',
        fuelType: 'كاز',
        capacity: 200000,
        current: 45000,
        temperature: 25.3,
        lastFill: DateTime(2026, 1, 28),
        status: TankStatus.low),
    Tank(
        id: 't6',
        name: 'خزان المحطة المركزية',
        location: 'المستودع المركزي',
        fuelType: 'ديزل',
        capacity: 600000,
        current: 480000,
        temperature: 22.7,
        lastFill: DateTime(2026, 2, 12),
        status: TankStatus.excellent),
  ];
  List<Tank> get tanks => List.unmodifiable(_tanks);

  // Get count of tanks with specific status
  int tanksWithStatus(TankStatus status) {
    return _tanks.where((tank) => tank.status == status).length;
  }

  final List<DailyConsumption> _dailyConsumption = List.generate(30, (i) {
    final base = 60000.0 + (i % 7 == 5 || i % 7 == 6 ? -15000 : 0);
    final variation = (i * 17 % 11) * 800.0;
    return DailyConsumption(
        date: DateTime.now().subtract(Duration(days: 29 - i)),
        consumed: base + variation,
        incoming: base + variation + 3000 + (i * 13 % 7) * 500);
  });
  List<DailyConsumption> get dailyConsumption =>
      List.unmodifiable(_dailyConsumption);

  List<MonthlyData> get monthlyData {
    return List.generate(12, (i) {
      final months = [
        'يناير',
        'فبراير',
        'مارس',
        'أبريل',
        'مايو',
        'يونيو',
        'يوليو',
        'أغسطس',
        'سبتمبر',
        'أكتوبر',
        'نوفمبر',
        'ديسمبر'
      ];
      final base = 1500000.0 + (i * 3 % 5) * 200000;
      return MonthlyData(
          month: months[i],
          incoming: base + (i * 7 % 4) * 150000,
          outgoing: base - (i * 5 % 3) * 100000,
          balance: _saharaBalance + (i - 6) * 500000);
    });
  }

  // ===== الإشعارات =====
  final List<AppNotification> _notifications = [
    AppNotification(
        id: 'n1',
        title: 'شحنة وارد جديدة',
        message: 'تم استلام 25,000 لتر ديزل من المزود الرئيسي',
        type: NotificationType.success,
        time: DateTime.now().subtract(const Duration(minutes: 15)),
        category: 'تحديثات'),
    AppNotification(
        id: 'n2',
        title: 'تنبيه مخزون منخفض',
        message: 'خزان النفط الأبيض في محطة الأجداد وصل لمستوى 22%',
        type: NotificationType.warning,
        time: DateTime.now().subtract(const Duration(hours: 2)),
        category: 'تنبيهات'),
    AppNotification(
        id: 'n3',
        title: 'خطأ في القراءة',
        message: 'فشل قراءة عداد الوقود في محطة البوادي',
        type: NotificationType.error,
        time: DateTime.now().subtract(const Duration(hours: 5)),
        category: 'نظام'),
    AppNotification(
        id: 'n4',
        title: 'تقرير شهري جاهز',
        message: 'تم إعداد تقرير شهر يناير بنجاح',
        type: NotificationType.info,
        time: DateTime.now().subtract(const Duration(hours: 12)),
        category: 'تحديثات'),
    AppNotification(
        id: 'n5',
        title: 'تحويل وقود',
        message: 'تم تحويل 15,000 لتر من المستودع المركزي إلى محطة التسمين',
        type: NotificationType.success,
        time: DateTime.now().subtract(const Duration(days: 1)),
        category: 'تحديثات'),
    AppNotification(
        id: 'n6',
        title: 'صيانة مجدولة',
        message: 'موعد صيانة خزان الديزل الرئيسي بعد 3 أيام',
        type: NotificationType.info,
        time: DateTime.now().subtract(const Duration(days: 1, hours: 6)),
        category: 'نظام'),
    AppNotification(
        id: 'n7',
        title: 'ارتفاع حرارة',
        message: 'ارتفاع درجة حرارة خزان الكاز في محطة البوادي إلى 28°C',
        type: NotificationType.warning,
        time: DateTime.now().subtract(const Duration(days: 2)),
        category: 'تنبيهات'),
    AppNotification(
        id: 'n8',
        title: 'اعتماد عملية',
        message: 'تمت الموافقة على طلب شراء 50,000 لتر بنزين',
        type: NotificationType.success,
        time: DateTime.now().subtract(const Duration(days: 2, hours: 4)),
        category: 'تحديثات'),
    AppNotification(
        id: 'n9',
        title: 'تحديث النظام',
        message: 'تم تحديث نظام المراقبة إلى الإصدار 2.1',
        type: NotificationType.info,
        time: DateTime.now().subtract(const Duration(days: 3)),
        category: 'نظام'),
    AppNotification(
        id: 'n10',
        title: 'تجاوز حد الاستهلاك',
        message: 'محطة التسمين تجاوزت حد الاستهلاك اليومي بنسبة 15%',
        type: NotificationType.error,
        time: DateTime.now().subtract(const Duration(days: 3, hours: 8)),
        category: 'تنبيهات'),
  ];
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadNotifications => _notifications.where((n) => !n.isRead).length;

  final List<RecentActivity> _recentActivities = [
    RecentActivity(
        type: ActivityType.incoming,
        description: 'استلام 25,000 لتر ديزل',
        amount: 25000,
        time: DateTime.now().subtract(const Duration(minutes: 15))),
    RecentActivity(
        type: ActivityType.outgoing,
        description: 'صرف 8,500 لتر لمحطة التسمين',
        amount: 8500,
        time: DateTime.now().subtract(const Duration(hours: 1))),
    RecentActivity(
        type: ActivityType.transfer,
        description: 'تحويل 15,000 لتر للمستودع',
        amount: 15000,
        time: DateTime.now().subtract(const Duration(hours: 3))),
    RecentActivity(
        type: ActivityType.incoming,
        description: 'استلام 12,000 لتر بنزين',
        amount: 12000,
        time: DateTime.now().subtract(const Duration(hours: 6))),
    RecentActivity(
        type: ActivityType.outgoing,
        description: 'صرف 5,200 لتر لمحطة البوادي',
        amount: 5200,
        time: DateTime.now().subtract(const Duration(hours: 10))),
    RecentActivity(
        type: ActivityType.transfer,
        description: 'تحويل 20,000 لتر من الاتحاد',
        amount: 20000,
        time: DateTime.now().subtract(const Duration(days: 1))),
  ];
  List<RecentActivity> get recentActivities =>
      List.unmodifiable(_recentActivities);

  // ===== تحويلات الاتحاد =====
  final List<UnionTransfer> _unionTransfers = [
    UnionTransfer(
        date: DateTime(2026, 2, 12),
        type: TransferType.receive,
        amount: 50000,
        source: 'المصفاة الجنوبية',
        notes: 'شحنة شهرية',
        status: 'مكتمل'),
    UnionTransfer(
        date: DateTime(2026, 2, 11),
        type: TransferType.send,
        amount: 25000,
        source: 'محطة الطاقة',
        notes: 'تموين أسبوعي',
        status: 'مكتمل'),
    UnionTransfer(
        date: DateTime(2026, 2, 10),
        type: TransferType.receive,
        amount: 35000,
        source: 'المصفاة الشمالية',
        notes: 'طلب طارئ',
        status: 'مكتمل'),
    UnionTransfer(
        date: DateTime(2026, 2, 9),
        type: TransferType.send,
        amount: 18000,
        source: 'محطة التسمين',
        notes: 'تموين دوري',
        status: 'مكتمل'),
    UnionTransfer(
        date: DateTime(2026, 2, 8),
        type: TransferType.receive,
        amount: 42000,
        source: 'المصفاة الجنوبية',
        notes: 'شحنة إضافية',
        status: 'مكتمل'),
    UnionTransfer(
        date: DateTime(2026, 2, 7),
        type: TransferType.send,
        amount: 30000,
        source: 'محطة البوادي',
        notes: 'تموين شهري',
        status: 'مكتمل'),
    UnionTransfer(
        date: DateTime(2026, 2, 6),
        type: TransferType.receive,
        amount: 28000,
        source: 'المصفاة الوسطى',
        notes: 'عقد توريد',
        status: 'مكتمل'),
    UnionTransfer(
        date: DateTime(2026, 2, 5),
        type: TransferType.send,
        amount: 15000,
        source: 'محطة البياض',
        notes: 'طلب عاجل',
        status: 'مكتمل'),
    UnionTransfer(
        date: DateTime(2026, 2, 4),
        type: TransferType.receive,
        amount: 60000,
        source: 'المصفاة الجنوبية',
        notes: 'شحنة كبيرة',
        status: 'مكتمل'),
    UnionTransfer(
        date: DateTime(2026, 2, 3),
        type: TransferType.send,
        amount: 22000,
        source: 'محطة الأجداد',
        notes: 'تموين طارئ',
        status: 'مكتمل'),
  ];
  List<UnionTransfer> get unionTransfers => List.unmodifiable(_unionTransfers);
  double get unionReceivedThisMonth => _unionTransfers
      .where((t) => t.type == TransferType.receive)
      .fold(0.0, (s, t) => s + t.amount);
  double get unionSentThisMonth => _unionTransfers
      .where((t) => t.type == TransferType.send)
      .fold(0.0, (s, t) => s + t.amount);

  // Compatibility getters
  List<union_model.UnionTransaction> get unionTransactions => _unionTransfers
      .map((t) => union_model.UnionTransaction(
            date:
                '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}',
            type: t.type == TransferType.receive ? 'استلام' : 'تحويل',
            amount: t.amount,
            target: t.source,
            status: t.status,
            time:
                '${t.date.hour.toString().padLeft(2, '0')}:${t.date.minute.toString().padLeft(2, '0')}',
          ))
      .toList();

  List<double> get weeklyUnionReceived => List.generate(
      7,
      (i) =>
          _unionTransfers
                  .where((t) => t.type == TransferType.receive)
                  .fold(0.0, (s, t) => s) /
              7 +
          (i * 5000));

  List<double> get weeklyUnionTransferred => List.generate(
      7,
      (i) =>
          _unionTransfers
                  .where((t) => t.type == TransferType.send)
                  .fold(0.0, (s, t) => s) /
              7 +
          (i * 3000));

  List<DailyBalance> get unionWeeklyBalance {
    return List.generate(7, (i) {
      final date = DateTime.now().subtract(Duration(days: 6 - i));
      final base = _unionBalance - (6 - i) * 120000;
      return DailyBalance(date: date, balance: base + (i * 23 % 7) * 50000);
    });
  }

  // ===== عمليات الخزانات =====
  final List<TankOperation> _tankOperations = [
    TankOperation(
        tankId: 't1',
        type: 'تعبئة',
        amount: 50000,
        date: DateTime(2026, 2, 10, 14, 30),
        operator: 'أحمد محمد',
        notes: 'شحنة دورية'),
    TankOperation(
        tankId: 't1',
        type: 'صرف',
        amount: 12000,
        date: DateTime(2026, 2, 11, 8, 0),
        operator: 'علي حسن',
        notes: 'تموين محطة التسمين'),
    TankOperation(
        tankId: 't2',
        type: 'تعبئة',
        amount: 30000,
        date: DateTime(2026, 2, 8, 10, 15),
        operator: 'أحمد محمد',
        notes: 'إعادة تعبئة'),
    TankOperation(
        tankId: 't3',
        type: 'صرف',
        amount: 8000,
        date: DateTime(2026, 2, 9, 16, 45),
        operator: 'محمد علي',
        notes: 'صرف للمزارع'),
    TankOperation(
        tankId: 't4',
        type: 'تعبئة',
        amount: 40000,
        date: DateTime(2026, 2, 11, 11, 30),
        operator: 'أحمد محمد',
        notes: 'شحنة احتياطية'),
    TankOperation(
        tankId: 't5',
        type: 'صرف',
        amount: 15000,
        date: DateTime(2026, 1, 28, 9, 0),
        operator: 'علي حسن',
        notes: 'تموين مزارع الأجداد'),
    TankOperation(
        tankId: 't6',
        type: 'تعبئة',
        amount: 80000,
        date: DateTime(2026, 2, 12, 7, 0),
        operator: 'أحمد محمد',
        notes: 'شحنة رئيسية'),
    TankOperation(
        tankId: 't2',
        type: 'صرف',
        amount: 5000,
        date: DateTime(2026, 2, 10, 13, 20),
        operator: 'محمد علي',
        notes: 'صرف عادي'),
  ];
  List<TankOperation> get tankOperations => List.unmodifiable(_tankOperations);
  List<TankOperation> getOperationsForTank(String tankId) =>
      _tankOperations.where((op) => op.tankId == tankId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  // ===== بيانات المحطات للصحاري =====
  final List<StationInfo> _stations = [
    StationInfo(
        id: 's1',
        name: 'محطة الطاقة الرئيسية',
        icon: Icons.power,
        balance: 150000000,
        change: 3,
        color: const Color(0xFF00D9A3),
        farms: ['رصيد محطة الطاقة'],
        generatorHours: 120,
        heaterHours: 80,
        dailyConsumption: 12500,
        monthlyTarget: 400000),
    StationInfo(
        id: 's2',
        name: 'محطة التسمين',
        icon: Icons.agriculture,
        balance: 200000000,
        change: 8,
        color: const Color(0xFFFFA726),
        farms: List.generate(60, (i) => 'مزرعة تسمين ${i + 1}'),
        generatorHours: 95,
        heaterHours: 65,
        dailyConsumption: 18000,
        monthlyTarget: 550000),
    StationInfo(
        id: 's3',
        name: 'محطة البوادي',
        icon: Icons.location_on,
        balance: 100000000,
        change: -1,
        color: const Color(0xFFAB47BC),
        farms: ['رصيد محطة البوادي'],
        subStations: [
          SubStationInfo(
              name: '12 مزرعة تربية',
              farms: List.generate(12, (i) => 'مزرعة تربية ${i + 1}')),
          SubStationInfo(
              name: '24 مزرعة إنتاج أمهات',
              farms: List.generate(24, (i) => 'مزرعة أمهات ${i + 1}'))
        ],
        generatorHours: 110,
        heaterHours: 72,
        dailyConsumption: 9500,
        monthlyTarget: 300000),
    StationInfo(
        id: 's4',
        name: 'محطة البياض',
        icon: Icons.egg,
        balance: 80000000,
        change: 6,
        color: const Color(0xFF42A5F5),
        farms: ['رصيد محطة البياض'],
        generatorHours: 88,
        heaterHours: 55,
        dailyConsumption: 7200,
        monthlyTarget: 220000),
    StationInfo(
        id: 's5',
        name: 'محطة أمهات البياض',
        icon: Icons.egg_alt,
        balance: 70000000,
        change: 4,
        color: const Color(0xFF26A69A),
        farms: ['رصيد محطة أمهات البياض'],
        generatorHours: 75,
        heaterHours: 48,
        dailyConsumption: 6800,
        monthlyTarget: 210000),
    StationInfo(
        id: 's6',
        name: 'محطة الأجداد',
        icon: Icons.family_restroom,
        balance: 50000000,
        change: 10,
        color: const Color(0xFFFF7043),
        farms: List.generate(6, (i) => 'مزرعة أجداد ${i + 1}'),
        generatorHours: 60,
        heaterHours: 40,
        dailyConsumption: 4500,
        monthlyTarget: 140000),
    StationInfo(
        id: 's7',
        name: 'محطة الأسفلت',
        icon: Icons.construction,
        balance: 30000000,
        change: -5,
        color: const Color(0xFF78909C),
        farms: ['رصيد محطة الأسفلت'],
        generatorHours: 45,
        heaterHours: 30,
        dailyConsumption: 3200,
        monthlyTarget: 100000),
  ];
  List<StationInfo> get stations => List.unmodifiable(_stations);
  double get totalStationsBalance =>
      _stations.fold(0.0, (s, st) => s + st.balance);
  double get totalDailyConsumptionAllStations =>
      _stations.fold(0.0, (s, st) => s + st.dailyConsumption);
  int get totalFarmsCount {
    int count = 0;
    for (var station in _stations) {
      count += station.farms.length;
      if (station.subStations != null)
        for (var sub in station.subStations!) count += sub.farms.length;
    }
    return count;
  }

  // ===== بيانات رصيد الغاز =====
  final List<GasRecord> _gasRecords = [
    GasRecord(
        id: 'g1',
        date: DateTime(2026, 2, 14),
        station: 'محطة الطاقة الرئيسية',
        farm: 'رصيد محطة الطاقة',
        quantity: 5000,
        unitPrice: 320,
        type: 'وارد',
        operator: 'أحمد محمد',
        notes: 'شحنة دورية'),
    GasRecord(
        id: 'g2',
        date: DateTime(2026, 2, 14),
        station: 'محطة التسمين',
        farm: 'مزرعة تسمين 1',
        quantity: 3200,
        unitPrice: 320,
        type: 'صرف',
        operator: 'علي حسن',
        notes: 'تموين مزرعة'),
    GasRecord(
        id: 'g3',
        date: DateTime(2026, 2, 13),
        station: 'محطة التسمين',
        farm: 'مزرعة تسمين 5',
        quantity: 2800,
        unitPrice: 320,
        type: 'صرف',
        operator: 'محمد علي',
        notes: 'تموين مزرعة'),
    GasRecord(
        id: 'g4',
        date: DateTime(2026, 2, 13),
        station: 'محطة البوادي',
        farm: 'مزرعة بوادي 3',
        quantity: 4500,
        unitPrice: 325,
        type: 'وارد',
        operator: 'أحمد محمد',
        notes: 'شحنة طوارئ'),
    GasRecord(
        id: 'g5',
        date: DateTime(2026, 2, 12),
        station: 'محطة البياض',
        farm: 'رصيد محطة البياض',
        quantity: 6000,
        unitPrice: 320,
        type: 'وارد',
        operator: 'أحمد محمد',
        notes: 'شحنة أسبوعية'),
    GasRecord(
        id: 'g6',
        date: DateTime(2026, 2, 12),
        station: 'محطة أمهات البياض',
        farm: 'رصيد محطة أمهات البياض',
        quantity: 1500,
        unitPrice: 320,
        type: 'صرف',
        operator: 'علي حسن',
        notes: 'تموين'),
    GasRecord(
        id: 'g7',
        date: DateTime(2026, 2, 11),
        station: 'محطة الأجداد',
        farm: 'مزرعة أجداد 2',
        quantity: 3800,
        unitPrice: 318,
        type: 'وارد',
        operator: 'محمد علي',
        notes: 'شحنة شهرية'),
    GasRecord(
        id: 'g8',
        date: DateTime(2026, 2, 11),
        station: 'محطة الطاقة الرئيسية',
        farm: 'رصيد محطة الطاقة',
        quantity: 2200,
        unitPrice: 320,
        type: 'صرف',
        operator: 'أحمد محمد',
        notes: 'صرف تشغيلي'),
    GasRecord(
        id: 'g9',
        date: DateTime(2026, 2, 10),
        station: 'محطة التسمين',
        farm: 'مزرعة تسمين 12',
        quantity: 7500,
        unitPrice: 322,
        type: 'وارد',
        operator: 'أحمد محمد',
        notes: 'شحنة كبيرة'),
    GasRecord(
        id: 'g10',
        date: DateTime(2026, 2, 10),
        station: 'محطة البوادي',
        farm: 'مزرعة بوادي 1',
        quantity: 1800,
        unitPrice: 320,
        type: 'صرف',
        operator: 'علي حسن',
        notes: 'تموين يومي'),
    GasRecord(
        id: 'g11',
        date: DateTime(2026, 2, 9),
        station: 'محطة الأسفلت',
        farm: 'رصيد محطة الأسفلت',
        quantity: 4200,
        unitPrice: 320,
        type: 'وارد',
        operator: 'محمد علي',
        notes: 'شحنة دورية'),
    GasRecord(
        id: 'g12',
        date: DateTime(2026, 2, 9),
        station: 'محطة البياض',
        farm: 'رصيد محطة البياض',
        quantity: 2600,
        unitPrice: 320,
        type: 'صرف',
        operator: 'أحمد محمد',
        notes: 'صرف تشغيلي'),
    GasRecord(
        id: 'g13',
        date: DateTime(2026, 2, 8),
        station: 'محطة التسمين',
        farm: 'مزرعة تسمين 22',
        quantity: 5500,
        unitPrice: 325,
        type: 'وارد',
        operator: 'أحمد محمد',
        notes: 'شحنة'),
    GasRecord(
        id: 'g14',
        date: DateTime(2026, 2, 8),
        station: 'محطة الأجداد',
        farm: 'مزرعة أجداد 4',
        quantity: 3000,
        unitPrice: 320,
        type: 'صرف',
        operator: 'علي حسن',
        notes: 'تموين'),
    GasRecord(
        id: 'g15',
        date: DateTime(2026, 2, 7),
        station: 'محطة الطاقة الرئيسية',
        farm: 'رصيد محطة الطاقة',
        quantity: 8000,
        unitPrice: 318,
        type: 'وارد',
        operator: 'أحمد محمد',
        notes: 'شحنة رئيسية'),
  ];
  List<GasRecord> get gasRecords => List.unmodifiable(_gasRecords);
  double get totalGasBalance =>
      _gasRecords
          .where((r) => r.type == 'وارد')
          .fold(0.0, (s, r) => s + r.quantity) -
      _gasRecords
          .where((r) => r.type == 'صرف')
          .fold(0.0, (s, r) => s + r.quantity);
  double get totalGasIncoming => _gasRecords
      .where((r) => r.type == 'وارد')
      .fold(0.0, (s, r) => s + r.quantity);
  double get totalGasOutgoing => _gasRecords
      .where((r) => r.type == 'صرف')
      .fold(0.0, (s, r) => s + r.quantity);
  double get totalGasCost => _gasRecords.fold(0.0, (s, r) => s + r.totalCost);
  int get totalGasRecords => _gasRecords.length;

  Map<String, double> get gasBalanceByStation {
    final map = <String, double>{};
    for (var r in _gasRecords) {
      final sign = r.type == 'وارد' ? 1.0 : -1.0;
      map[r.station] = (map[r.station] ?? 0) + r.quantity * sign;
    }
    return map;
  }

  Map<String, double> get gasFarmBalances {
    final map = <String, double>{};
    for (var r in _gasRecords) {
      final sign = r.type == 'وارد' ? 1.0 : -1.0;
      map[r.farm] = (map[r.farm] ?? 0) + r.quantity * sign;
    }
    return map;
  }

  List<double> get gasWeeklyData {
    return List.generate(7, (i) {
      final date = DateTime.now().subtract(Duration(days: 6 - i));
      return _gasRecords
          .where((r) =>
              r.date.year == date.year &&
              r.date.month == date.month &&
              r.date.day == date.day &&
              r.type == 'وارد')
          .fold(0.0, (s, r) => s + r.quantity);
    });
  }

  List<double> get gasWeeklyOutgoing {
    return List.generate(7, (i) {
      final date = DateTime.now().subtract(Duration(days: 6 - i));
      return _gasRecords
          .where((r) =>
              r.date.year == date.year &&
              r.date.month == date.month &&
              r.date.day == date.day &&
              r.type == 'صرف')
          .fold(0.0, (s, r) => s + r.quantity);
    });
  }

  void addGasRecord(
      {required String station,
      required String farm,
      required double quantity,
      required double unitPrice,
      required String type,
      required String operator,
      String notes = ''}) {
    _gasRecords.insert(
        0,
        GasRecord(
          id: 'g_${DateTime.now().millisecondsSinceEpoch}',
          date: DateTime.now(),
          station: station,
          farm: farm,
          quantity: quantity,
          unitPrice: unitPrice,
          type: type,
          operator: operator,
          notes: notes,
        ));
    _recentActivities.insert(
        0,
        RecentActivity(
          type: type == 'وارد' ? ActivityType.incoming : ActivityType.outgoing,
          description:
              '$type ${formatNumber(quantity)} لتر غاز - $station / $farm',
          amount: quantity,
          time: DateTime.now(),
        ));
    _notifications.insert(
        0,
        AppNotification(
          id: 'n_${DateTime.now().millisecondsSinceEpoch}',
          title: type == 'وارد' ? 'وارد غاز جديد' : 'صرف غاز',
          message:
              'تم $type ${formatNumber(quantity)} لتر غاز - $station / $farm',
          type: NotificationType.success,
          time: DateTime.now(),
          category: 'تحديثات',
        ));
    notifyListeners();
  }

  void updateGasRecord(String id,
      {String? station,
      String? farm,
      double? quantity,
      double? unitPrice,
      String? type,
      String? operator,
      String? notes}) {
    final idx = _gasRecords.indexWhere((r) => r.id == id);
    if (idx != -1) {
      final old = _gasRecords[idx];
      _gasRecords[idx] = GasRecord(
        id: old.id,
        date: old.date,
        station: station ?? old.station,
        farm: farm ?? old.farm,
        quantity: quantity ?? old.quantity,
        unitPrice: unitPrice ?? old.unitPrice,
        type: type ?? old.type,
        operator: operator ?? old.operator,
        notes: notes ?? old.notes,
      );
      notifyListeners();
    }
  }

  void deleteGasRecord(String id) {
    _gasRecords.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  // ===== بيانات العربات =====
  final List<Vehicle> _vehicles = [
    Vehicle(
        id: 'v1',
        plateNumber: 'بغداد 12345',
        driverName: 'أحمد محمد',
        model: 'تويوتا هايلكس',
        vehicleType: 'بيكب',
        fuelType: 'كاز',
        isActive: true,
        totalConsumed: 12500,
        lastRefuel: DateTime(2026, 2, 16),
        lastQuantity: 120,
        history: [
          RefuelRecord(date: DateTime(2026, 2, 16), quantity: 120),
          RefuelRecord(date: DateTime(2026, 2, 14), quantity: 95)
        ]),
    Vehicle(
        id: 'v2',
        plateNumber: 'كربلاء 54321',
        driverName: 'علي حسن',
        model: 'ايسوزو صهريج',
        vehicleType: 'صهريج',
        fuelType: 'كاز',
        isActive: true,
        totalConsumed: 45000,
        lastRefuel: DateTime(2026, 2, 16),
        lastQuantity: 850,
        history: [
          RefuelRecord(date: DateTime(2026, 2, 16), quantity: 850),
          RefuelRecord(date: DateTime(2026, 2, 15), quantity: 900)
        ]),
    Vehicle(
        id: 'v3',
        plateNumber: 'بصرة 67890',
        driverName: 'محمد جاسم',
        model: 'مان شاحنة',
        vehicleType: 'شاحنة',
        fuelType: 'كاز',
        isActive: true,
        totalConsumed: 78000,
        lastRefuel: DateTime(2026, 2, 16),
        lastQuantity: 450,
        history: [RefuelRecord(date: DateTime(2026, 2, 16), quantity: 450)]),
    Vehicle(
        id: 'v4',
        plateNumber: 'بغداد 11111',
        driverName: 'حسين عباس',
        model: 'تويوتا كامري',
        vehicleType: 'سيارة صغيرة',
        fuelType: 'بنزين',
        isActive: true,
        totalConsumed: 5600,
        lastRefuel: DateTime(2026, 2, 16),
        lastQuantity: 55,
        history: [RefuelRecord(date: DateTime(2026, 2, 16), quantity: 55)]),
    Vehicle(
        id: 'v5',
        plateNumber: 'كربلاء 22222',
        driverName: 'كريم سعد',
        model: 'كيا سيراتو',
        vehicleType: 'سيارة صغيرة',
        fuelType: 'بنزين',
        isActive: true,
        totalConsumed: 3200,
        lastRefuel: DateTime(2026, 2, 16),
        lastQuantity: 40,
        history: [RefuelRecord(date: DateTime(2026, 2, 16), quantity: 40)]),
    Vehicle(
        id: 'v6',
        plateNumber: 'بغداد 33333',
        driverName: 'عمار فاضل',
        model: 'هونداي توسان',
        vehicleType: 'سيارة صغيرة',
        fuelType: 'بنزين',
        isActive: false,
        totalConsumed: 4100,
        lastRefuel: DateTime(2026, 2, 14),
        lastQuantity: 45,
        history: [RefuelRecord(date: DateTime(2026, 2, 14), quantity: 45)]),
    Vehicle(
        id: 'v7',
        plateNumber: 'نينوى 44444',
        driverName: 'زيد محمود',
        model: 'باص مرسيدس',
        vehicleType: 'باص',
        fuelType: 'كاز',
        isActive: true,
        totalConsumed: 92000,
        lastRefuel: DateTime(2026, 2, 16),
        lastQuantity: 350,
        history: [
          RefuelRecord(date: DateTime(2026, 2, 16), quantity: 350),
          RefuelRecord(date: DateTime(2026, 2, 15), quantity: 380)
        ]),
    Vehicle(
        id: 'v8',
        plateNumber: 'بغداد 55555',
        driverName: 'ياسر كاظم',
        model: 'كاتربيلر D6',
        vehicleType: 'معدة ثقيلة',
        fuelType: 'كاز',
        isActive: true,
        totalConsumed: 120000,
        lastRefuel: DateTime(2026, 2, 16),
        lastQuantity: 600,
        history: [RefuelRecord(date: DateTime(2026, 2, 16), quantity: 600)]),
    Vehicle(
        id: 'v9',
        plateNumber: 'كربلاء 66666',
        driverName: 'سامر نعيم',
        model: 'مولدة كمنز',
        vehicleType: 'مولدة',
        fuelType: 'كاز',
        isActive: true,
        totalConsumed: 250000,
        lastRefuel: DateTime(2026, 2, 16),
        lastQuantity: 1200,
        history: [RefuelRecord(date: DateTime(2026, 2, 16), quantity: 1200)]),
    Vehicle(
        id: 'v10',
        plateNumber: 'بغداد 77777',
        driverName: 'فاضل عبدالله',
        model: 'فولفو FH',
        vehicleType: 'شاحنة',
        fuelType: 'كاز',
        isActive: true,
        totalConsumed: 65000,
        lastRefuel: DateTime(2026, 2, 15),
        lastQuantity: 500,
        history: [RefuelRecord(date: DateTime(2026, 2, 15), quantity: 500)]),
    Vehicle(
        id: 'v11',
        plateNumber: 'بصرة 88888',
        driverName: 'ماجد حميد',
        model: 'ايسوزو بيكب',
        vehicleType: 'بيكب',
        fuelType: 'كاز',
        isActive: false,
        totalConsumed: 18000,
        lastRefuel: DateTime(2026, 2, 13),
        lastQuantity: 80,
        history: [RefuelRecord(date: DateTime(2026, 2, 13), quantity: 80)]),
    Vehicle(
        id: 'v12',
        plateNumber: 'كربلاء 99999',
        driverName: 'حيدر علي',
        model: 'مولدة بيركنز',
        vehicleType: 'مولدة',
        fuelType: 'غاز',
        isActive: true,
        totalConsumed: 180000,
        lastRefuel: DateTime(2026, 2, 16),
        lastQuantity: 900,
        history: [RefuelRecord(date: DateTime(2026, 2, 16), quantity: 900)]),
    Vehicle(
        id: 'v13',
        plateNumber: 'بغداد 10101',
        driverName: 'عادل خالد',
        model: 'مولدة كمنز 500',
        vehicleType: 'مولدة',
        fuelType: 'غاز',
        isActive: true,
        totalConsumed: 210000,
        lastRefuel: DateTime(2026, 2, 16),
        lastQuantity: 1100,
        history: [RefuelRecord(date: DateTime(2026, 2, 16), quantity: 1100)]),
    Vehicle(
        id: 'v14',
        plateNumber: 'كربلاء 20202',
        driverName: 'رائد جمعة',
        model: 'هيتر صناعي',
        vehicleType: 'معدة ثقيلة',
        fuelType: 'غاز',
        isActive: true,
        totalConsumed: 95000,
        lastRefuel: DateTime(2026, 2, 16),
        lastQuantity: 700,
        history: [RefuelRecord(date: DateTime(2026, 2, 16), quantity: 700)]),
    Vehicle(
        id: 'v15',
        plateNumber: 'بغداد 30303',
        driverName: 'نبيل صالح',
        model: 'تويوتا لاندكروزر',
        vehicleType: 'سيارة صغيرة',
        fuelType: 'بنزين',
        isActive: true,
        totalConsumed: 8900,
        lastRefuel: DateTime(2026, 2, 16),
        lastQuantity: 75,
        history: [RefuelRecord(date: DateTime(2026, 2, 16), quantity: 75)]),
  ];
  List<Vehicle> get vehicles => List.unmodifiable(_vehicles);

  void addVehicle(
      {required String plateNumber,
      required String driverName,
      required String model,
      required String vehicleType,
      required String fuelType}) {
    _vehicles.add(Vehicle(
        id: 'v_${DateTime.now().millisecondsSinceEpoch}',
        plateNumber: plateNumber,
        driverName: driverName,
        model: model,
        vehicleType: vehicleType,
        fuelType: fuelType,
        isActive: true,
        totalConsumed: 0,
        lastRefuel: DateTime.now(),
        lastQuantity: 0,
        history: []));
    notifyListeners();
  }

  void updateVehicle(String id,
      {String? driverName, String? model, bool? isActive}) {
    final i = _vehicles.indexWhere((v) => v.id == id);
    if (i != -1) {
      final old = _vehicles[i];
      _vehicles[i] = Vehicle(
          id: old.id,
          plateNumber: old.plateNumber,
          driverName: driverName ?? old.driverName,
          model: model ?? old.model,
          vehicleType: old.vehicleType,
          fuelType: old.fuelType,
          isActive: isActive ?? old.isActive,
          totalConsumed: old.totalConsumed,
          lastRefuel: old.lastRefuel,
          lastQuantity: old.lastQuantity,
          history: old.history);
      notifyListeners();
    }
  }

  void refuelVehicle(String plateNumber, double quantity, String fuelType) {
    final i = _vehicles.indexWhere(
        (v) => v.plateNumber == plateNumber && v.fuelType == fuelType);
    if (i != -1) {
      final old = _vehicles[i];
      final newHistory = List<RefuelRecord>.from(old.history)
        ..insert(0, RefuelRecord(date: DateTime.now(), quantity: quantity));
      _vehicles[i] = Vehicle(
          id: old.id,
          plateNumber: old.plateNumber,
          driverName: old.driverName,
          model: old.model,
          vehicleType: old.vehicleType,
          fuelType: old.fuelType,
          isActive: true,
          totalConsumed: old.totalConsumed + quantity,
          lastRefuel: DateTime.now(),
          lastQuantity: quantity,
          history: newHistory);
    } else {
      _vehicles.add(Vehicle(
          id: 'v_${DateTime.now().millisecondsSinceEpoch}',
          plateNumber: plateNumber,
          driverName: 'غير محدد',
          model: 'غير محدد',
          vehicleType: 'غير محدد',
          fuelType: fuelType,
          isActive: true,
          totalConsumed: quantity,
          lastRefuel: DateTime.now(),
          lastQuantity: quantity,
          history: [RefuelRecord(date: DateTime.now(), quantity: quantity)]));
    }
    notifyListeners();
  }

  // ===== بيانات تقرير الوارد =====
  final List<IncomingRecord> _incomingRecords = [
    IncomingRecord(
        id: 'r1',
        date: DateTime(2026, 2, 12),
        supplier: 'شركة النفط الوطنية',
        fuelType: 'ديزل',
        quantity: 25000,
        unitPrice: 490,
        tankName: 'خزان الديزل الرئيسي',
        driverName: 'حسن أحمد',
        truckNumber: 'بغداد 12345',
        status: 'مكتمل',
        color: '2.5',
        density: 0.85),
    IncomingRecord(
        id: 'r2',
        date: DateTime(2026, 2, 12),
        supplier: 'مصفاة كربلاء',
        fuelType: 'بنزين',
        quantity: 15000,
        unitPrice: 650,
        tankName: 'خزان البنزين',
        driverName: 'علي كاظم',
        truckNumber: 'كربلاء 54321',
        status: 'مكتمل',
        color: '1.0',
        density: 0.72),
    IncomingRecord(
        id: 'r3',
        date: DateTime(2026, 2, 11),
        supplier: 'شركة النفط الوطنية',
        fuelType: 'ديزل',
        quantity: 30000,
        unitPrice: 490,
        tankName: 'خزان الديزل الاحتياطي',
        driverName: 'محمد جاسم',
        truckNumber: 'بغداد 67890',
        status: 'مكتمل',
        color: '2.0',
        density: 0.84),
    IncomingRecord(
        id: 'r4',
        date: DateTime(2026, 2, 11),
        supplier: 'المصفاة الجنوبية',
        fuelType: 'كاز',
        quantity: 20000,
        unitPrice: 350,
        tankName: 'خزان الكاز',
        driverName: 'عباس حسين',
        truckNumber: 'بصرة 11111',
        status: 'مكتمل',
        color: '3.0',
        density: 0.80),
    IncomingRecord(
        id: 'r5',
        date: DateTime(2026, 2, 10),
        supplier: 'مصفاة كربلاء',
        fuelType: 'ديزل',
        quantity: 35000,
        unitPrice: 495,
        tankName: 'خزان المحطة المركزية',
        driverName: 'كريم سعد',
        truckNumber: 'كربلاء 22222',
        status: 'مكتمل',
        color: '2.5',
        density: 0.85),
    IncomingRecord(
        id: 'r6',
        date: DateTime(2026, 2, 10),
        supplier: 'شركة النفط الوطنية',
        fuelType: 'بنزين',
        quantity: 18000,
        unitPrice: 640,
        tankName: 'خزان البنزين',
        driverName: 'حسن أحمد',
        truckNumber: 'بغداد 12345',
        status: 'مكتمل',
        color: '1.5',
        density: 0.73),
    IncomingRecord(
        id: 'r7',
        date: DateTime(2026, 2, 9),
        supplier: 'المصفاة الجنوبية',
        fuelType: 'ديزل',
        quantity: 22000,
        unitPrice: 488,
        tankName: 'خزان الديزل الرئيسي',
        driverName: 'عمار فاضل',
        truckNumber: 'بصرة 33333',
        status: 'مكتمل',
        color: '2.0',
        density: 0.84),
    IncomingRecord(
        id: 'r8',
        date: DateTime(2026, 2, 9),
        supplier: 'مصفاة الشمال',
        fuelType: 'كاز',
        quantity: 12000,
        unitPrice: 355,
        tankName: 'خزان النفط الأبيض',
        driverName: 'زيد محمود',
        truckNumber: 'نينوى 44444',
        status: 'مكتمل',
        color: '3.5',
        density: 0.81),
    IncomingRecord(
        id: 'r9',
        date: DateTime(2026, 2, 8),
        supplier: 'شركة النفط الوطنية',
        fuelType: 'ديزل',
        quantity: 40000,
        unitPrice: 492,
        tankName: 'خزان المحطة المركزية',
        driverName: 'حسن أحمد',
        truckNumber: 'بغداد 12345',
        status: 'مكتمل',
        color: '2.5',
        density: 0.85),
    IncomingRecord(
        id: 'r10',
        date: DateTime(2026, 2, 8),
        supplier: 'مصفاة كربلاء',
        fuelType: 'بنزين',
        quantity: 10000,
        unitPrice: 645,
        tankName: 'خزان البنزين',
        driverName: 'علي كاظم',
        truckNumber: 'كربلاء 54321',
        status: 'مكتمل',
        color: '1.0',
        density: 0.72),
    IncomingRecord(
        id: 'r11',
        date: DateTime(2026, 2, 7),
        supplier: 'المصفاة الجنوبية',
        fuelType: 'ديزل',
        quantity: 28000,
        unitPrice: 490,
        tankName: 'خزان الديزل الاحتياطي',
        driverName: 'عباس حسين',
        truckNumber: 'بصرة 11111',
        status: 'مكتمل',
        color: '2.0',
        density: 0.83),
    IncomingRecord(
        id: 'r12',
        date: DateTime(2026, 2, 7),
        supplier: 'مصفاة الشمال',
        fuelType: 'كاز',
        quantity: 16000,
        unitPrice: 348,
        tankName: 'خزان الكاز',
        driverName: 'زيد محمود',
        truckNumber: 'نينوى 44444',
        status: 'مكتمل',
        color: '3.0',
        density: 0.80),
    IncomingRecord(
        id: 'r13',
        date: DateTime(2026, 2, 6),
        supplier: 'شركة النفط الوطنية',
        fuelType: 'ديزل',
        quantity: 32000,
        unitPrice: 490,
        tankName: 'خزان الديزل الرئيسي',
        driverName: 'محمد جاسم',
        truckNumber: 'بغداد 67890',
        status: 'مكتمل',
        color: '2.5',
        density: 0.85),
    IncomingRecord(
        id: 'r14',
        date: DateTime(2026, 2, 5),
        supplier: 'مصفاة كربلاء',
        fuelType: 'ديزل',
        quantity: 26000,
        unitPrice: 495,
        tankName: 'خزان المحطة المركزية',
        driverName: 'كريم سعد',
        truckNumber: 'كربلاء 22222',
        status: 'مكتمل',
        color: '2.0',
        density: 0.84),
    IncomingRecord(
        id: 'r15',
        date: DateTime(2026, 2, 4),
        supplier: 'المصفاة الجنوبية',
        fuelType: 'بنزين',
        quantity: 14000,
        unitPrice: 650,
        tankName: 'خزان البنزين',
        driverName: 'عمار فاضل',
        truckNumber: 'بصرة 33333',
        status: 'مكتمل',
        color: '1.5',
        density: 0.73),
  ];
  List<IncomingRecord> get incomingRecords =>
      List.unmodifiable(_incomingRecords);
  double get totalIncomingQuantity =>
      _incomingRecords.fold(0.0, (s, r) => s + r.quantity);
  double get totalIncomingCost =>
      _incomingRecords.fold(0.0, (s, r) => s + r.totalCost);
  int get totalIncomingShipments => _incomingRecords.length;

  // Compatibility getters for reports
  List<IncomingRecord> get incomingShipments => incomingRecords; // alias
  List<ReportRow> get fuelExpenses => _generateFuelExpenses(); // dynamic data
  List<StationReport> get stationReports =>
      _generateStationReports(); // dynamic data

  List<ReportRow> _generateFuelExpenses() {
    // Generate fake data for reports based on fuel types
    return [
      ReportRow(
          type: 'ديزل',
          prevBalance: 500000,
          sales: 120000,
          purchase: 150000,
          expense: 30000,
          currentBalance: 500000,
          avgPrice: 490),
      ReportRow(
          type: 'بنزين',
          prevBalance: 300000,
          sales: 80000,
          purchase: 100000,
          expense: 20000,
          currentBalance: 300000,
          avgPrice: 650),
      ReportRow(
          type: 'كاز',
          prevBalance: 200000,
          sales: 50000,
          purchase: 60000,
          expense: 10000,
          currentBalance: 200000,
          avgPrice: 350),
    ];
  }

  List<StationReport> _generateStationReports() {
    // Convert stations to station reports
    return _stations
        .map((s) => StationReport(
              name: s.name,
              consumed: (s.dailyConsumption * 28).toInt(),
              balance: (s.balance / 10000).toInt(), // simplified calculation
              efficiency: (95 + s.change).toInt(),
            ))
        .toList();
  }

  List<IncomingRecord> getIncomingByDate(DateTime date) => _incomingRecords
      .where((r) =>
          r.date.year == date.year &&
          r.date.month == date.month &&
          r.date.day == date.day)
      .toList();
  List<IncomingRecord> getIncomingBySupplier(String supplier) =>
      _incomingRecords.where((r) => r.supplier == supplier).toList();
  Set<String> get allSuppliers =>
      _incomingRecords.map((r) => r.supplier).toSet();
  Set<String> get allFuelTypes =>
      _incomingRecords.map((r) => r.fuelType).toSet();
  Map<String, double> get supplierTotals {
    final map = <String, double>{};
    for (var r in _incomingRecords)
      map[r.supplier] = (map[r.supplier] ?? 0) + r.quantity;
    return map;
  }

  Map<String, double> get fuelTypeTotals {
    final map = <String, double>{};
    for (var r in _incomingRecords)
      map[r.fuelType] = (map[r.fuelType] ?? 0) + r.quantity;
    return map;
  }

  // ===== المصادقة =====
  String _currentUserName = '';
  String _currentUserRole = '';
  bool _isLoggedIn = false;
  String get currentUserName => _currentUserName;
  String get currentUserRole => _currentUserRole;
  bool get isLoggedIn => _isLoggedIn;

  bool login(String email, String password) {
    for (var user in _users) {
      if (user['email'] == email && user['password'] == password) {
        _currentUserName = user['name']!;
        _currentUserRole = user['role']!;
        _isLoggedIn = true;
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  void logout() {
    _currentUserName = '';
    _currentUserRole = '';
    _isLoggedIn = false;
    notifyListeners();
  }

  final List<Map<String, String>> _users = [
    {
      'email': 'admin@sahara-fuel.com',
      'password': 'admin123',
      'name': 'مدير النظام',
      'role': 'مدير عام'
    },
    {
      'email': 'manager@sahara-fuel.com',
      'password': 'manager123',
      'name': 'أحمد محمد',
      'role': 'مدير محطة'
    },
    {
      'email': 'operator@sahara-fuel.com',
      'password': 'operator123',
      'name': 'علي حسن',
      'role': 'مشغّل'
    },
    {
      'email': 'admin@sahara.com',
      'password': 'admin123',
      'name': 'مدير النظام',
      'role': 'مدير عام'
    },
    {
      'email': 'manager@sahara.com',
      'password': 'manager123',
      'name': 'أحمد محمد',
      'role': 'مدير محطة'
    },
    {'email': '1', 'password': '1', 'name': 'مستخدم تجريبي', 'role': 'مدير'},
  ];

  // ===== العمليات المتسلسلة =====

  /// إضافة شحنة وارد - تحديث: سجل الوارد + الخزان + الرصيد + الإشعارات + سجل العمليات
  void addIncomingRecord(
      {required String supplier,
      required String fuelType,
      required double quantity,
      required double unitPrice,
      required String tankName,
      required String driverName,
      required String truckNumber,
      String color = '2.0',
      double density = 0.85}) {
    // 1) إضافة السجل
    final record = IncomingRecord(
        id: 'r_${DateTime.now().millisecondsSinceEpoch}',
        date: DateTime.now(),
        supplier: supplier,
        fuelType: fuelType,
        quantity: quantity,
        unitPrice: unitPrice,
        tankName: tankName,
        driverName: driverName,
        truckNumber: truckNumber,
        status: 'مكتمل',
        color: color,
        density: density);
    _incomingRecords.insert(0, record);
    // 2) تحديث الوارد اليومي + رصيد الصحاري
    _todayIncoming += quantity;
    _saharaBalance += quantity;
    // 3) تحديث الخزان
    _updateTankLevel(tankName, quantity);
    // 4) تسجيل النشاط
    _recentActivities.insert(
        0,
        RecentActivity(
            type: ActivityType.incoming,
            description:
                'استلام ${formatNumber(quantity)} لتر $fuelType - $supplier',
            amount: quantity,
            time: DateTime.now()));
    // 5) إشعار
    _notifications.insert(
        0,
        AppNotification(
            id: 'n_${DateTime.now().millisecondsSinceEpoch}',
            title: 'شحنة وارد جديدة',
            message:
                'تم استلام ${formatNumber(quantity)} لتر $fuelType من $supplier إلى $tankName',
            type: NotificationType.success,
            time: DateTime.now(),
            category: 'تحديثات'));
    // 6) عملية خزان
    _tankOperations.insert(
        0,
        TankOperation(
            tankId: _tanks
                .firstWhere((t) => t.name == tankName,
                    orElse: () => _tanks.first)
                .id,
            type: 'تعبئة',
            amount: quantity,
            date: DateTime.now(),
            operator: 'النظام',
            notes: 'شحنة وارد - $supplier'));
    notifyListeners();
  }

  /// تعبئة خزان يدوياً
  void refillTank(String tankName, double amount,
      {String operator = 'مشغّل', String notes = ''}) {
    _todayIncoming += amount;
    _saharaBalance += amount;
    _updateTankLevel(tankName, amount);
    _recentActivities.insert(
        0,
        RecentActivity(
            type: ActivityType.incoming,
            description: 'تعبئة ${formatNumber(amount)} لتر - $tankName',
            amount: amount,
            time: DateTime.now()));
    _notifications.insert(
        0,
        AppNotification(
            id: 'n_${DateTime.now().millisecondsSinceEpoch}',
            title: 'تعبئة خزان',
            message: 'تم تعبئة ${formatNumber(amount)} لتر في $tankName',
            type: NotificationType.success,
            time: DateTime.now(),
            category: 'تحديثات'));
    _tankOperations.insert(
        0,
        TankOperation(
            tankId: _tanks
                .firstWhere((t) => t.name == tankName,
                    orElse: () => _tanks.first)
                .id,
            type: 'تعبئة',
            amount: amount,
            date: DateTime.now(),
            operator: operator,
            notes: notes));
    notifyListeners();
  }

  /// صرف من خزان
  void drainTank(String tankName, double amount,
      {String destination = '', String operator = 'مشغّل', String notes = ''}) {
    _todayOutgoing += amount;
    _saharaBalance -= amount;
    _updateTankLevel(tankName, -amount);
    final tank = _tanks.firstWhere((t) => t.name == tankName,
        orElse: () => _tanks.first);
    _recentActivities.insert(
        0,
        RecentActivity(
            type: ActivityType.outgoing,
            description:
                'صرف ${formatNumber(amount)} لتر من $tankName${destination.isNotEmpty ? " إلى $destination" : ""}',
            amount: amount,
            time: DateTime.now()));
    _tankOperations.insert(
        0,
        TankOperation(
            tankId: tank.id,
            type: 'صرف',
            amount: amount,
            date: DateTime.now(),
            operator: operator,
            notes: notes.isNotEmpty ? notes : destination));
    // تنبيه إذا منخفض
    if (getTankPercentage(tank) < 25) {
      _notifications.insert(
          0,
          AppNotification(
              id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
              title: 'تنبيه مخزون منخفض!',
              message:
                  'مستوى $tankName وصل إلى ${getTankPercentage(tank).toStringAsFixed(0)}%',
              type: NotificationType.warning,
              time: DateTime.now(),
              category: 'تنبيهات'));
    }
    notifyListeners();
  }

  /// تحويل بين خزانين
  void transferBetweenTanks(String fromTank, String toTank, double amount) {
    _updateTankLevel(fromTank, -amount);
    _updateTankLevel(toTank, amount);
    _recentActivities.insert(
        0,
        RecentActivity(
            type: ActivityType.transfer,
            description:
                'تحويل ${formatNumber(amount)} لتر من $fromTank إلى $toTank',
            amount: amount,
            time: DateTime.now()));
    _notifications.insert(
        0,
        AppNotification(
            id: 'n_${DateTime.now().millisecondsSinceEpoch}',
            title: 'تحويل وقود',
            message:
                'تم تحويل ${formatNumber(amount)} لتر من $fromTank إلى $toTank',
            type: NotificationType.info,
            time: DateTime.now(),
            category: 'تحديثات'));
    notifyListeners();
  }

  /// إضافة تحويل اتحاد مع تحديث الرصيد
  void addUnionTransfer(
      {required TransferType type,
      required double amount,
      required String source,
      String notes = ''}) {
    _unionTransfers.insert(
        0,
        UnionTransfer(
            date: DateTime.now(),
            type: type,
            amount: amount,
            source: source,
            notes: notes,
            status: 'مكتمل'));
    if (type == TransferType.receive) {
      _unionBalance += amount;
    } else {
      _unionBalance -= amount;
    }
    final desc = type == TransferType.receive
        ? 'استلام ${formatNumber(amount)} لتر من $source'
        : 'إرسال ${formatNumber(amount)} لتر إلى $source';
    _recentActivities.insert(
        0,
        RecentActivity(
            type: type == TransferType.receive
                ? ActivityType.incoming
                : ActivityType.outgoing,
            description: desc,
            amount: amount,
            time: DateTime.now()));
    _notifications.insert(
        0,
        AppNotification(
            id: 'n_${DateTime.now().millisecondsSinceEpoch}',
            title: type == TransferType.receive
                ? 'استلام من الاتحاد'
                : 'إرسال للاتحاد',
            message: desc,
            type: NotificationType.success,
            time: DateTime.now(),
            category: 'تحديثات'));
    notifyListeners();
  }

  /// تحديث مستوى خزان داخلياً (+ تعبئة / - صرف)
  void _updateTankLevel(String tankName, double delta) {
    final i = _tanks.indexWhere((t) => t.name == tankName);
    if (i != -1) {
      final newCurrent =
          (_tanks[i].current + delta).clamp(0.0, _tanks[i].capacity);
      final p = _tanks[i].capacity > 0
          ? (newCurrent / _tanks[i].capacity) * 100
          : 0.0;
      _tanks[i] = _tanks[i].copyWith(
          current: newCurrent,
          lastFill: delta > 0 ? DateTime.now() : _tanks[i].lastFill,
          status: p >= 80
              ? TankStatus.excellent
              : p >= 50
                  ? TankStatus.good
                  : p >= 25
                      ? TankStatus.medium
                      : TankStatus.low);
    }
  }

  // العمليات القديمة (للتوافق)
  void addIncoming(double amount, String tankName) =>
      refillTank(tankName, amount);
  void dispenseFuel(double amount, String tankName, String destination) =>
      drainTank(tankName, amount, destination: destination);
  void transferFuel(double amount, String fromTank, String toTank) =>
      transferBetweenTanks(fromTank, toTank, amount);
  void updateUnionBalance(double amount) {
    _unionBalance += amount;
    notifyListeners();
  }

  void markNotificationAsRead(String id) {
    final i = _notifications.indexWhere((n) => n.id == id);
    if (i != -1) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void markAllNotificationsAsRead() {
    for (var i = 0; i < _notifications.length; i++)
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    notifyListeners();
  }

  void deleteNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  // ===== حسابات =====
  double getTankPercentage(Tank tank) =>
      tank.capacity <= 0 ? 0 : (tank.current / tank.capacity) * 100;
  double get totalTankCapacity => _tanks.fold(0, (sum, t) => sum + t.capacity);
  double get totalCurrentStock => _tanks.fold(0, (sum, t) => sum + t.current);
  double get overallFillPercentage =>
      (totalCurrentStock / totalTankCapacity) * 100;
  int get excellentTanks =>
      _tanks.where((t) => t.status == TankStatus.excellent).length;
  int get goodTanks => _tanks.where((t) => t.status == TankStatus.good).length;
  int get mediumTanks =>
      _tanks.where((t) => t.status == TankStatus.medium).length;
  int get lowTanks => _tanks.where((t) => t.status == TankStatus.low).length;
  double get averageDailyConsumption => _dailyConsumption.isEmpty
      ? 0
      : _dailyConsumption.fold(0.0, (s, d) => s + d.consumed) /
          _dailyConsumption.length;

  void deleteReadNotifications() {
    _notifications.removeWhere((n) => n.isRead);
    notifyListeners();
  }

  List<ReportSummary> get reportsSummary => reportSummaries;
  List<ReportSummary> get reportSummaries => [
        ReportSummary(
            title: 'تقرير الوارد اليومي',
            type: 'يومي',
            status: 'جاهز',
            date: DateTime.now(),
            recordCount: _incomingRecords.length),
        ReportSummary(
            title: 'تقرير الصادر اليومي',
            type: 'يومي',
            status: 'جاهز',
            date: DateTime.now(),
            recordCount: 18),
        ReportSummary(
            title: 'تقرير المخزون',
            type: 'أسبوعي',
            status: 'جاهز',
            date: DateTime.now().subtract(const Duration(days: 1)),
            recordCount: _tanks.length),
        ReportSummary(
            title: 'تقرير الاتحاد',
            type: 'شهري',
            status: 'جاهز',
            date: DateTime.now().subtract(const Duration(days: 2)),
            recordCount: _unionTransfers.length),
        ReportSummary(
            title: 'تقرير الاستهلاك',
            type: 'أسبوعي',
            status: 'قيد الإعداد',
            date: DateTime.now().subtract(const Duration(days: 3)),
            recordCount: 30),
        ReportSummary(
            title: 'تقرير حالة الخزانات',
            type: 'يومي',
            status: 'جاهز',
            date: DateTime.now(),
            recordCount: _tanks.length),
        ReportSummary(
            title: 'تقرير مالي شهري',
            type: 'شهري',
            status: 'قيد الإعداد',
            date: DateTime.now().subtract(const Duration(days: 5)),
            recordCount: 45),
        ReportSummary(
            title: 'تقرير المحطات',
            type: 'أسبوعي',
            status: 'جاهز',
            date: DateTime.now().subtract(const Duration(days: 1)),
            recordCount: _stations.length),
        ReportSummary(
            title: 'تقرير المزودين',
            type: 'شهري',
            status: 'جاهز',
            date: DateTime.now().subtract(const Duration(days: 4)),
            recordCount: allSuppliers.length),
      ];

  static String formatNumber(double value) {
    if (value >= 1000000000)
      return '${(value / 1000000000).toStringAsFixed(1)} مليار';
    if (value >= 1000000)
      return '${(value / 1000000).toStringAsFixed(1)} مليون';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)} ألف';
    return value.toStringAsFixed(0);
  }

  static String formatBalance(double value) =>
      NumberFormat('#,###', 'ar').format(value);
}

// ===== نماذج البيانات =====
class Tank {
  final String id, name, location, fuelType;
  final double capacity, current, temperature;
  final DateTime lastFill;
  final TankStatus status;
  Tank(
      {required this.id,
      required this.name,
      required this.location,
      required this.fuelType,
      required this.capacity,
      required this.current,
      required this.temperature,
      required this.lastFill,
      required this.status});
  Tank copyWith(
          {String? id,
          String? name,
          String? location,
          String? fuelType,
          double? capacity,
          double? current,
          double? temperature,
          DateTime? lastFill,
          TankStatus? status}) =>
      Tank(
          id: id ?? this.id,
          name: name ?? this.name,
          location: location ?? this.location,
          fuelType: fuelType ?? this.fuelType,
          capacity: capacity ?? this.capacity,
          current: current ?? this.current,
          temperature: temperature ?? this.temperature,
          lastFill: lastFill ?? this.lastFill,
          status: status ?? this.status);
  double get percentage => capacity > 0 ? (current / capacity) * 100 : 0;
  double get currentAmount => current; // alias
  String get statusText => arabicStatus;
  String get arabicStatus {
    switch (status) {
      case TankStatus.excellent:
        return 'ممتاز';
      case TankStatus.good:
        return 'جيد';
      case TankStatus.medium:
        return 'متوسط';
      case TankStatus.low:
        return 'منخفض';
    }
  }
}

enum TankStatus { excellent, good, medium, low }

extension TankStatusExtension on TankStatus {
  String get arabicName {
    switch (this) {
      case TankStatus.excellent:
        return 'ممتاز';
      case TankStatus.good:
        return 'جيد';
      case TankStatus.medium:
        return 'متوسط';
      case TankStatus.low:
        return 'منخفض';
    }
  }
}

enum NotificationType { success, warning, error, info }

enum ActivityType { incoming, outgoing, transfer }

enum TransferType { receive, send }

class DailyConsumption {
  final DateTime date;
  final double consumed, incoming;
  DailyConsumption(
      {required this.date, required this.consumed, required this.incoming});
  double get net => incoming - consumed;
}

class MonthlyData {
  final String month;
  final double incoming, outgoing, balance;
  MonthlyData(
      {required this.month,
      required this.incoming,
      required this.outgoing,
      required this.balance});
}

class AppNotification {
  final String id, title, message, category;
  final NotificationType type;
  final DateTime time;
  final bool isRead;
  AppNotification(
      {required this.id,
      required this.title,
      required this.message,
      required this.type,
      required this.time,
      required this.category,
      this.isRead = false});
  AppNotification copyWith({bool? isRead}) => AppNotification(
      id: id,
      title: title,
      message: message,
      type: type,
      time: time,
      category: category,
      isRead: isRead ?? this.isRead);

  DateTime get date => time; // alias for compatibility
}

class RecentActivity {
  final ActivityType type;
  final String description;
  final double amount;
  final DateTime time;
  RecentActivity(
      {required this.type,
      required this.description,
      required this.amount,
      required this.time});

  String get title => description; // alias for compatibility
  DateTime get date => time; // alias for compatibility
}

class UnionTransfer {
  final DateTime date;
  final TransferType type;
  final double amount;
  final String source, notes, status;
  UnionTransfer(
      {required this.date,
      required this.type,
      required this.amount,
      required this.source,
      required this.notes,
      required this.status});
}

class DailyBalance {
  final DateTime date;
  final double balance;
  DailyBalance({required this.date, required this.balance});
}

class TankOperation {
  final String tankId, type, operator, notes;
  final double amount;
  final DateTime date;
  TankOperation(
      {required this.tankId,
      required this.type,
      required this.amount,
      required this.date,
      required this.operator,
      this.notes = ''});
}

class ReportSummary {
  final String title, type, status;
  final DateTime date;
  final int recordCount;
  ReportSummary(
      {required this.title,
      required this.type,
      required this.status,
      required this.date,
      required this.recordCount});
}

class StationInfo {
  final String id, name;
  final IconData icon;
  final double balance, dailyConsumption, monthlyTarget;
  final int change, generatorHours, heaterHours;
  final Color color;
  final List<String> farms;
  final List<SubStationInfo>? subStations;
  StationInfo(
      {required this.id,
      required this.name,
      required this.icon,
      required this.balance,
      required this.change,
      required this.color,
      required this.farms,
      this.subStations,
      this.generatorHours = 0,
      this.heaterHours = 0,
      this.dailyConsumption = 0,
      this.monthlyTarget = 0});
  int get totalFarms {
    int c = farms.length;
    if (subStations != null) for (var s in subStations!) c += s.farms.length;
    return c;
  }
}

class SubStationInfo {
  final String name;
  final List<String> farms;
  SubStationInfo({required this.name, required this.farms});
}

class IncomingRecord {
  final String id,
      supplier,
      fuelType,
      tankName,
      driverName,
      truckNumber,
      status,
      color;
  final DateTime date;
  final double quantity, unitPrice, density;
  IncomingRecord(
      {required this.id,
      required this.date,
      required this.supplier,
      required this.fuelType,
      required this.quantity,
      required this.unitPrice,
      required this.tankName,
      required this.driverName,
      required this.truckNumber,
      required this.status,
      this.color = '2.0',
      this.density = 0.85});
  double get totalCost => quantity * unitPrice;

  // Convert to Map for serialization
  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'supplier': supplier,
        'fuelType': fuelType,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'tankName': tankName,
        'driverName': driverName,
        'truckNumber': truckNumber,
        'status': status,
        'color': color,
        'density': density,
      };
}

class RefuelRecord {
  final DateTime date;
  final double quantity;
  RefuelRecord({required this.date, required this.quantity});
}

class Vehicle {
  final String id, plateNumber, driverName, model, vehicleType, fuelType;
  final bool isActive;
  final double totalConsumed, lastQuantity;
  final DateTime lastRefuel;
  final List<RefuelRecord> history;

  Vehicle({
    required this.id,
    required this.plateNumber,
    required this.driverName,
    required this.model,
    required this.vehicleType,
    required this.fuelType,
    required this.isActive,
    required this.totalConsumed,
    required this.lastRefuel,
    required this.lastQuantity,
    required this.history,
  });
}
// =====================================================
// Serializer classes for Hive persistence
// =====================================================

class TankSerializer {
  static Map<String, dynamic> toMap(Tank t) => {
        'id': t.id,
        'name': t.name,
        'location': t.location,
        'fuelType': t.fuelType,
        'capacity': t.capacity,
        'current': t.current,
        'temperature': t.temperature,
        'lastFill': t.lastFill.toIso8601String(),
        'status': t.status.index,
      };
  static Tank fromMap(Map<String, dynamic> m) => Tank(
        id: m['id'] ?? '',
        name: m['name'] ?? '',
        location: m['location'] ?? '',
        fuelType: m['fuelType'] ?? '',
        capacity: (m['capacity'] as num?)?.toDouble() ?? 0,
        current: (m['current'] as num?)?.toDouble() ?? 0,
        temperature: (m['temperature'] as num?)?.toDouble() ?? 0,
        lastFill: DateTime.tryParse(m['lastFill'] ?? '') ?? DateTime.now(),
        status: TankStatus.values[(m['status'] as int?) ?? 0],
      );
}

class IncomingRecordSerializer {
  static Map<String, dynamic> toMap(IncomingRecord r) => {
        'id': r.id,
        'date': r.date.toIso8601String(),
        'supplier': r.supplier,
        'fuelType': r.fuelType,
        'quantity': r.quantity,
        'unitPrice': r.unitPrice,
        'tankName': r.tankName,
        'driverName': r.driverName,
        'truckNumber': r.truckNumber,
        'status': r.status,
        'color': r.color,
        'density': r.density,
      };
  static IncomingRecord fromMap(Map<String, dynamic> m) => IncomingRecord(
        id: m['id'] ?? '',
        date: DateTime.tryParse(m['date'] ?? '') ?? DateTime.now(),
        supplier: m['supplier'] ?? '',
        fuelType: m['fuelType'] ?? '',
        quantity: (m['quantity'] as num?)?.toDouble() ?? 0,
        unitPrice: (m['unitPrice'] as num?)?.toDouble() ?? 0,
        tankName: m['tankName'] ?? '',
        driverName: m['driverName'] ?? '',
        truckNumber: m['truckNumber'] ?? '',
        status: m['status'] ?? '',
        color: m['color'] ?? '2.0',
        density: (m['density'] as num?)?.toDouble() ?? 0.85,
      );
}

class NotificationSerializer {
  static Map<String, dynamic> toMap(AppNotification n) => {
        'id': n.id,
        'title': n.title,
        'message': n.message,
        'category': n.category,
        'type': n.type.index,
        'time': n.time.toIso8601String(),
        'isRead': n.isRead,
      };
  static AppNotification fromMap(Map<String, dynamic> m) => AppNotification(
        id: m['id'] ?? '',
        title: m['title'] ?? '',
        message: m['message'] ?? '',
        category: m['category'] ?? '',
        type: NotificationType.values[(m['type'] as int?) ?? 0],
        time: DateTime.tryParse(m['time'] ?? '') ?? DateTime.now(),
        isRead: m['isRead'] ?? false,
      );
}

class ActivitySerializer {
  static Map<String, dynamic> toMap(RecentActivity a) => {
        'type': a.type.index,
        'description': a.description,
        'amount': a.amount,
        'time': a.time.toIso8601String(),
      };
  static RecentActivity fromMap(Map<String, dynamic> m) => RecentActivity(
        type: ActivityType.values[(m['type'] as int?) ?? 0],
        description: m['description'] ?? '',
        amount: (m['amount'] as num?)?.toDouble() ?? 0,
        time: DateTime.tryParse(m['time'] ?? '') ?? DateTime.now(),
      );
}

class UnionTransferSerializer {
  static Map<String, dynamic> toMap(UnionTransfer t) => {
        'date': t.date.toIso8601String(),
        'type': t.type.index,
        'amount': t.amount,
        'source': t.source,
        'notes': t.notes,
        'status': t.status,
      };
  static UnionTransfer fromMap(Map<String, dynamic> m) => UnionTransfer(
        date: DateTime.tryParse(m['date'] ?? '') ?? DateTime.now(),
        type: TransferType.values[(m['type'] as int?) ?? 0],
        amount: (m['amount'] as num?)?.toDouble() ?? 0,
        source: m['source'] ?? '',
        notes: m['notes'] ?? '',
        status: m['status'] ?? '',
      );
}

class TankOperationSerializer {
  static Map<String, dynamic> toMap(TankOperation o) => {
        'tankId': o.tankId,
        'type': o.type,
        'amount': o.amount,
        'date': o.date.toIso8601String(),
        'operator': o.operator,
        'notes': o.notes,
      };
  static TankOperation fromMap(Map<String, dynamic> m) => TankOperation(
        tankId: m['tankId'] ?? '',
        type: m['type'] ?? '',
        amount: (m['amount'] as num?)?.toDouble() ?? 0,
        date: DateTime.tryParse(m['date'] ?? '') ?? DateTime.now(),
        operator: m['operator'] ?? '',
        notes: m['notes'] ?? '',
      );
}

class GasRecord {
  final String id, station, farm, type, operator, notes;
  final DateTime date;
  final double quantity, unitPrice;
  GasRecord(
      {required this.id,
      required this.date,
      required this.station,
      required this.farm,
      required this.quantity,
      required this.unitPrice,
      required this.type,
      required this.operator,
      this.notes = ''});
  double get totalCost => quantity * unitPrice;
}

// Additional classes for compatibility
// (UnionTransaction is now imported from models/union_transaction.dart)
