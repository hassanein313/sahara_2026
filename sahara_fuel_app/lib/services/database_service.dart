import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// خدمة قاعدة البيانات المحلية باستخدام Hive
/// تستخدم من: FuelProvider, AuthService, CloudSyncService, SettingsPage
class DatabaseService {
  // Singleton
  static final DatabaseService _instance = DatabaseService._();
  factory DatabaseService() => _instance;
  DatabaseService._();

  // صناديق Hive
  Box? _balancesBox;
  Box? _tanksBox;
  Box? _incomingBox;
  Box? _notificationsBox;
  Box? _activitiesBox;
  Box? _unionBox;
  Box? _tankOpsBox;
  Box? _usersBox;
  Box? _settingsBox;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  // ===== التهيئة =====
  Future<void> init() async {
    if (_initialized) return;
    try {
      await Hive.initFlutter();
      _balancesBox = await Hive.openBox('balances');
      _tanksBox = await Hive.openBox('tanks');
      _incomingBox = await Hive.openBox('incoming_records');
      _notificationsBox = await Hive.openBox('notifications');
      _activitiesBox = await Hive.openBox('activities');
      _unionBox = await Hive.openBox('union_transfers');
      _tankOpsBox = await Hive.openBox('tank_operations');
      _usersBox = await Hive.openBox('users');
      _settingsBox = await Hive.openBox('settings');
      _initialized = true;
      debugPrint('✅ قاعدة البيانات Hive جاهزة');
    } catch (e) {
      debugPrint('⚠️ خطأ تهيئة Hive: $e');
    }
  }

  // ===== إحصائيات =====
  Map<String, int> get stats => {
    'الأرصدة': _balancesBox?.length ?? 0,
    'الخزانات': (_tanksBox?.get('data') as List?)?.length ?? 0,
    'سجلات الوارد': (_incomingBox?.get('data') as List?)?.length ?? 0,
    'الإشعارات': (_notificationsBox?.get('data') as List?)?.length ?? 0,
    'الأنشطة': (_activitiesBox?.get('data') as List?)?.length ?? 0,
    'تحويلات الاتحاد': (_unionBox?.get('data') as List?)?.length ?? 0,
    'عمليات الخزانات': (_tankOpsBox?.get('data') as List?)?.length ?? 0,
    'المستخدمين': (_usersBox?.get('users') as List?)?.length ?? 0,
  };

  // =============================================
  //  الأرصدة
  // =============================================
  bool hasBalances() => _balancesBox?.isNotEmpty ?? false;

  Map<String, double> loadBalances() {
    if (_balancesBox == null) return {};
    return {
      'saharaBalance': (_balancesBox!.get('saharaBalance') as num?)?.toDouble() ?? 0,
      'unionBalance': (_balancesBox!.get('unionBalance') as num?)?.toDouble() ?? 0,
      'stationsBalance': (_balancesBox!.get('stationsBalance') as num?)?.toDouble() ?? 0,
      'todayIncoming': (_balancesBox!.get('todayIncoming') as num?)?.toDouble() ?? 0,
      'todayOutgoing': (_balancesBox!.get('todayOutgoing') as num?)?.toDouble() ?? 0,
      'saharaChange': (_balancesBox!.get('saharaChange') as num?)?.toDouble() ?? 0,
      'unionChange': (_balancesBox!.get('unionChange') as num?)?.toDouble() ?? 0,
      'stationsChange': (_balancesBox!.get('stationsChange') as num?)?.toDouble() ?? 0,
    };
  }

  Future<void> saveBalances({
    required double saharaBalance,
    required double unionBalance,
    required double stationsBalance,
    required double todayIncoming,
    required double todayOutgoing,
    required double saharaChange,
    required double unionChange,
    required double stationsChange,
  }) async {
    if (_balancesBox == null) return;
    await _balancesBox!.putAll({
      'saharaBalance': saharaBalance,
      'unionBalance': unionBalance,
      'stationsBalance': stationsBalance,
      'todayIncoming': todayIncoming,
      'todayOutgoing': todayOutgoing,
      'saharaChange': saharaChange,
      'unionChange': unionChange,
      'stationsChange': stationsChange,
    });
  }

  // =============================================
  //  الخزانات
  // =============================================
  bool hasTanks() => (_tanksBox?.get('data') as List?)?.isNotEmpty ?? false;

