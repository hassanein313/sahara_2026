import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'database_service.dart';
import 'license_service.dart';

export '../models/user_model.dart';

/// خدمة المصادقة وإدارة الصلاحيات
class AuthService extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  bool _dbReady = false;

  // ===== المستخدم الحالي =====
  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  String get userName => _currentUser?.name ?? '';
  String get userRole => _currentUser?.role.arabicName ?? '';
  String get userEmail => _currentUser?.email ?? '';
  UserRole get role => _currentUser?.role ?? UserRole.viewer;

  // ===== تحميل من قاعدة البيانات =====
  Future<void> loadFromDatabase() async {
    if (!_db.isInitialized) return;

    // تحميل المستخدمين
    if (_db.hasUsers()) {
      _users.clear();
      for (var m in _db.loadUsers()) {
        _users.add(AppUser(
          id: m['id'] ?? '',
          name: m['name'] ?? '',
          email: m['email'] ?? '',
          phone: m['phone'] ?? '',
          role: UserRole.values[m['role'] ?? 0],
          isActive: m['isActive'] ?? true,
          createdAt: DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
          lastLogin:
              m['lastLogin'] != null ? DateTime.tryParse(m['lastLogin']) : null,
          permissions: m['permissions'] != null
              ? Map<String, bool>.from(m['permissions'])
              : null,
        ));
      }
      // تحميل كلمات المرور
      final passwords = _db.loadPasswords();
      if (passwords.isNotEmpty) {
        _passwords.clear();
        _passwords.addAll(passwords);
      }
    }

    // تحميل سجل الدخول
    final loginMaps = _db.loadLoginHistory();
    if (loginMaps.isNotEmpty) {
      _loginHistory.clear();
      for (var m in loginMaps) {
        _loginHistory.add(LoginRecord(
          userId: m['userId'] ?? '',
          userName: m['userName'] ?? '',
          email: m['email'] ?? '',
          time: DateTime.tryParse(m['time'] ?? '') ?? DateTime.now(),
          success: m['success'] ?? false,
        ));
      }
    }

    // تذكّر آخر مستخدم
    final lastEmail = _db.loadLastUser();
    if (lastEmail != null) {
      debugPrint('📌 آخر مستخدم: $lastEmail');
    }

    _dbReady = true;
    debugPrint('✅ تم تحميل بيانات المصادقة');
    notifyListeners();
  }

  // ===== حفظ في قاعدة البيانات =====
  Future<void> _saveToDatabase() async {
    if (!_db.isInitialized || !_dbReady) return;
    try {
      await _db.saveUsers(_users
          .map((u) => {
                'id': u.id,
                'name': u.name,
                'email': u.email,
                'phone': u.phone,
                'role': u.role.index,
                'isActive': u.isActive,
                'createdAt': u.createdAt.toIso8601String(),
                'lastLogin': u.lastLogin?.toIso8601String(),
                'permissions': u.permissions,
              })
          .toList());
      await _db.savePasswords(_passwords);
      await _db.saveLoginHistory(_loginHistory
          .map((l) => {
                'userId': l.userId,
                'userName': l.userName,
                'email': l.email,
                'time': l.time.toIso8601String(),
                'success': l.success,
              })
          .toList());
    } catch (e) {
      debugPrint('⚠️ خطأ حفظ المصادقة: $e');
    }
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    _saveToDatabase();
  }

  // ===== قاعدة المستخدمين =====
  final List<AppUser> _users = [
    AppUser(
        id: '1',
        name: 'أحمد محمد علي',
        email: 'admin@sahara.com',
        phone: '07801234567',
        role: UserRole.admin,
        createdAt: DateTime(2025, 1, 1),
        lastLogin: DateTime.now()),
    AppUser(
        id: '2',
        name: 'حسين عباس كاظم',
        email: 'manager@sahara.com',
        phone: '07809876543',
        role: UserRole.manager,
        createdAt: DateTime(2025, 3, 15),
        lastLogin: DateTime.now().subtract(const Duration(hours: 2))),
    AppUser(
        id: '3',
        name: 'علي حسن جواد',
        email: 'user@sahara.com',
        phone: '07705551234',
        role: UserRole.operator,
        createdAt: DateTime(2025, 6, 1),
        lastLogin: DateTime.now().subtract(const Duration(days: 1))),
    AppUser(
        id: '4',
        name: 'محمد كريم عبد الله',
        email: 'auditor@sahara.com',
        phone: '07701112233',
        role: UserRole.auditor,
        createdAt: DateTime(2025, 8, 10),
        lastLogin: DateTime.now().subtract(const Duration(days: 3))),
    AppUser(
        id: '5',
        name: 'مستخدم تجريبي',
        email: '1',
        phone: '0780000000',
        role: UserRole.admin,
        createdAt: DateTime(2026, 1, 1),
        lastLogin: DateTime.now()),
    // مستخدمو الباكند
    AppUser(
        id: '6',
        name: 'مدير النظام',
        email: 'admin@sahara-fuel.com',
        phone: '07801234567',
        role: UserRole.admin,
        createdAt: DateTime(2026, 1, 1),
        lastLogin: DateTime.now()),
    AppUser(
        id: '7',
        name: 'مدير المحطة',
        email: 'manager@sahara-fuel.com',
        phone: '07809876543',
        role: UserRole.manager,
        createdAt: DateTime(2026, 1, 1),
        lastLogin: DateTime.now()),
    AppUser(
        id: '8',
        name: 'علي المشغّل',
        email: 'operator@sahara-fuel.com',
        phone: '07705551234',
        role: UserRole.operator,
        createdAt: DateTime(2026, 1, 1),
        lastLogin: DateTime.now()),
  ];

  final Map<String, String> _passwords = {
    'admin@sahara.com': 'admin123',
    'manager@sahara.com': 'manager123',
    'user@sahara.com': 'user123',
    'auditor@sahara.com': 'auditor123',
    '1': '1',
    'admin@sahara-fuel.com': 'admin123',
    'manager@sahara-fuel.com': 'manager123',
    'operator@sahara-fuel.com': 'operator123',
  };

  List<AppUser> get allUsers => List.unmodifiable(_users);

  // ===== تسجيل الدخول =====
  bool login(String email, String password) {
    final trimEmail = email.trim();
    final trimPass = password.trim();
    if (_passwords.containsKey(trimEmail) &&
        _passwords[trimEmail] == trimPass) {
      final userIdx = _users.indexWhere((u) => u.email == trimEmail);
      if (userIdx != -1 && _users[userIdx].isActive) {
        _currentUser = _users[userIdx];
        _loginHistory.add(LoginRecord(
            userId: _currentUser!.id,
            userName: _currentUser!.name,
            email: trimEmail,
            time: DateTime.now(),
            success: true));
        if (_db.isInitialized) _db.saveLastUser(trimEmail);
        notifyListeners();
        return true;
      }
    }
    _loginHistory.add(LoginRecord(
        userId: '',
        userName: trimEmail,
        email: trimEmail,
        time: DateTime.now(),
        success: false));
    notifyListeners();
    return false;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  // ===== صلاحيات الصفحات =====
  bool hasPermission(String pageKey) {
    if (_currentUser == null) return false;
    if (_currentUser!.role == UserRole.admin) return true;
    // لوحة التحكم دائماً متاحة لجميع المستخدمين
    if (pageKey == 'dashboard') return true;
    return _currentUser!.permissions[pageKey] ?? false;
  }

  List<PagePermission> get allowedPages {
    if (_currentUser == null) return [];
    return _allPages.where((p) => hasPermission(p.key)).toList();
  }

  static final List<PagePermission> _allPages = [
    PagePermission(
        key: 'dashboard',
        label: 'الرئيسية',
        icon: Icons.dashboard_rounded,
        index: 0),
    PagePermission(
        key: 'sahara_balance',
        label: 'رصيد الصحاري',
        icon: Icons.account_balance_wallet_rounded,
        index: 1),
    PagePermission(
        key: 'reports',
        label: 'التقارير',
        icon: Icons.analytics_rounded,
        index: 2),
    PagePermission(
        key: 'union_balance',
        label: 'رصيد الاتحاد',
        icon: Icons.swap_horiz_rounded,
        index: 3),
    PagePermission(
        key: 'tanks',
        label: 'خزانات الوقود',
        icon: Icons.propane_tank_rounded,
        index: 4),
    PagePermission(
        key: 'incoming_report',
        label: 'تقرير الوارد',
        icon: Icons.arrow_downward_rounded,
        index: 5),
    PagePermission(
        key: 'advanced_reports',
        label: 'تقارير متقدمة',
        icon: Icons.insights_rounded,
        index: 6),
    PagePermission(
        key: 'station_manager',
        label: 'إدارة المحطات',
        icon: Icons.store_rounded,
        index: 7),
    PagePermission(
        key: 'data_management',
        label: 'إدارة البيانات',
        icon: Icons.cloud_upload_rounded,
        index: 8),
    PagePermission(
        key: 'notifications',
        label: 'الإشعارات',
        icon: Icons.notifications_rounded,
        index: 9),
    PagePermission(
        key: 'audit_trail',
        label: 'سجل العمليات',
        icon: Icons.history_rounded,
        index: 10),
    PagePermission(
        key: 'settings',
        label: 'الإعدادات',
        icon: Icons.settings_rounded,
        index: 11),
    PagePermission(
        key: 'settings',
        label: 'الإعدادات',
        icon: Icons.settings_rounded,
        index: 11),
    PagePermission(
        key: 'gas_balance',
        label: 'رصيد الغاز',
        icon: Icons.local_fire_department_rounded,
        index: 12),
    PagePermission(
        key: 'vehicles',
        label: 'العربات',
        icon: Icons.directions_car_rounded,
        index: 13),
    PagePermission(
        key: 'deserty_eye',
        label: 'عين الصحراء',
        icon: Icons.directions_car_rounded,
        index: 14),
// ← أضف هذا السطر
  ];

  // ===== إدارة المستخدمين =====
  /// إضافة مستخدم جديد مع التحقق من حدود الترخيص
  Future<String?> addUserWithLicenseCheck(AppUser user, String password) async {
    final license = await LicenseService.loadSavedLicense();
    if (license != null) {
      final activeCount = _users.where((u) => u.isActive).length;
      if (activeCount >= license.maxUsers) {
        return 'تم الوصول للحد الأقصى: ${license.maxUsers} مستخدم (الترخيص ${license.typeArabic})';
      }
    }
    _users.add(user);
    _passwords[user.email] = password;
    notifyListeners();
    return null; // نجاح
  }

  void addUser(AppUser user, String password) {
    _users.add(user);
    _passwords[user.email] = password;
    notifyListeners();
  }

  void updateUser(String id,
      {String? name,
      String? email,
      String? phone,
      UserRole? role,
      bool? isActive,
      Map<String, bool>? permissions}) {
    final idx = _users.indexWhere((u) => u.id == id);
    if (idx != -1) {
      final old = _users[idx];
      if (email != null && email != old.email) {
        final pass = _passwords.remove(old.email);
        if (pass != null) _passwords[email] = pass;
      }
      // إذا تغير الدور ولم تُمرر صلاحيات صريحة، نُطبق الافتراضي للدور الجديد
      final finalPerms = permissions ??
          (role != null && role != old.role
              ? AppUser.defaultPermsForRole(role)
              : null);
      _users[idx] = old.copyWith(
          name: name,
          email: email,
          phone: phone,
          role: role,
          isActive: isActive,
          permissions: finalPerms);
      if (_currentUser?.id == id) _currentUser = _users[idx];
      notifyListeners();
    }
  }

  void updateUserPermission(String userId, String pageKey, bool allowed) {
    final idx = _users.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      final perms = Map<String, bool>.from(_users[idx].permissions);
      perms[pageKey] = allowed;
      // ضمان أن لوحة التحكم دائماً متاحة
      perms['dashboard'] = true;
      _users[idx] = _users[idx].copyWith(permissions: perms);
      if (_currentUser?.id == userId) _currentUser = _users[idx];
      notifyListeners();
    }
  }

  /// تعيين جميع الصلاحيات لمستخدم (true أو false)
  void setAllPermissions(String userId, bool value) {
    final idx = _users.indexWhere((u) => u.id == userId);
    if (idx != -1 && _users[idx].role != UserRole.admin) {
      final perms = Map<String, bool>.from(_users[idx].permissions);
      for (var k in perms.keys) perms[k] = value;
      perms['dashboard'] = true; // لوحة التحكم إلزامية
      _users[idx] = _users[idx].copyWith(permissions: perms);
      if (_currentUser?.id == userId) _currentUser = _users[idx];
      notifyListeners();
    }
  }

  /// إعادة صلاحيات المستخدم للافتراضي حسب دوره
  void resetPermissionsToDefault(String userId) {
    final idx = _users.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      _users[idx] = _users[idx]
          .copyWith(permissions: AppUser.defaultPermsForRole(_users[idx].role));
      if (_currentUser?.id == userId) _currentUser = _users[idx];
      notifyListeners();
    }
  }

  void toggleUserActive(String userId) {
    final idx = _users.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      _users[idx] = _users[idx].copyWith(isActive: !_users[idx].isActive);
      notifyListeners();
    }
  }

  // ===== سجل الدخول =====
  final List<LoginRecord> _loginHistory = [];
  List<LoginRecord> get loginHistory => List.unmodifiable(_loginHistory);
}

class PagePermission {
  final String key, label;
  final IconData icon;
  final int index;
  const PagePermission(
      {required this.key,
      required this.label,
      required this.icon,
      required this.index});
}
