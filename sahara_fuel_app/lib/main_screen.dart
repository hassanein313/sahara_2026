import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'pages/sahara_balance_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/reports_page.dart';
import 'pages/tanks_page.dart';
import 'pages/notifications_page.dart';
import 'pages/audit_trail_page.dart';
import 'pages/settings_page.dart';
import 'pages/union_balance_page.dart';
import 'pages/incoming_report_page.dart';
import 'pages/advanced_reports_page.dart'; // Phase 5
import 'pages/station_manager_page.dart'; // Phase 8
import 'pages/data_management_page.dart'; // Data Management
import 'constants/app_colors.dart';
import 'providers/fuel_provider.dart';
import 'services/auth_service.dart';
import 'services/license_service.dart';
import 'services/smart_alert_service.dart'; // Phase 7
import 'widgets/responsive_layout.dart'; // Phase 9
import 'main.dart';
import 'pages/gas_balance_page.dart'; // Gas Balance
import 'pages/vehicles_page.dart';
import 'widgets/theme_toggle_button.dart';
import 'pages/Deserty_eye.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  LicenseInfo? _license;
  bool _bannerDismissed = false;
  bool _showAlertPanel = false; // Phase 7

  @override
  void initState() {
    super.initState();
    _checkLicense();
    // Phase 7: بدء مراقبة التنبيهات الذكية
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final prov = Provider.of<FuelProvider>(context, listen: false);
        SmartAlertService().startMonitoring(prov);
      }
    });
  }

  Future<void> _checkLicense() async {
    final lic = await LicenseService.loadSavedLicense();
    if (mounted) setState(() => _license = lic);
  }

  // خريطة الصفحات حسب المفتاح
  static const Map<String, int> _pageKeyToIndex = {
    'dashboard': 0,
    'sahara_balance': 1,
    'reports': 2,
    'union_balance': 3,
    'tanks': 4,
    'incoming_report': 5,
    'advanced_reports': 6,
    'station_manager': 7,
    'data_management': 8,
    'notifications': 9,
    'audit_trail': 10,
    'settings': 11,
    'gas_balance': 12,
    'vehicles': 13,
    'deserty_eye': 14,
  };

  static const List<Widget> _allPages = [
    DashboardPage(), // 0
    SaharaBalancePage(), // 1
    ReportsPage(), // 2
    UnionBalancePage(), // 3
    TanksPage(), // 4
    IncomingReportPage(), // 5
    AdvancedReportsPage(), // 6  - Phase 5
    StationManagerPage(), // 7  - Phase 8
    DataManagementPage(), // 8  - Data Management
    NotificationsPage(), // 9
    AuditTrailPage(), // 10
    SettingsPage(), // 11
    GasBalancePage(),
    VehiclesPage(),
    DesertEyePage(), // Phase 9
    // 12 - Gas Balance  ← أضف هذا السطر
  ];

  // أقسام القائمة الجانبية
  static const List<_MenuSection> _menuSections = [
    _MenuSection('الصفحات الرئيسية', [
      _MenuItem(
          key: 'dashboard', label: 'الرئيسية', icon: Icons.dashboard_rounded),
      _MenuItem(
          key: 'sahara_balance',
          label: 'رصيد الصحاري',
          icon: Icons.account_balance_wallet_rounded),
      _MenuItem(
          key: 'gas_balance',
          label: 'رصيد الغاز',
          icon: Icons.local_fire_department_rounded), // ← أضف هذا السطر
      _MenuItem(
          key: 'union_balance',
          label: 'رصيد الاتحاد',
          icon: Icons.swap_horiz_rounded),
      _MenuItem(
          key: 'vehicles',
          label: 'العربات',
          icon: Icons.directions_car_rounded),
      _MenuItem(
          key: 'deserty_eye', label: 'عين الصحراء', icon: Icons.map_rounded),
    ]),
    _MenuSection('التقارير والتحليلات', [
      _MenuItem(
          key: 'reports', label: 'التقارير', icon: Icons.analytics_rounded),
      _MenuItem(
          key: 'advanced_reports',
          label: 'تقارير متقدمة',
          icon: Icons.insights_rounded),
      _MenuItem(
          key: 'incoming_report',
          label: 'تقرير الوارد',
          icon: Icons.arrow_downward_rounded),
      _MenuItem(
          key: 'tanks',
          label: 'خزانات الوقود',
          icon: Icons.propane_tank_rounded),
    ]),
    _MenuSection('الإدارة', [
      _MenuItem(
          key: 'station_manager',
          label: 'إدارة المحطات',
          icon: Icons.store_rounded),
      _MenuItem(
          key: 'data_management',
          label: 'إدارة البيانات',
          icon: Icons.cloud_upload_rounded),
    ]),
    _MenuSection('النظام', [
      _MenuItem(
          key: 'notifications',
          label: 'الإشعارات',
          icon: Icons.notifications_rounded,
          hasBadge: true),
      _MenuItem(
          key: 'audit_trail',
          label: 'سجل العمليات',
          icon: Icons.history_rounded),
      _MenuItem(
          key: 'settings', label: 'الإعدادات', icon: Icons.settings_rounded),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final fuel = Provider.of<FuelProvider>(context);

    // الصفحات المسموحة
    final allowed = auth.allowedPages;
    final allowedKeys = allowed.map((p) => p.key).toSet();

    // ضمان أن الفهرس المحدد ضمن المسموح
    if (_selectedIndex >= _allPages.length) _selectedIndex = 0;

    // استخراج مفتاح الصفحة الحالية
    String currentPageKey = _pageKeyToIndex.entries
        .firstWhere((e) => e.value == _selectedIndex,
            orElse: () => const MapEntry('dashboard', 0))
        .key;

    // إذا الصفحة غير مسموحة، نعيد التوجيه لأول صفحة مسموحة
    final isCurrentAllowed = allowedKeys.contains(currentPageKey);
    if (!isCurrentAllowed && allowed.isNotEmpty) {
      // لا نغيّر _selectedIndex تلقائياً - نعرض صفحة الوصول المرفوض
      // المستخدم يقدر يضغط زر العودة
    }

    return Scaffold(
      body: Stack(children: [
        // === التحقق من الصلاحية قبل عرض الصفحة ===
        if (isCurrentAllowed)
          _allPages[_selectedIndex]
        else
          _accessDeniedPage(auth),
        // === شريط المعلومات العلوي ===
        Positioned(
            top: 20,
            right: 20,
            child: Row(children: [
              // معلومات المستخدم + دوره
              if (auth.isLoggedIn)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  margin: const EdgeInsets.only(left: 12),
                  decoration: BoxDecoration(
                      color: const Color(0xFF1A1F2E).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.accent.withOpacity(0.2))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    CircleAvatar(
                        radius: 14,
                        backgroundColor: auth.role.color.withOpacity(0.2),
                        child: Icon(auth.role.icon,
                            color: auth.role.color, size: 16)),
                    const SizedBox(width: 8),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(auth.userName,
                              style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          Row(children: [
                            Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                    color: auth.role.color,
                                    shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Text(auth.userRole,
                                style: GoogleFonts.cairo(
                                    fontSize: 10, color: auth.role.color)),
                          ]),
                        ]),
                  ]),
                ),
              // شارة الإشعارات
              if (fuel.unreadNotifications > 0 &&
                  allowedKeys.contains('notifications'))
                GestureDetector(
                  onTap: () => setState(
                      () => _selectedIndex = _pageKeyToIndex['notifications']!),
                  child: Container(
                      margin: const EdgeInsets.only(left: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: const Color(0xFF1A1F2E).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.accent.withOpacity(0.2))),
                      child: Stack(clipBehavior: Clip.none, children: [
                        const Icon(Icons.notifications_outlined,
                            color: Colors.white, size: 20),
                        Positioned(
                            top: -6,
                            right: -6,
                            child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                    color: Colors.red, shape: BoxShape.circle),
                                child: Text('${fuel.unreadNotifications}',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)))),
                      ])),
                ),
              // Phase 7: زر التنبيهات الذكية
              GestureDetector(
                onTap: () => setState(() => _showAlertPanel = !_showAlertPanel),
                child: Container(
                    margin: const EdgeInsets.only(left: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: const Color(0xFF1A1F2E).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: SmartAlertService().criticalCount > 0
                                ? const Color(0xFFEF5350).withOpacity(0.4)
                                : const Color(0xFFFFA726).withOpacity(0.2))),
                    child: Stack(clipBehavior: Clip.none, children: [
                      Icon(Icons.notifications_active,
                          color: SmartAlertService().criticalCount > 0
                              ? const Color(0xFFEF5350)
                              : const Color(0xFFFFA726),
                          size: 20),
                      if (SmartAlertService().activeCount > 0)
                        Positioned(
                            top: -6,
                            right: -6,
                            child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                    color: SmartAlertService().criticalCount > 0
                                        ? const Color(0xFFEF5350)
                                        : const Color(0xFFFFA726),
                                    shape: BoxShape.circle),
                                child: Text(
                                    '${SmartAlertService().activeCount}',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold)))),
                    ])),
              ),
              // زر الوضع الليلي/النهاري
              Container(
                  margin: const EdgeInsets.only(left: 12),
                  decoration: BoxDecoration(
                      color: const Color(0xFF1A1F2E).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.accent.withOpacity(0.2))),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: ThemeToggleButton(),
                  )),
              // زر القائمة
              Builder(
                  builder: (context) => Container(
                        margin: const EdgeInsets.only(left: 12),
                        decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              AppColors.accent,
                              AppColors.accent.withOpacity(0.8)
                            ]),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                  color: AppColors.accent.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4))
                            ]),
                        child: IconButton(
                            icon: const Icon(Icons.menu,
                                color: Colors.white, size: 22),
                            onPressed: () =>
                                Scaffold.of(context).openEndDrawer()),
                      )),
            ])),
        // Phase 7: لوحة التنبيهات العائمة
        if (_showAlertPanel) const FloatingAlertsPanel(),
        // === شريط تحذير الترخيص ===
        if (_license != null &&
            !_bannerDismissed &&
            (_license!.type == LicenseType.trial ||
                _license!.daysRemaining <= 30))
          Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    _license!.isExpired
                        ? const Color(0xFFEF5350)
                        : _license!.daysRemaining <= 7
                            ? const Color(0xFFFF7043)
                            : const Color(0xFFFFA726),
                    _license!.isExpired
                        ? const Color(0xFFD32F2F)
                        : _license!.daysRemaining <= 7
                            ? const Color(0xFFE64A19)
                            : const Color(0xFFFF8F00),
                  ]),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, -3))
                  ],
                ),
                child: Row(children: [
                  Icon(_license!.isExpired ? Icons.error : Icons.warning_amber,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(
                          _license!.isExpired
                              ? 'انتهت صلاحية الترخيص! يرجى التجديد للاستمرار.'
                              : _license!.type == LicenseType.trial
                                  ? 'وضع تجريبي - متبقي ${_license!.daysRemaining} يوم (${_license!.maxStations} محطات، ${_license!.maxUsers} مستخدمين)'
                                  : 'ينتهي الترخيص خلال ${_license!.daysRemaining} يوم - تواصل مع الدعم للتجديد',
                          style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold))),
                  const SizedBox(width: 8),
                  GestureDetector(
                      onTap: () => setState(() => _bannerDismissed = true),
                      child: const Icon(Icons.close,
                          color: Colors.white70, size: 18)),
                ]),
              )),
      ]),
      endDrawer: _buildDrawer(auth, fuel, allowedKeys),
    );
  }

  // ===== صفحة الوصول المرفوض =====
  Widget _accessDeniedPage(AuthService auth) {
    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.pageGradient)),
      child: Center(
          child: Container(
        width: 420,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border:
                Border.all(color: const Color(0xFFEF5350).withOpacity(0.2))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                  color: const Color(0xFFEF5350).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20)),
              child:
                  const Icon(Icons.lock, color: Color(0xFFEF5350), size: 40)),
          const SizedBox(height: 24),
          Text('الوصول مرفوض',
              style: GoogleFonts.cairo(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFEF5350))),
          const SizedBox(height: 8),
          Text('ليس لديك صلاحية للوصول إلى هذه الصفحة',
              style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey[400])),
          const SizedBox(height: 6),
          Text('تواصل مع مدير النظام لتعديل صلاحياتك',
              style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 20),
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: const Color(0xFF1A1F2E),
                  borderRadius: BorderRadius.circular(12)),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(auth.role.icon, color: auth.role.color, size: 16),
                const SizedBox(width: 8),
                Text('${auth.userName} (${auth.userRole})',
                    style: GoogleFonts.cairo(
                        color: Colors.grey[400], fontSize: 12)),
                const SizedBox(width: 10),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text('${auth.allowedPages.length} صفحة متاحة',
                        style: GoogleFonts.cairo(
                            color: AppColors.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold))),
              ])),
          const SizedBox(height: 20),
          SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () {
                  final firstAllowed = auth.allowedPages.isNotEmpty
                      ? _pageKeyToIndex[auth.allowedPages.first.key] ?? 0
                      : 0;
                  setState(() => _selectedIndex = firstAllowed);
                },
                icon: const Icon(Icons.arrow_back, size: 18),
                label: Text('العودة للصفحة الرئيسية',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
              )),
        ]),
      )),
    );
  }

  // ===== القائمة الجانبية مع فلترة الصلاحيات =====
  Widget _buildDrawer(
      AuthService auth, FuelProvider fuel, Set<String> allowedKeys) {
    return Drawer(
      backgroundColor: const Color(0xFF1A1F2E),
      width: 280,
      child: Column(children: [
        // هيدر القائمة
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
            AppColors.accent.withOpacity(0.3),
            const Color(0xFF1A1F2E)
          ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
          child: Column(children: [
            Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      AppColors.accent,
                      AppColors.accent.withOpacity(0.7)
                    ]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.accent.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ]),
                child: const Icon(Icons.local_gas_station,
                    color: Colors.white, size: 38)),
            const SizedBox(height: 16),
            Text('صحاري كربلاء',
                style: GoogleFonts.cairo(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('نظام إدارة الوقود',
                style:
                    GoogleFonts.cairo(fontSize: 12, color: Colors.grey[500])),
            if (auth.isLoggedIn) ...[
              const SizedBox(height: 12),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                      color: auth.role.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: auth.role.color.withOpacity(0.3))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(auth.role.icon, color: auth.role.color, size: 14),
                    const SizedBox(width: 6),
                    Text('${auth.userName} - ${auth.userRole}',
                        style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: auth.role.color,
                            fontWeight: FontWeight.bold)),
                  ])),
            ],
            // شارة الترخيص
            if (_license != null) ...[
              const SizedBox(height: 8),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                      color: (_license!.type == LicenseType.trial
                              ? const Color(0xFFFFA726)
                              : _license!.type == LicenseType.permanent
                                  ? AppColors.accent
                                  : const Color(0xFF42A5F5))
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: (_license!.type == LicenseType.trial
                                  ? const Color(0xFFFFA726)
                                  : _license!.type == LicenseType.permanent
                                      ? AppColors.accent
                                      : const Color(0xFF42A5F5))
                              .withOpacity(0.3))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.vpn_key,
                        size: 12,
                        color: _license!.type == LicenseType.trial
                            ? const Color(0xFFFFA726)
                            : _license!.type == LicenseType.permanent
                                ? AppColors.accent
                                : const Color(0xFF42A5F5)),
                    const SizedBox(width: 4),
                    Text(
                        '${_license!.typeArabic} ${_license!.isExpired ? "(منتهي)" : "• ${_license!.daysRemaining} يوم"}',
                        style: GoogleFonts.cairo(
                            fontSize: 9,
                            color: _license!.type == LicenseType.trial
                                ? const Color(0xFFFFA726)
                                : _license!.type == LicenseType.permanent
                                    ? AppColors.accent
                                    : const Color(0xFF42A5F5),
                            fontWeight: FontWeight.bold)),
                  ])),
            ],
          ]),
        ),
        const SizedBox(height: 10),

        // عناصر القائمة — المسموحة + المحظورة (مقفلة)
        Expanded(
            child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
              for (final section in _menuSections) ...[
                _menuSectionHeader(section.title),
                for (final item in section.items)
                  allowedKeys.contains(item.key)
                      ? _drawerItem(
                          item.label, item.icon, _pageKeyToIndex[item.key]!,
                          badge: item.hasBadge ? fuel.unreadNotifications : 0)
                      : _lockedDrawerItem(item.label, item.icon),
                const SizedBox(height: 16),
              ],
            ])),

        // عدد الصفحات المتاحة
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.lock_open,
                  color: AppColors.accent.withOpacity(0.5), size: 14),
              const SizedBox(width: 6),
              Text(
                  '${allowedKeys.length} صفحة متاحة من ${_pageKeyToIndex.length}',
                  style:
                      GoogleFonts.cairo(fontSize: 10, color: Colors.grey[600])),
            ])),

        // تسجيل الخروج
        Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.logout_rounded,
                      color: Colors.red, size: 20)),
              title: Text('تسجيل الخروج',
                  style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: Colors.red,
                      fontWeight: FontWeight.w500)),
              onTap: () => _confirmLogout(auth),
            )),
        Container(
            padding: const EdgeInsets.all(16),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.circle, color: AppColors.accent, size: 8),
              const SizedBox(width: 8),
              Text('الإصدار 2.0.0',
                  style:
                      GoogleFonts.cairo(fontSize: 11, color: Colors.grey[600])),
            ])),
      ]),
    );
  }

  void _confirmLogout(AuthService auth) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1A1F2E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text('تسجيل الخروج',
                  style: GoogleFonts.cairo(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              content: Text('هل أنت متأكد من تسجيل الخروج؟',
                  style: GoogleFonts.cairo(color: Colors.grey[400])),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('إلغاء',
                        style: GoogleFonts.cairo(color: Colors.grey[500]))),
                ElevatedButton(
                    onPressed: () {
                      auth.logout();
                      Navigator.pop(ctx);
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (_) => const LoginPage()));
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                    child: Text('خروج',
                        style: GoogleFonts.cairo(color: Colors.white))),
              ],
            ));
  }

  Widget _menuSectionHeader(String title) => Padding(
      padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
      child: Text(title,
          style: GoogleFonts.cairo(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600)));

  Widget _drawerItem(String title, IconData icon, int index, {int badge = 0}) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppColors.accent.withOpacity(0.3))
              : null),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent.withOpacity(0.2)
                    : Colors.grey[800],
                borderRadius: BorderRadius.circular(10)),
            child: Stack(clipBehavior: Clip.none, children: [
              Center(
                  child: Icon(icon,
                      color: isSelected ? AppColors.accent : Colors.grey[500],
                      size: 20)),
              if (badge > 0)
                Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle),
                        child: Text('$badge',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold)))),
            ])),
        title: Text(title,
            style: GoogleFonts.cairo(
                fontSize: 14,
                color: isSelected ? AppColors.accent : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
        trailing: isSelected
            ? Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(2)))
            : null,
        onTap: () {
          setState(() => _selectedIndex = index);
          Navigator.pop(context);
        },
      ),
    );
  }

  // عنصر قائمة مقفل (غير مسموح)
  Widget _lockedDrawerItem(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(10)),
            child: Stack(clipBehavior: Clip.none, children: [
              Center(child: Icon(icon, color: Colors.grey[700], size: 20)),
              Positioned(
                  bottom: -2,
                  left: -2,
                  child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                          color: const Color(0xFF1A1F2E),
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.grey[800]!, width: 1)),
                      child:
                          Icon(Icons.lock, color: Colors.grey[600], size: 10))),
            ])),
        title: Text(title,
            style: GoogleFonts.cairo(
                fontSize: 13,
                color: Colors.grey[700],
                fontWeight: FontWeight.w400)),
        trailing: Icon(Icons.block, color: Colors.grey[800], size: 14),
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Row(children: [
              const Icon(Icons.lock, color: Colors.white, size: 16),
              const SizedBox(width: 10),
              Text('ليس لديك صلاحية للوصول إلى "$title"',
                  style: GoogleFonts.cairo(fontSize: 12)),
            ]),
            backgroundColor: const Color(0xFFEF5350),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ));
        },
      ),
    );
  }
}

// ===== نماذج القائمة =====
class _MenuSection {
  final String title;
  final List<_MenuItem> items;
  const _MenuSection(this.title, this.items);
}

class _MenuItem {
  final String key, label;
  final IconData icon;
  final bool hasBadge;
  const _MenuItem(
      {required this.key,
      required this.label,
      required this.icon,
      this.hasBadge = false});
}