  List<Map<String, dynamic>> loadTanks() {
    final data = _tanksBox?.get('data');
    if (data == null) return [];
    return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> saveTanks(List<Map<String, dynamic>> tanks) async {
    await _tanksBox?.put('data', tanks);
  }

  // =============================================
  //  سجلات الوارد
  // =============================================
  bool hasIncoming() => (_incomingBox?.get('data') as List?)?.isNotEmpty ?? false;

  List<Map<String, dynamic>> loadIncomingRecords() {
    final data = _incomingBox?.get('data');
    if (data == null) return [];
    return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> saveIncomingRecords(List<Map<String, dynamic>> records) async {
    await _incomingBox?.put('data', records);
  }

  // =============================================
  //  الإشعارات
  // =============================================
  List<Map<String, dynamic>> loadNotifications() {
    final data = _notificationsBox?.get('data');
    if (data == null) return [];
    return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> saveNotifications(List<Map<String, dynamic>> notifications) async {
    await _notificationsBox?.put('data', notifications);
  }

  // =============================================
  //  الأنشطة
  // =============================================
  List<Map<String, dynamic>> loadActivities() {
    final data = _activitiesBox?.get('data');
    if (data == null) return [];
    return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> saveActivities(List<Map<String, dynamic>> activities) async {
    await _activitiesBox?.put('data', activities);
  }

  // =============================================
  //  تحويلات الاتحاد
  // =============================================
  bool hasUnionTransfers() => (_unionBox?.get('data') as List?)?.isNotEmpty ?? false;

  List<Map<String, dynamic>> loadUnionTransfers() {
    final data = _unionBox?.get('data');
    if (data == null) return [];
    return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> saveUnionTransfers(List<Map<String, dynamic>> transfers) async {
    await _unionBox?.put('data', transfers);
  }

  // =============================================
  //  عمليات الخزانات
  // =============================================
  List<Map<String, dynamic>> loadTankOperations() {
    final data = _tankOpsBox?.get('data');
    if (data == null) return [];
    return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> saveTankOperations(List<Map<String, dynamic>> operations) async {
    await _tankOpsBox?.put('data', operations);
  }

  // =============================================
  //  المستخدمين والمصادقة
  // =============================================
  bool hasUsers() => (_usersBox?.get('users') as List?)?.isNotEmpty ?? false;

  List<Map<String, dynamic>> loadUsers() {
    final data = _usersBox?.get('users');
    if (data == null) return [];
    return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> saveUsers(List<Map<String, dynamic>> users) async {
    await _usersBox?.put('users', users);
  }

  Map<String, String> loadPasswords() {
    final data = _usersBox?.get('passwords');
    if (data == null) return {};
    return Map<String, String>.from(data);
  }

  Future<void> savePasswords(Map<String, String> passwords) async {
    await _usersBox?.put('passwords', passwords);
  }

  List<Map<String, dynamic>> loadLoginHistory() {
    final data = _usersBox?.get('login_history');
    if (data == null) return [];
    return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> saveLoginHistory(List<Map<String, dynamic>> history) async {
    await _usersBox?.put('login_history', history);
  }

  String? loadLastUser() {
    return _usersBox?.get('last_user') as String?;
  }

  Future<void> saveLastUser(String email) async {
    await _usersBox?.put('last_user', email);
  }

  // =============================================
  //  الإعدادات
  // =============================================
  dynamic loadSetting(String key) {
    return _settingsBox?.get(key);
  }

  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox?.put(key, value);
  }

  // =============================================
  //  تصدير / استيراد (للمزامنة السحابية)
  // =============================================
  Map<String, dynamic> exportAll() {
    return {
      'balances': _balancesBox?.toMap(),
      'tanks': _tanksBox?.get('data'),
      'incoming': _incomingBox?.get('data'),
      'notifications': _notificationsBox?.get('data'),
      'activities': _activitiesBox?.get('data'),
      'union_transfers': _unionBox?.get('data'),
      'tank_operations': _tankOpsBox?.get('data'),
      'users': _usersBox?.toMap(),
      'settings': _settingsBox?.toMap(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  Future<void> importAll(Map<String, dynamic> data) async {
    if (data['tanks'] != null) await _tanksBox?.put('data', data['tanks']);
    if (data['incoming'] != null) await _incomingBox?.put('data', data['incoming']);
    if (data['notifications'] != null) await _notificationsBox?.put('data', data['notifications']);
    if (data['activities'] != null) await _activitiesBox?.put('data', data['activities']);
    if (data['union_transfers'] != null) await _unionBox?.put('data', data['union_transfers']);
    if (data['tank_operations'] != null) await _tankOpsBox?.put('data', data['tank_operations']);
    debugPrint('✅ تم استيراد البيانات');
  }

  // =============================================
  //  مسح جميع البيانات
  // =============================================
  Future<void> clearAll() async {
    await _balancesBox?.clear();
    await _tanksBox?.clear();
    await _incomingBox?.clear();
    await _notificationsBox?.clear();
    await _activitiesBox?.clear();
    await _unionBox?.clear();
    await _tankOpsBox?.clear();
    await _usersBox?.clear();
    // لا نمسح الإعدادات
    debugPrint('🗑️ تم مسح جميع البيانات');
  }
}

