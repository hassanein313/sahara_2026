import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import '../constants/app_colors.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/license_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/smart_alert_service.dart';
import '../models/user_model.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _notif = true, _autoBackup = true, _soundAlerts = false;
  String _lang = 'العربية', _backupFreq = 'يومي';

  static const _pageLabels = {
    'dashboard': 'لوحة التحكم',
    'incoming_report': 'تقرير الوارد',
    'sahara_balance': 'رصيد الصحاري',
    'union_balance': 'رصيد الاتحاد',
    'tanks': 'الخزانات',
    'reports': 'التقارير',
    'advanced_reports': 'تقارير متقدمة',
    'station_manager': 'إدارة المحطات',
    'notifications': 'الإشعارات',
    'settings': 'الإعدادات',
    'audit_trail': 'سجل المراجعة'
  };
  static const _pageIcons = <String, IconData>{
    'dashboard': Icons.dashboard,
    'incoming_report': Icons.local_shipping,
    'sahara_balance': Icons.account_balance_wallet,
    'union_balance': Icons.account_balance,
    'tanks': Icons.propane_tank,
    'reports': Icons.assessment,
    'advanced_reports': Icons.insights,
    'station_manager': Icons.store,
    'notifications': Icons.notifications,
    'settings': Icons.settings,
    'audit_trail': Icons.history
  };

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 8, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(builder: (context, auth, _) {
      final users = auth.allUsers;
      return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppColors.getPageGradient(context))),
            child: Column(children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('الإعدادات',
                                  style: GoogleFonts.cairo(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                              Text('إدارة النظام والمستخدمين والصلاحيات',
                                  style: GoogleFonts.cairo(
                                      fontSize: 14, color: Colors.grey[500])),
                            ]),
                        Row(children: [
                          _badge('${users.where((u) => u.isActive).length} نشط',
                              Icons.people, AppColors.getAccent(context)),
                          const SizedBox(width: 12),
                          _badge('v2.0.0', Icons.info_outline,
                              const Color(0xFF8B5CF6)),
                        ]),
                      ])),
              const SizedBox(height: 20),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                        color: AppColors.getSurface(context),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF2D3748))),
                    child: TabBar(
                        controller: _tabCtrl,
                        isScrollable: true,
                        dividerHeight: 0,
                        splashBorderRadius: BorderRadius.circular(12),
                        indicator: BoxDecoration(
                            color: AppColors.getAccent(context).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.getAccent(context).withOpacity(0.4))),
                        labelColor: AppColors.getAccent(context),
                        unselectedLabelColor: Colors.grey[500],
                        labelStyle: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold, fontSize: 12),
                        unselectedLabelStyle: GoogleFonts.cairo(fontSize: 11),
                        indicatorSize: TabBarIndicatorSize.tab,
                        tabs: const [
                          Tab(text: 'المستخدمين'),
                          Tab(text: 'الصلاحيات'),
                          Tab(text: 'النظام'),
                          Tab(text: 'النسخ الاحتياطي'),
                          Tab(text: 'الترخيص'),
                          Tab(text: 'المزامنة ☁️'),
                          Tab(text: 'التنبيهات 🔔'),
                          Tab(text: 'حول')
                        ]),
                  )),
              const SizedBox(height: 16),
              Expanded(
                  child: TabBarView(controller: _tabCtrl, children: [
                _usersTab(auth, users),
                _permissionsTab(auth, users),
                _systemTab(auth),
                _backupTab(),
                _licenseTab(),
                const CloudSyncWidget(),
                _smartAlertsTab(),
                _aboutTab()
              ])),
            ]),
          ));
    });
  }

  // ===== تاب المستخدمين - يقرأ من AuthService =====
  Widget _usersTab(AuthService auth, List<AppUser> users) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Row(children: [
            _stat('الكل', '${users.length}', const Color(0xFF42A5F5),
                Icons.people),
            const SizedBox(width: 12),
            _stat('نشط', '${users.where((u) => u.isActive).length}',
                AppColors.getAccent(context), Icons.check_circle),
            const SizedBox(width: 12),
            _stat('معطّل', '${users.where((u) => !u.isActive).length}',
                AppColors.getError(context), Icons.block),
            const Spacer(),
            GestureDetector(
                onTap: () => _addUserDialog(auth),
                child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                        color: AppColors.getAccent(context),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.getAccent(context).withOpacity(0.3),
                              blurRadius: 8)
                        ]),
                    child: Row(children: [
                      const Icon(Icons.person_add,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text('إضافة مستخدم',
                          style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13))
                    ]))),
          ]),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2D3748))),
            child: Column(children: [
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                      color: Color(0xFF1E2127),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16))),
                  child: Row(children: [
                    _th('المستخدم', 3),
                    _th('الدور', 2),
                    _th('الهاتف', 2),
                    _th('آخر دخول', 2),
                    _th('الحالة', 1),
                    _th('إجراءات', 2)
                  ])),
              ...List.generate(users.length, (i) {
                final u = users[i];
                final isCurrent = auth.currentUser?.id == u.id;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  color: i.isOdd
                      ? const Color(0xFF1E2127).withOpacity(0.3)
                      : Colors.transparent,
                  child: Row(children: [
                    Expanded(
                        flex: 3,
                        child: Row(children: [
                          Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                  color: u.role.color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Center(
                                  child: Text(u.name[0],
                                      style: GoogleFonts.cairo(
                                          color: u.role.color,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)))),
                          const SizedBox(width: 12),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Text(u.name,
                                      style: GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                  if (isCurrent)
                                    Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                            color: AppColors.getAccent(context)
                                                .withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(6)),
                                        child: Text('أنت',
                                            style: GoogleFonts.cairo(
                                                color: AppColors.getAccent(context),
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold))),
                                ]),
                                Row(children: [
                                  Text(u.email,
                                      style: GoogleFonts.cairo(
                                          color: Colors.grey[600],
                                          fontSize: 11)),
                                  const SizedBox(width: 6),
                                  Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                          color: const Color(0xFFFFA726)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                      child: Text(
                                          '${u.permissions.values.where((v) => v).length} صفحة',
                                          style: GoogleFonts.cairo(
                                              color: const Color(0xFFFFA726),
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold))),
                                ]),
                              ]),
                        ])),
                    Expanded(
                        flex: 2,
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: u.role.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8)),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(u.role.icon, color: u.role.color, size: 14),
                              const SizedBox(width: 6),
                              Text(u.role.arabicName,
                                  style: GoogleFonts.cairo(
                                      color: u.role.color,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold))
                            ]))),
                    Expanded(
                        flex: 2,
                        child: Text(u.phone,
                            style: GoogleFonts.cairo(
                                color: Colors.grey[400], fontSize: 12),
                            textAlign: TextAlign.center)),
                    Expanded(
                        flex: 2,
                        child: Text(
                            u.lastLogin != null ? _timeAgo(u.lastLogin!) : '-',
                            style: GoogleFonts.cairo(
                                color: Colors.grey[500], fontSize: 11),
                            textAlign: TextAlign.center)),
                    Expanded(
                        flex: 1,
                        child: Center(
                            child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                    color: u.isActive
                                        ? AppColors.getAccent(context)
                                        : AppColors.getError(context),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                          color: (u.isActive
                                                  ? AppColors.getAccent(context)
                                                  : AppColors.getError(context))
                                              .withOpacity(0.4),
                                          blurRadius: 6)
                                    ])))),
                    Expanded(
                        flex: 2,
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _iconBtn(Icons.vpn_key, const Color(0xFFFFA726),
                                  () => _permissionsDialog(auth, u)),
                              const SizedBox(width: 4),
                              _iconBtn(Icons.edit, AppColors.getAccent(context),
                                  () => _editUserDialog(auth, u)),
                              const SizedBox(width: 4),
                              if (!isCurrent)
                                _iconBtn(
                                    u.isActive
                                        ? Icons.block
                                        : Icons.check_circle,
                                    u.isActive
                                        ? AppColors.getError(context)
                                        : AppColors.getAccent(context),
                                    () => auth.toggleUserActive(u.id)),
                            ])),
                  ]),
                );
              }),
            ]),
          ),
        ]));
  }

  // ===== تاب الصلاحيات - يكتب في AuthService =====
  Widget _permissionsTab(AuthService auth, List<AppUser> users) {
    final activeUsers = users.where((u) => u.isActive).toList();
    return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('مصفوفة الصلاحيات',
                  style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              Text(
                  'تحكم بصلاحيات كل مستخدم لكل تبويب - التغييرات تُطبق فوراً وتُحفظ',
                  style:
                      GoogleFonts.cairo(fontSize: 13, color: Colors.grey[500])),
            ]),
            const Spacer(),
            // مفتاح الألوان
            Row(children: [
              Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                      color: AppColors.getAccent(context),
                      borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 4),
              Text('مسموح',
                  style:
                      GoogleFonts.cairo(color: Colors.grey[500], fontSize: 10)),
              const SizedBox(width: 12),
              Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                      color: const Color(0xFF2D3748),
                      borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 4),
              Text('محظور',
                  style:
                      GoogleFonts.cairo(color: Colors.grey[500], fontSize: 10)),
            ]),
          ]),
          const SizedBox(height: 20),
          Container(
              decoration: BoxDecoration(
                  color: AppColors.getSurface(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2D3748))),
              child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor:
                        WidgetStateProperty.all(const Color(0xFF1E2127)),
                    headingRowHeight: 56,
                    dataRowMinHeight: 56,
                    dataRowMaxHeight: 60,
                    columnSpacing: 16,
                    columns: [
                      DataColumn(
                          label: SizedBox(
                              width: 170,
                              child: Text('المستخدم',
                                  style: GoogleFonts.cairo(
                                      color: AppColors.getAccent(context),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)))),
                      ..._pageLabels.entries.map((e) => DataColumn(
                          label: SizedBox(
                              width: 90,
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(_pageIcons[e.key],
                                        color: Colors.grey[400], size: 16),
                                    Text(e.value,
                                        style: GoogleFonts.cairo(
                                            color: Colors.grey[400],
                                            fontSize: 10),
                                        textAlign: TextAlign.center)
                                  ])))),
                      const DataColumn(
                          label: SizedBox(width: 50, child: SizedBox())),
                    ],
                    rows: activeUsers.map((u) {
                      final allowedCount =
                          u.permissions.values.where((v) => v).length;
                      return DataRow(cells: [
                        DataCell(Row(children: [
                          Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                  color: u.role.color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Icon(u.role.icon,
                                  color: u.role.color, size: 16)),
                          const SizedBox(width: 8),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(u.name.split(' ').take(2).join(' '),
                                    style: GoogleFonts.cairo(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                                Row(children: [
                                  Text(u.role.arabicName,
                                      style: GoogleFonts.cairo(
                                          color: u.role.color, fontSize: 10)),
                                  const SizedBox(width: 6),
                                  Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                          color:
                                              AppColors.getAccent(context).withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(6)),
                                      child: Text(
                                          '$allowedCount/${_pageLabels.length}',
                                          style: GoogleFonts.cairo(
                                              color: AppColors.getAccent(context),
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold))),
                                ]),
                              ]),
                        ])),
                        ..._pageLabels.keys.map((page) => DataCell(Center(
                            child: Transform.scale(
                                scale: 0.8,
                                child: Switch(
                                  value: u.permissions[page] ?? false,
                                  activeColor: AppColors.getAccent(context),
                                  inactiveTrackColor: const Color(0xFF2D3748),
                                  trackOutlineColor: WidgetStateProperty.all(
                                      Colors.transparent),
                                  onChanged: u.role == UserRole.admin ||
                                          page == 'dashboard'
                                      ? null
                                      : (val) => auth.updateUserPermission(
                                          u.id, page, val),
                                ))))),
                        // زر فتح ديالوج التفاصيل
                        DataCell(Center(
                            child: GestureDetector(
                                onTap: () => _permissionsDialog(auth, u),
                                child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                        color: const Color(0xFFFFA726)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(Icons.open_in_new,
                                        color: Color(0xFFFFA726), size: 14))))),
                      ]);
                    }).toList(),
                  ))),
          const SizedBox(height: 24),
          Text('قوالب الصلاحيات الافتراضية',
              style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 12),
          Row(
              children: UserRole.values
                  .map((r) => Expanded(
                      child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: r.color.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: r.color.withOpacity(0.2))),
                          child: Column(children: [
                            Icon(r.icon, color: r.color, size: 28),
                            const SizedBox(height: 8),
                            Text(r.arabicName,
                                style: GoogleFonts.cairo(
                                    color: r.color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(
                                '${AppUser.defaultPermsForRole(r).values.where((v) => v).length} / ${_pageLabels.length} صفحة',
                                style: GoogleFonts.cairo(
                                    color: Colors.grey[500], fontSize: 11))
                          ]))))
                  .toList()),
        ]));
  }

  // ===== تاب النظام =====
  Widget _systemTab(AuthService auth) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: _group('الحساب', [
              _profileCard(auth),
              const SizedBox(height: 12),
              _row('تغيير كلمة المرور', Icons.lock_outline, AppColors.getAccent(context),
                  trailing: const Icon(Icons.chevron_right,
                      color: Colors.grey, size: 20)),
              _row('المصادقة الثنائية', Icons.security, const Color(0xFF8B5CF6),
                  trailing: _sw(false, (_) {})),
            ])),
            const SizedBox(width: 20),
            Expanded(
                child: _group('التطبيق', [
              _row('الإشعارات', Icons.notifications_outlined, AppColors.getInfo(context),
                  trailing: _sw(_notif, (v) => setState(() => _notif = v))),
              _row('أصوات التنبيه', Icons.volume_up, AppColors.getWarning(context),
                  trailing: _sw(
                      _soundAlerts, (v) => setState(() => _soundAlerts = v))),
              Consumer<ThemeProvider>(
                builder: (context, theme, _) => _row(
                  'الوضع الداكن',
                  Icons.dark_mode_outlined,
                  AppColors.getChartPurple(context),
                  trailing: _sw(theme.isDark, (v) {
                    theme.setDark(v);
                    setState(() {});
                  }),
                ),
              ),
              _row('اللغة', Icons.language, AppColors.getChartBlue(context),
                  trailing: _dd(_lang, ['العربية', 'English'],
                      (v) => setState(() => _lang = v!))),
            ])),
          ]),
          const SizedBox(height: 20),
          _group('سجل تسجيلات الدخول', [
            ...auth.loginHistory.reversed.take(5).map((r) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: const Color(0xFF252830),
                    borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  Icon(r.success ? Icons.login : Icons.error_outline,
                      color: r.success ? AppColors.getAccent(context) : AppColors.getError(context),
                      size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(r.userName,
                            style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        Text(r.email,
                            style: GoogleFonts.cairo(
                                color: Colors.grey[600], fontSize: 10)),
                      ])),
                  Text(_timeAgo(r.time),
                      style: GoogleFonts.cairo(
                          color: Colors.grey[500], fontSize: 10)),
                  const SizedBox(width: 10),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color:
                              (r.success ? AppColors.getAccent(context) : AppColors.getError(context))
                                  .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(r.success ? 'نجح' : 'فشل',
                          style: GoogleFonts.cairo(
                              color: r.success
                                  ? AppColors.getAccent(context)
                                  : AppColors.getError(context),
                              fontSize: 10,
                              fontWeight: FontWeight.bold))),
                ]))),
            if (auth.loginHistory.isEmpty)
              Center(
                  child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('لا توجد سجلات',
                          style: GoogleFonts.cairo(color: Colors.grey[600])))),
          ]),
        ]));
  }

  // ===== تاب النسخ الاحتياطي =====
  Widget _backupTab() {
    final db = DatabaseService();
    final stats = db.isInitialized ? db.stats : <String, int>{};
    final totalRecords = stats.values.fold(0, (a, b) => a + b);
    final backups = [
      {'date': '12/02/2026 - 08:30', 'size': '24.5 MB', 'ok': true},
      {'date': '11/02/2026 - 08:30', 'size': '23.8 MB', 'ok': true},
      {'date': '10/02/2026 - 08:30', 'size': '22.1 MB', 'ok': true},
      {'date': '09/02/2026 - 08:30', 'size': '21.9 MB', 'ok': false},
    ];
    return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          // إحصائيات قاعدة البيانات
          _group('قاعدة البيانات المحلية (Hive)', [
            Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFF252830),
                    borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  Row(children: [
                    Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                            color: AppColors.getAccent(context).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.storage,
                            color: AppColors.getAccent(context), size: 22)),
                    const SizedBox(width: 14),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'حالة القاعدة: ${db.isInitialized ? "متصلة ✅" : "غير متصلة ❌"}',
                              style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                          Text('إجمالي السجلات: $totalRecords',
                              style: GoogleFonts.cairo(
                                  color: Colors.grey[500], fontSize: 11)),
                        ]),
                  ]),
                  const SizedBox(height: 14),
                  Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: stats.entries
                          .map((e) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                    color: const Color(0xFF1A1F2E),
                                    borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('${e.value}',
                                          style: GoogleFonts.cairo(
                                              color: AppColors.getAccent(context),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14)),
                                      const SizedBox(width: 6),
                                      Text(e.key,
                                          style: GoogleFonts.cairo(
                                              color: Colors.grey[500],
                                              fontSize: 10)),
                                    ]),
                              ))
                          .toList()),
                ])),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: SizedBox(
                      height: 46,
                      child: ElevatedButton.icon(
                          onPressed: () => _snack(
                              'البيانات تُحفظ تلقائياً مع كل تغيير',
                              AppColors.getAccent(context)),
                          icon: const Icon(Icons.save, size: 18),
                          label: Text('حفظ يدوي',
                              style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.getAccent(context),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)))))),
              const SizedBox(width: 12),
              Expanded(
                  child: SizedBox(
                      height: 46,
                      child: ElevatedButton.icon(
                          onPressed: () => _confirmReset(db),
                          icon: const Icon(Icons.delete_forever, size: 18),
                          label: Text('إعادة ضبط',
                              style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.getError(context),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)))))),
            ]),
          ]),
          const SizedBox(height: 20),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                flex: 2,
                child: _group('إعدادات النسخ', [
                  _row('نسخ تلقائي', Icons.backup, AppColors.getAccent(context),
                      trailing: _sw(
                          _autoBackup, (v) => setState(() => _autoBackup = v))),
                  _row('التكرار', Icons.repeat, const Color(0xFF42A5F5),
                      trailing: _dd(_backupFreq, ['يومي', 'أسبوعي', 'شهري'],
                          (v) => setState(() => _backupFreq = v!))),
                  const SizedBox(height: 12),
                  SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                          onPressed: () => _snack(
                              'جاري النسخ الاحتياطي...', AppColors.getAccent(context)),
                          icon: const Icon(Icons.cloud_upload, size: 18),
                          label: Text('نسخ الآن',
                              style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.getAccent(context),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12))))),
                ])),
            const SizedBox(width: 20),
            Expanded(
                flex: 3,
                child: _group(
                    'السجل',
                    backups
                        .map((b) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: const Color(0xFF252830),
                                borderRadius: BorderRadius.circular(10)),
                            child: Row(children: [
                              Icon(
                                  b['ok'] as bool
                                      ? Icons.cloud_done
                                      : Icons.cloud_off,
                                  color: b['ok'] as bool
                                      ? AppColors.getAccent(context)
                                      : AppColors.getError(context),
                                  size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(b['date'] as String,
                                        style: GoogleFonts.cairo(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600)),
                                    Text('الحجم: ${b['size']}',
                                        style: GoogleFonts.cairo(
                                            color: Colors.grey[500],
                                            fontSize: 10)),
                                  ])),
                              Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                      color: (b['ok'] as bool
                                              ? AppColors.getAccent(context)
                                              : AppColors.getError(context))
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Text(b['ok'] as bool ? 'مكتمل' : 'فشل',
                                      style: GoogleFonts.cairo(
                                          color: b['ok'] as bool
                                              ? AppColors.getAccent(context)
                                              : AppColors.getError(context),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold))),
                            ])))
                        .toList())),
          ]),
        ]));
  }

  void _confirmReset(DatabaseService db) {
    showDialog(
        context: context,
        builder: (ctx) => Directionality(
            textDirection: ui.TextDirection.rtl,
            child: AlertDialog(
              backgroundColor: const Color(0xFF1A1F2E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(children: [
                Icon(Icons.warning_amber, color: AppColors.getError(context), size: 28),
                const SizedBox(width: 10),
                Text('إعادة ضبط المصنع',
                    style: GoogleFonts.cairo(
                        color: Colors.white, fontWeight: FontWeight.bold))
              ]),
              content: Text(
                  'سيتم مسح جميع البيانات المحلية بما في ذلك الأرصدة والسجلات والإشعارات. هل أنت متأكد؟',
                  style: GoogleFonts.cairo(color: Colors.grey[400])),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('إلغاء',
                        style: GoogleFonts.cairo(color: Colors.grey[500]))),
                ElevatedButton(
                    onPressed: () async {
                      await db.clearAll();
                      Navigator.pop(ctx);
                      _snack('تم مسح جميع البيانات - أعد تشغيل التطبيق',
                          AppColors.getError(context));
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.getError(context),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                    child: Text('مسح الكل',
                        style: GoogleFonts.cairo(color: Colors.white))),
              ],
            )));
  }

  // ===== تاب الترخيص =====
  Widget _licenseTab() {
    return FutureBuilder<LicenseInfo?>(
      future: LicenseService.loadSavedLicense(),
      builder: (context, snapshot) {
        final license = snapshot.data;
        if (license == null) {
          return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                    color: Colors.grey[800]!.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20)),
                child:
                    Icon(Icons.vpn_key_off, color: Colors.grey[600], size: 40)),
            const SizedBox(height: 20),
            Text('لا يوجد ترخيص مفعّل',
                style: GoogleFonts.cairo(
                    color: Colors.grey[400],
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ]));
        }

        final daysLeft = license.daysRemaining;
        final isExpiring = daysLeft <= 30 && daysLeft > 0;
        final isExpired = license.isExpired;
        final statusColor = isExpired
            ? const Color(0xFFEF5350)
            : isExpiring
                ? const Color(0xFFFFA726)
                : const Color(0xFF10B981);
        final statusText = isExpired
            ? 'منتهي'
            : isExpiring
                ? 'ينتهي قريباً'
                : 'نشط';
        final statusIcon = isExpired
            ? Icons.cancel
            : isExpiring
                ? Icons.warning_amber
                : Icons.verified;

        return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
                child: Container(
                    width: 650,
                    child: Column(children: [
                      // بطاقة الحالة
                      Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                statusColor.withOpacity(0.08),
                                statusColor.withOpacity(0.02)
                              ]),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: statusColor.withOpacity(0.3))),
                          child: Row(children: [
                            Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(18)),
                                child: Icon(statusIcon,
                                    color: statusColor, size: 36)),
                            const SizedBox(width: 20),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Row(children: [
                                    Text('حالة الترخيص',
                                        style: GoogleFonts.cairo(
                                            color: Colors.grey[500],
                                            fontSize: 12)),
                                    const SizedBox(width: 10),
                                    Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 3),
                                        decoration: BoxDecoration(
                                            color:
                                                statusColor.withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: Text(statusText,
                                            style: GoogleFonts.cairo(
                                                color: statusColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold))),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text(license.clientName,
                                      style: GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold)),
                                  Text(
                                      '${license.typeArabic} • ${isExpired ? "انتهى" : "$daysLeft يوم متبقي"}',
                                      style: GoogleFonts.cairo(
                                          color: Colors.grey[400],
                                          fontSize: 13)),
                                ])),
                            // شريط تقدم الأيام
                            if (!isExpired)
                              SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        SizedBox(
                                            width: 70,
                                            height: 70,
                                            child: CircularProgressIndicator(
                                                value: (daysLeft /
                                                        (license.type ==
                                                                LicenseType
                                                                    .trial
                                                            ? 30
                                                            : license.type ==
                                                                    LicenseType
                                                                        .annual
                                                                ? 365
                                                                : 36500))
                                                    .clamp(0.0, 1.0),
                                                backgroundColor:
                                                    Colors.grey[800],
                                                color: statusColor,
                                                strokeWidth: 6)),
                                        Text('$daysLeft',
                                            style: GoogleFonts.cairo(
                                                color: statusColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20)),
                                      ])),
                          ])),
                      const SizedBox(height: 20),

                      // تفاصيل الترخيص
                      _group('تفاصيل الترخيص', [
                        _licRow('رقم العميل', license.clientId, Icons.badge,
                            const Color(0xFF42A5F5)),
                        _licRow('نوع الترخيص', license.typeArabic,
                            Icons.card_membership, const Color(0xFF8B5CF6)),
                        _licRow(
                            'تاريخ الإصدار',
                            license.issueDate.toString().substring(0, 10),
                            Icons.calendar_today,
                            const Color(0xFF10B981)),
                        _licRow(
                            'تاريخ الانتهاء',
                            license.expiryDate.toString().substring(0, 10),
                            Icons.event_busy,
                            statusColor),
                        _licRow(
                            'الحد الأقصى للمحطات',
                            '${license.maxStations} محطة',
                            Icons.store,
                            const Color(0xFFFFA726)),
                        _licRow(
                            'الحد الأقصى للمستخدمين',
                            '${license.maxUsers} مستخدم',
                            Icons.people,
                            const Color(0xFF26A69A)),
                        _licRow('بصمة الجهاز', license.deviceHash,
                            Icons.fingerprint, Colors.grey),
                      ]),
                      const SizedBox(height: 16),

                      // أزرار الإجراءات
                      Row(children: [
                        if (isExpired || isExpiring)
                          Expanded(
                              child: SizedBox(
                                  height: 46,
                                  child: ElevatedButton.icon(
                                      onPressed: () => _snack(
                                          'تواصل مع الدعم لتجديد الترخيص',
                                          statusColor),
                                      icon: const Icon(Icons.refresh, size: 18),
                                      label: Text('تجديد الترخيص',
                                          style: GoogleFonts.cairo(
                                              fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: statusColor,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      12)))))),
                        if (isExpired || isExpiring) const SizedBox(width: 12),
                        Expanded(
                            child: SizedBox(
                                height: 46,
                                child: OutlinedButton.icon(
                                    onPressed: () async {
                                      await LicenseService.clearLicense();
                                      _snack(
                                          'تم إلغاء الترخيص - أعد تشغيل التطبيق',
                                          const Color(0xFFEF5350));
                                    },
                                    icon: Icon(Icons.delete_outline,
                                        size: 18, color: Colors.grey[500]),
                                    label: Text('إلغاء الترخيص',
                                        style: GoogleFonts.cairo(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[500])),
                                    style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                            color: Colors.grey[700]!),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)))))),
                      ]),
                    ]))));
      },
    );
  }

  Widget _licRow(String label, String value, IconData icon, Color color) =>
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 18)),
            const SizedBox(width: 14),
            Expanded(
                child: Text(label,
                    style: GoogleFonts.cairo(
                        color: Colors.grey[500], fontSize: 12))),
            SelectableText(value,
                style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ]));

  // ===== تاب حول =====
  Widget _aboutTab() {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
            child: Container(
          width: 600,
          padding: const EdgeInsets.all(36),
          decoration: BoxDecoration(
              color: AppColors.getSurface(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF2D3748))),
          child: Column(children: [
            Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF00D9A3), Color(0xFF00B4D8)]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.getAccent(context).withOpacity(0.3),
                          blurRadius: 20)
                    ]),
                child: const Icon(Icons.local_gas_station,
                    color: Colors.white, size: 40)),
            const SizedBox(height: 20),
            Text('وقود صحاري كربلاء',
                style: GoogleFonts.cairo(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            Text('Sahara Karbala Fuel Management',
                style:
                    GoogleFonts.cairo(fontSize: 13, color: Colors.grey[500])),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _chip('الإصدار', 'v2.0.0', AppColors.getAccent(context)),
              const SizedBox(width: 16),
              _chip('الترخيص', 'سنوي', const Color(0xFF8B5CF6)),
              const SizedBox(width: 16),
              _chip('المحطات', '7 / 10', const Color(0xFF42A5F5)),
            ]),
            const SizedBox(height: 24),
            Divider(color: Colors.grey[800]),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _info('المطور', 'Sahara Tech'),
              const SizedBox(width: 40),
              _info('الدعم', 'support@saharafuel.iq'),
              const SizedBox(width: 40),
              _info('الهاتف', '07XX-XXX-XXXX'),
            ]),
            const SizedBox(height: 20),
            Text('© 2026 جميع الحقوق محفوظة',
                style:
                    GoogleFonts.cairo(color: Colors.grey[700], fontSize: 11)),
          ]),
        )));
  }

  // ===== Dialogs =====
  // ===== ديالوج تخصيص صلاحيات المستخدم =====
  void _permissionsDialog(AuthService auth, AppUser u) {
    // نسخة من الصلاحيات للتعديل المحلي
    final perms = Map<String, bool>.from(u.permissions);
    final isAdmin = u.role == UserRole.admin;
    final allPages = _pageLabels.entries.toList();
    final allowedCount = () => perms.values.where((v) => v).length;

    showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, ss) => Directionality(
                  textDirection: ui.TextDirection.rtl,
                  child: Dialog(
                    backgroundColor: AppColors.getSurface(context),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    child: Container(
                        width: 520,
                        padding: const EdgeInsets.all(28),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          // هيدر
                          Row(children: [
                            Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                    color: u.role.color.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(14)),
                                child: Icon(Icons.vpn_key,
                                    color: u.role.color, size: 24)),
                            const SizedBox(width: 14),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text('صلاحيات التبويبات',
                                      style: GoogleFonts.cairo(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                                  Row(children: [
                                    Text(u.name,
                                        style: GoogleFonts.cairo(
                                            fontSize: 13,
                                            color: u.role.color,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                            color:
                                                u.role.color.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(6)),
                                        child: Text(u.role.arabicName,
                                            style: GoogleFonts.cairo(
                                                fontSize: 10,
                                                color: u.role.color))),
                                  ]),
                                ])),
                            // شارة العدد
                            Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                    color: AppColors.getAccent(context).withOpacity(0.1),
                                    shape: BoxShape.circle),
                                child: Text('${allowedCount()}',
                                    style: GoogleFonts.cairo(
                                        color: AppColors.getAccent(context),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16))),
                          ]),
                          const SizedBox(height: 8),

                          if (isAdmin)
                            Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFFFA726)
                                        .withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: const Color(0xFFFFA726)
                                            .withOpacity(0.2))),
                                child: Row(children: [
                                  const Icon(Icons.info_outline,
                                      color: Color(0xFFFFA726), size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                      'المدير يملك صلاحية الوصول لجميع الصفحات',
                                      style: GoogleFonts.cairo(
                                          color: const Color(0xFFFFA726),
                                          fontSize: 11))
                                ])),

                          const SizedBox(height: 16),

                          // أزرار سريعة
                          if (!isAdmin)
                            Row(children: [
                              _quickBtn(
                                  'تحديد الكل',
                                  Icons.select_all,
                                  AppColors.getAccent(context),
                                  () => ss(() {
                                        for (var k in perms.keys)
                                          perms[k] = true;
                                      })),
                              const SizedBox(width: 8),
                              _quickBtn(
                                  'إلغاء الكل',
                                  Icons.deselect,
                                  const Color(0xFFEF5350),
                                  () => ss(() {
                                        for (var k in perms.keys) {
                                          if (k != 'dashboard')
                                            perms[k] = false;
                                        }
                                      })),
                              const SizedBox(width: 8),
                              _quickBtn(
                                  'استعادة الافتراضي',
                                  Icons.restore,
                                  const Color(0xFF42A5F5),
                                  () => ss(() {
                                        final def =
                                            AppUser.defaultPermsForRole(u.role);
                                        for (var k in perms.keys)
                                          perms[k] = def[k] ?? false;
                                      })),
                            ]),
                          if (!isAdmin) const SizedBox(height: 16),

                          // قائمة الصفحات
                          Container(
                            constraints: const BoxConstraints(maxHeight: 380),
                            decoration: BoxDecoration(
                                color: const Color(0xFF1A1F2E),
                                borderRadius: BorderRadius.circular(14),
                                border:
                                    Border.all(color: const Color(0xFF2D3748))),
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.all(8),
                              itemCount: allPages.length,
                              separatorBuilder: (_, __) =>
                                  Divider(color: Colors.grey[800], height: 1),
                              itemBuilder: (_, i) {
                                final key = allPages[i].key;
                                final label = allPages[i].value;
                                final icon = _pageIcons[key] ?? Icons.circle;
                                final isOn = perms[key] ?? false;
                                final isDashboard = key == 'dashboard';

                                return ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 2),
                                  leading: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                          color: (isOn
                                                  ? AppColors.getAccent(context)
                                                  : Colors.grey[700]!)
                                              .withOpacity(isOn ? 0.15 : 0.1),
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      child: Icon(icon,
                                          color: isOn
                                              ? AppColors.getAccent(context)
                                              : Colors.grey[600],
                                          size: 20)),
                                  title: Text(label,
                                      style: GoogleFonts.cairo(
                                          color: isOn
                                              ? Colors.white
                                              : Colors.grey[500],
                                          fontSize: 13,
                                          fontWeight: isOn
                                              ? FontWeight.bold
                                              : FontWeight.normal)),
                                  subtitle: isDashboard
                                      ? Text('(إلزامي)',
                                          style: GoogleFonts.cairo(
                                              color: AppColors.getAccent(context),
                                              fontSize: 10))
                                      : null,
                                  trailing: Transform.scale(
                                      scale: 0.85,
                                      child: Switch(
                                        value: isOn,
                                        activeColor: AppColors.getAccent(context),
                                        inactiveTrackColor:
                                            const Color(0xFF2D3748),
                                        trackOutlineColor:
                                            WidgetStateProperty.all(
                                                Colors.transparent),
                                        onChanged: isAdmin || isDashboard
                                            ? null
                                            : (val) =>
                                                ss(() => perms[key] = val),
                                      )),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),

                          // أزرار الحفظ
                          Row(children: [
                            Expanded(
                                child: TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: Text('إلغاء',
                                        style: GoogleFonts.cairo(
                                            color: Colors.grey[400])))),
                            const SizedBox(width: 12),
                            Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  onPressed: isAdmin
                                      ? null
                                      : () {
                                          // حفظ الصلاحيات
                                          auth.updateUser(u.id,
                                              permissions: perms);
                                          Navigator.pop(ctx);
                                          _snack(
                                              'تم تحديث صلاحيات ${u.name} (${allowedCount()} صفحة)',
                                              AppColors.getAccent(context));
                                        },
                                  icon: const Icon(Icons.save, size: 18),
                                  label: Text(
                                      'حفظ الصلاحيات (${allowedCount()} / ${allPages.length})',
                                      style: GoogleFonts.cairo(
                                          fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.getAccent(context),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12))),
                                )),
                          ]),
                        ])),
                  ),
                )));
  }

  Widget _quickBtn(String label, IconData icon, Color c, VoidCallback onTap) =>
      Expanded(
          child: GestureDetector(
              onTap: onTap,
              child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                      color: c.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: c.withOpacity(0.2))),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, color: c, size: 14),
                        const SizedBox(width: 6),
                        Text(label,
                            style: GoogleFonts.cairo(
                                color: c,
                                fontSize: 10,
                                fontWeight: FontWeight.bold))
                      ]))));

  Widget _miniBtn(String label, Color c, VoidCallback onTap) => GestureDetector(
      onTap: onTap,
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: c.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: c.withOpacity(0.2))),
          child: Text(label,
              style: GoogleFonts.cairo(
                  color: c, fontSize: 9, fontWeight: FontWeight.bold))));

  void _addUserDialog(AuthService auth) {
    final nc = TextEditingController(),
        ec = TextEditingController(),
        pc = TextEditingController(),
        wc = TextEditingController();
    UserRole sr = UserRole.operator;
    Map<String, bool> perms =
        Map.from(AppUser.defaultPermsForRole(UserRole.operator));
    showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, ss) => Directionality(
                textDirection: ui.TextDirection.rtl,
                child: Dialog(
                    backgroundColor: AppColors.getSurface(context),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    child: Container(
                        width: 520,
                        padding: const EdgeInsets.all(28),
                        child: SingleChildScrollView(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                              Row(children: [
                                Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                        color:
                                            AppColors.getAccent(context).withOpacity(0.15),
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: Icon(Icons.person_add,
                                        color: AppColors.getAccent(context), size: 22)),
                                const SizedBox(width: 14),
                                Text('إضافة مستخدم جديد',
                                    style: GoogleFonts.cairo(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white))
                              ]),
                              const SizedBox(height: 24),
                              _df('الاسم الكامل', nc, Icons.person),
                              const SizedBox(height: 12),
                              _df('البريد', ec, Icons.email),
                              const SizedBox(height: 12),
                              _df('الهاتف', pc, Icons.phone),
                              const SizedBox(height: 12),
                              _df('كلمة المرور', wc, Icons.lock, obs: true),
                              const SizedBox(height: 16),
                              // اختيار الدور
                              Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFF252830),
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('الدور:',
                                            style: GoogleFonts.cairo(
                                                color: Colors.grey[400],
                                                fontSize: 12)),
                                        const SizedBox(height: 8),
                                        Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: UserRole.values
                                                .map((r) => GestureDetector(
                                                    onTap: () => ss(() {
                                                          sr = r;
                                                          perms = Map.from(AppUser
                                                              .defaultPermsForRole(
                                                                  r));
                                                        }),
                                                    child: Container(
                                                        padding: const EdgeInsets.symmetric(
                                                            horizontal: 14,
                                                            vertical: 6),
                                                        decoration: BoxDecoration(
                                                            color: sr == r
                                                                ? r.color
                                                                    .withOpacity(
                                                                        0.15)
                                                                : Colors
                                                                    .transparent,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                    10),
                                                            border: Border.all(
                                                                color: sr == r
                                                                    ? r.color
                                                                    : Colors.grey[
                                                                        700]!)),
                                                        child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Icon(r.icon,
                                                                  color: sr == r
                                                                      ? r.color
                                                                      : Colors.grey[
                                                                          500],
                                                                  size: 14),
                                                              const SizedBox(
                                                                  width: 6),
                                                              Text(r.arabicName,
                                                                  style: GoogleFonts.cairo(
                                                                      color: sr ==
                                                                              r
                                                                          ? r
                                                                              .color
                                                                          : Colors.grey[
                                                                              500],
                                                                      fontSize:
                                                                          12,
                                                                      fontWeight: sr ==
                                                                              r
                                                                          ? FontWeight
                                                                              .bold
                                                                          : FontWeight
                                                                              .normal))
                                                            ]))))
                                                .toList()),
                                      ])),
                              const SizedBox(height: 16),
                              // اختيار الصفحات المسموحة
                              Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFF252830),
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          Text('الصفحات المسموحة:',
                                              style: GoogleFonts.cairo(
                                                  color: Colors.grey[400],
                                                  fontSize: 12)),
                                          const Spacer(),
                                          Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                  color: AppColors.getAccent(context)
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8)),
                                              child: Text(
                                                  '${perms.values.where((v) => v).length} / ${perms.length}',
                                                  style: GoogleFonts.cairo(
                                                      color: AppColors.getAccent(context),
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold))),
                                        ]),
                                        const SizedBox(height: 10),
                                        if (sr != UserRole.admin)
                                          Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children:
                                                  _pageLabels.entries.map((e) {
                                                final isOn =
                                                    perms[e.key] ?? false;
                                                final isDashboard =
                                                    e.key == 'dashboard';
                                                return GestureDetector(
                                                    onTap: isDashboard
                                                        ? null
                                                        : () => ss(() =>
                                                            perms[e.key] =
                                                                !isOn),
                                                    child: Container(
                                                        padding: const EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 6),
                                                        decoration: BoxDecoration(
                                                            color: isOn
                                                                ? AppColors.getAccent(context)
                                                                    .withOpacity(
                                                                        0.15)
                                                                : Colors
                                                                    .transparent,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                    10),
                                                            border: Border.all(
                                                                color: isOn
                                                                    ? AppColors
                                                                        .accent
                                                                        .withOpacity(0.4)
                                                                    : Colors.grey[700]!)),
                                                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                                                          Icon(
                                                              _pageIcons[e.key],
                                                              color: isOn
                                                                  ? AppColors
                                                                      .accent
                                                                  : Colors.grey[
                                                                      600],
                                                              size: 14),
                                                          const SizedBox(
                                                              width: 6),
                                                          Text(e.value,
                                                              style: GoogleFonts.cairo(
                                                                  color: isOn
                                                                      ? AppColors
                                                                          .accent
                                                                      : Colors.grey[
                                                                          500],
                                                                  fontSize: 11,
                                                                  fontWeight: isOn
                                                                      ? FontWeight
                                                                          .bold
                                                                      : FontWeight
                                                                          .normal)),
                                                          if (isDashboard)
                                                            Text(' (إلزامي)',
                                                                style: GoogleFonts.cairo(
                                                                    color: Colors
                                                                            .grey[
                                                                        600],
                                                                    fontSize:
                                                                        9)),
                                                        ])));
                                              }).toList()),
                                        if (sr == UserRole.admin)
                                          Text(
                                              'المدير يملك جميع الصلاحيات تلقائياً',
                                              style: GoogleFonts.cairo(
                                                  color:
                                                      const Color(0xFFFFA726),
                                                  fontSize: 11)),
                                      ])),
                              const SizedBox(height: 24),
                              Row(children: [
                                Expanded(
                                    child: TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: Text('إلغاء',
                                            style: GoogleFonts.cairo(
                                                color: Colors.grey[400])))),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: ElevatedButton(
                                        onPressed: () {
                                          if (nc.text.isNotEmpty &&
                                              ec.text.isNotEmpty &&
                                              wc.text.isNotEmpty) {
                                            // ضمان أن لوحة التحكم دائماً مفعّلة
                                            perms['dashboard'] = true;
                                            auth.addUser(
                                                AppUser(
                                                    id: DateTime.now()
                                                        .millisecondsSinceEpoch
                                                        .toString(),
                                                    name: nc.text,
                                                    email: ec.text,
                                                    phone: pc.text,
                                                    role: sr,
                                                    createdAt: DateTime.now(),
                                                    permissions:
                                                        sr == UserRole.admin
                                                            ? null
                                                            : perms),
                                                wc.text);
                                            Navigator.pop(ctx);
                                            _snack(
                                                'تم إضافة ${nc.text} (${perms.values.where((v) => v).length} صفحة)',
                                                AppColors.getAccent(context));
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.getAccent(context),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 14),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12))),
                                        child: Text('إضافة',
                                            style: GoogleFonts.cairo(
                                                fontWeight: FontWeight.bold)))),
                              ]),
                            ])))))));
  }

  void _editUserDialog(AuthService auth, AppUser u) {
    final nc = TextEditingController(text: u.name),
        ec = TextEditingController(text: u.email),
        pc = TextEditingController(text: u.phone);
    UserRole sr = u.role;
    Map<String, bool> perms = Map.from(u.permissions);
    showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, ss) => Directionality(
                textDirection: ui.TextDirection.rtl,
                child: Dialog(
                    backgroundColor: AppColors.getSurface(context),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    child: Container(
                        width: 520,
                        padding: const EdgeInsets.all(28),
                        child: SingleChildScrollView(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                              Row(children: [
                                Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                        color: u.role.color.withOpacity(0.15),
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: Icon(Icons.edit,
                                        color: u.role.color, size: 22)),
                                const SizedBox(width: 14),
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('تعديل المستخدم',
                                          style: GoogleFonts.cairo(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white)),
                                      Text(u.email,
                                          style: GoogleFonts.cairo(
                                              fontSize: 11,
                                              color: Colors.grey[600])),
                                    ]),
                              ]),
                              const SizedBox(height: 24),
                              _df('الاسم', nc, Icons.person),
                              const SizedBox(height: 12),
                              _df('البريد', ec, Icons.email),
                              const SizedBox(height: 12),
                              _df('الهاتف', pc, Icons.phone),
                              const SizedBox(height: 16),
                              // اختيار الدور
                              Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFF252830),
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('الدور:',
                                            style: GoogleFonts.cairo(
                                                color: Colors.grey[400],
                                                fontSize: 12)),
                                        const SizedBox(height: 8),
                                        Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: UserRole.values
                                                .map((r) => GestureDetector(
                                                    onTap: () => ss(() {
                                                          sr = r;
                                                          if (r != u.role)
                                                            perms = Map.from(AppUser
                                                                .defaultPermsForRole(
                                                                    r));
                                                        }),
                                                    child: Container(
                                                        padding: const EdgeInsets.symmetric(
                                                            horizontal: 14,
                                                            vertical: 6),
                                                        decoration: BoxDecoration(
                                                            color: sr == r
                                                                ? r.color
                                                                    .withOpacity(
                                                                        0.15)
                                                                : Colors
                                                                    .transparent,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                    10),
                                                            border: Border.all(
                                                                color: sr == r
                                                                    ? r.color
                                                                    : Colors.grey[
                                                                        700]!)),
                                                        child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Icon(r.icon,
                                                                  color: sr == r
                                                                      ? r.color
                                                                      : Colors.grey[
                                                                          500],
                                                                  size: 14),
                                                              const SizedBox(
                                                                  width: 6),
                                                              Text(r.arabicName,
                                                                  style: GoogleFonts.cairo(
                                                                      color: sr ==
                                                                              r
                                                                          ? r
                                                                              .color
                                                                          : Colors.grey[
                                                                              500],
                                                                      fontSize:
                                                                          12,
                                                                      fontWeight: sr ==
                                                                              r
                                                                          ? FontWeight
                                                                              .bold
                                                                          : FontWeight
                                                                              .normal))
                                                            ]))))
                                                .toList()),
                                      ])),
                              const SizedBox(height: 16),
                              // تخصيص الصفحات
                              Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFF252830),
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          Icon(Icons.vpn_key,
                                              color: const Color(0xFFFFA726),
                                              size: 16),
                                          const SizedBox(width: 8),
                                          Text('الصفحات المسموحة:',
                                              style: GoogleFonts.cairo(
                                                  color: Colors.grey[400],
                                                  fontSize: 12)),
                                          const Spacer(),
                                          Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                  color: AppColors.getAccent(context)
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8)),
                                              child: Text(
                                                  '${perms.values.where((v) => v).length} / ${perms.length}',
                                                  style: GoogleFonts.cairo(
                                                      color: AppColors.getAccent(context),
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold))),
                                        ]),
                                        const SizedBox(height: 10),
                                        if (sr != UserRole.admin) ...[
                                          // أزرار سريعة
                                          Row(children: [
                                            _miniBtn(
                                                'الكل',
                                                AppColors.getAccent(context),
                                                () => ss(() {
                                                      for (var k in perms.keys)
                                                        perms[k] = true;
                                                    })),
                                            const SizedBox(width: 6),
                                            _miniBtn(
                                                'لا شيء',
                                                const Color(0xFFEF5350),
                                                () => ss(() {
                                                      for (var k
                                                          in perms.keys) {
                                                        if (k != 'dashboard')
                                                          perms[k] = false;
                                                      }
                                                    })),
                                            const SizedBox(width: 6),
                                            _miniBtn(
                                                'افتراضي',
                                                const Color(0xFF42A5F5),
                                                () => ss(() {
                                                      perms = Map.from(AppUser
                                                          .defaultPermsForRole(
                                                              sr));
                                                    })),
                                          ]),
                                          const SizedBox(height: 10),
                                          Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children:
                                                  _pageLabels.entries.map((e) {
                                                final isOn =
                                                    perms[e.key] ?? false;
                                                final isDashboard =
                                                    e.key == 'dashboard';
                                                return GestureDetector(
                                                    onTap: isDashboard
                                                        ? null
                                                        : () => ss(() =>
                                                            perms[e.key] =
                                                                !isOn),
                                                    child: AnimatedContainer(
                                                        duration: const Duration(
                                                            milliseconds: 200),
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                                horizontal: 12,
                                                                vertical: 6),
                                                        decoration: BoxDecoration(
                                                            color: isOn
                                                                ? AppColors.getAccent(context)
                                                                    .withOpacity(
                                                                        0.15)
                                                                : Colors
                                                                    .transparent,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                    10),
                                                            border: Border.all(
                                                                color: isOn
                                                                    ? AppColors.getAccent(context).withOpacity(0.4)
                                                                    : Colors.grey[700]!)),
                                                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                                                          Icon(
                                                              _pageIcons[e.key],
                                                              color: isOn
                                                                  ? AppColors
                                                                      .accent
                                                                  : Colors.grey[
                                                                      600],
                                                              size: 14),
                                                          const SizedBox(
                                                              width: 6),
                                                          Text(e.value,
                                                              style: GoogleFonts.cairo(
                                                                  color: isOn
                                                                      ? AppColors
                                                                          .accent
                                                                      : Colors.grey[
                                                                          500],
                                                                  fontSize: 11,
                                                                  fontWeight: isOn
                                                                      ? FontWeight
                                                                          .bold
                                                                      : FontWeight
                                                                          .normal)),
                                                          if (isDashboard)
                                                            Text(' (إلزامي)',
                                                                style: GoogleFonts.cairo(
                                                                    color: Colors
                                                                            .grey[
                                                                        600],
                                                                    fontSize:
                                                                        9)),
                                                        ])));
                                              }).toList()),
                                        ],
                                        if (sr == UserRole.admin)
                                          Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 4),
                                              child: Text(
                                                  'المدير يملك جميع الصلاحيات تلقائياً',
                                                  style: GoogleFonts.cairo(
                                                      color: const Color(
                                                          0xFFFFA726),
                                                      fontSize: 11))),
                                      ])),
                              const SizedBox(height: 24),
                              Row(children: [
                                Expanded(
                                    child: TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: Text('إلغاء',
                                            style: GoogleFonts.cairo(
                                                color: Colors.grey[400])))),
                                const SizedBox(width: 12),
                                Expanded(
                                    flex: 2,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        perms['dashboard'] = true;
                                        auth.updateUser(u.id,
                                            name: nc.text,
                                            email: ec.text,
                                            phone: pc.text,
                                            role: sr,
                                            permissions: sr == UserRole.admin
                                                ? null
                                                : perms);
                                        Navigator.pop(ctx);
                                        _snack(
                                            'تم تحديث ${nc.text} (${perms.values.where((v) => v).length} صفحة)',
                                            AppColors.getAccent(context));
                                      },
                                      icon: const Icon(Icons.save, size: 18),
                                      label: Text('حفظ التعديلات',
                                          style: GoogleFonts.cairo(
                                              fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.getAccent(context),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12))),
                                    )),
                              ]),
                            ])))))));
  }

  // ===== Widgets =====
  Widget _badge(String t, IconData i, Color c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
          color: c.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.withOpacity(0.3))),
      child: Row(children: [
        Icon(i, color: c, size: 16),
        const SizedBox(width: 8),
        Text(t,
            style: GoogleFonts.cairo(
                color: c, fontSize: 12, fontWeight: FontWeight.bold))
      ]));
  Widget _stat(String l, String v, Color c, IconData i) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
          color: c.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.withOpacity(0.15))),
      child: Row(children: [
        Icon(i, color: c, size: 18),
        const SizedBox(width: 8),
        Text(v,
            style: GoogleFonts.cairo(
                color: c, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(width: 6),
        Text(l, style: GoogleFonts.cairo(color: Colors.grey[500], fontSize: 11))
      ]));
  Widget _th(String t, int f) => Expanded(
      flex: f,
      child: Text(t,
          style: GoogleFonts.cairo(
              color: AppColors.getAccent(context),
              fontWeight: FontWeight.bold,
              fontSize: 12),
          textAlign: TextAlign.center));
  Widget _iconBtn(IconData i, Color c, VoidCallback f) => GestureDetector(
      onTap: f,
      child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
              color: c.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(i, color: c, size: 15)));
  Widget _group(String t, List<Widget> ch) => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2D3748))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t,
            style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.getAccent(context))),
        const SizedBox(height: 16),
        ...ch
      ]));
  Widget _row(String t, IconData i, Color c,
          {String? sub, Widget? trailing, bool isDanger = false}) =>
      Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: const Color(0xFF252830),
              borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: c.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(i, color: c, size: 18)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(t,
                      style: GoogleFonts.cairo(
                          color: isDanger ? AppColors.getError(context) : Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  if (sub != null)
                    Text(sub,
                        style: GoogleFonts.cairo(
                            color: Colors.grey[600], fontSize: 10))
                ])),
            if (trailing != null) trailing
          ]));
  Widget _sw(bool v, ValueChanged<bool> f) => Switch(
      value: v,
      onChanged: f,
      activeColor: AppColors.getAccent(context),
      inactiveTrackColor: const Color(0xFF2D3748),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent));
  Widget _dd(String v, List<String> items, ValueChanged<String?> f) =>
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          height: 34,
          decoration: BoxDecoration(
              color: const Color(0xFF252830),
              borderRadius: BorderRadius.circular(8)),
          child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                  value: v,
                  dropdownColor: const Color(0xFF252830),
                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 12),
                  items: items
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: f)));
  Widget _profileCard(AuthService auth) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFF252830),
          borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  auth.role.color,
                  auth.role.color.withOpacity(0.6)
                ]),
                borderRadius: BorderRadius.circular(14)),
            child: Icon(auth.role.icon, color: Colors.white, size: 28)),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(auth.userName,
              style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          Text(auth.userEmail,
              style: GoogleFonts.cairo(color: Colors.grey[500], fontSize: 12)),
          Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: auth.role.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6)),
              child: Text(auth.userRole,
                  style: GoogleFonts.cairo(
                      color: auth.role.color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)))
        ])
      ]));
  Widget _df(String l, TextEditingController c, IconData i,
          {bool obs = false}) =>
      TextField(
          controller: c,
          obscureText: obs,
          style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
              labelText: l,
              labelStyle:
                  GoogleFonts.cairo(color: Colors.grey[600], fontSize: 13),
              prefixIcon: Icon(i, color: AppColors.getAccent(context), size: 20),
              filled: true,
              fillColor: const Color(0xFF252830),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.getAccent(context)))));
  Widget _chip(String l, String v, Color c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
          color: c.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.withOpacity(0.3))),
      child: Column(children: [
        Text(v,
            style: GoogleFonts.cairo(
                color: c, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(l, style: GoogleFonts.cairo(color: Colors.grey[500], fontSize: 11))
      ]));
  Widget _info(String l, String v) => Column(children: [
        Text(l,
            style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 11)),
        Text(v,
            style: GoogleFonts.cairo(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))
      ]);
  void _snack(String m, Color c) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(m, style: GoogleFonts.cairo()),
          backgroundColor: c,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
  String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return 'منذ ${d.inMinutes} دقيقة';
    if (d.inHours < 24) return 'منذ ${d.inHours} ساعة';
    return 'منذ ${d.inDays} يوم';
  }

  // ===== Phase 7: تاب إعدادات التنبيهات الذكية =====
  Widget _smartAlertsTab() {
    final alert = SmartAlertService();
    return StatefulBuilder(
        builder: (ctx, ss) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              // ملخص التنبيهات
              Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        const Color(0xFFFFA726).withOpacity(0.08),
                        const Color(0xFFFFA726).withOpacity(0.02)
                      ]),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFFFFA726).withOpacity(0.2))),
                  child: Row(children: [
                    Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                            color: const Color(0xFFFFA726).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.notifications_active,
                            color: Color(0xFFFFA726), size: 28)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('التنبيهات الذكية',
                              style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18)),
                          Text(
                              '${alert.activeCount} تنبيه نشط • ${alert.criticalCount} حرج',
                              style: GoogleFonts.cairo(
                                  color: const Color(0xFFFFA726),
                                  fontSize: 12)),
                          Text(
                              '${alert.rules.where((r) => r.enabled).length} من ${alert.rules.length} قاعدة مفعّلة',
                              style: GoogleFonts.cairo(
                                  color: Colors.grey[500], fontSize: 11)),
                        ])),
                    Column(children: [
                      Row(children: [
                        Icon(Icons.volume_up,
                            color: alert.soundEnabled
                                ? const Color(0xFF10B981)
                                : Colors.grey[700],
                            size: 16),
                        Switch(
                            value: alert.soundEnabled,
                            onChanged: (v) {
                              alert.toggleSound(v);
                              ss(() {});
                            },
                            activeColor: const Color(0xFF10B981),
                            inactiveTrackColor: const Color(0xFF2D3748),
                            trackOutlineColor:
                                WidgetStateProperty.all(Colors.transparent)),
                      ]),
                      Row(children: [
                        Icon(Icons.notifications,
                            color: alert.popupEnabled
                                ? const Color(0xFF42A5F5)
                                : Colors.grey[700],
                            size: 16),
                        Switch(
                            value: alert.popupEnabled,
                            onChanged: (v) {
                              alert.togglePopup(v);
                              ss(() {});
                            },
                            activeColor: const Color(0xFF42A5F5),
                            inactiveTrackColor: const Color(0xFF2D3748),
                            trackOutlineColor:
                                WidgetStateProperty.all(Colors.transparent)),
                      ]),
                    ]),
                  ])),
              const SizedBox(height: 20),

              // قواعد التنبيه
              Container(
                decoration: BoxDecoration(
                    color: AppColors.getSurface(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2D3748))),
                child: Column(children: [
                  Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: Color(0xFF1E2127),
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(16))),
                      child: Row(children: [
                        const Icon(Icons.rule,
                            color: Color(0xFFFFA726), size: 18),
                        const SizedBox(width: 8),
                        Text('قواعد التنبيه',
                            style: GoogleFonts.cairo(
                                color: const Color(0xFFFFA726),
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        const Spacer(),
                        Text('${alert.rules.length} قاعدة',
                            style: GoogleFonts.cairo(
                                color: Colors.grey[500], fontSize: 11)),
                      ])),
                  ...alert.rules.map((rule) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(
                                  color: Colors.grey[800]!, width: 0.5))),
                      child: Row(children: [
                        Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                                color: rule.priority == AlertPriority.critical
                                    ? const Color(0xFFEF5350).withOpacity(0.12)
                                    : rule.priority == AlertPriority.high
                                        ? const Color(0xFFFFA726)
                                            .withOpacity(0.12)
                                        : const Color(0xFF42A5F5)
                                            .withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10)),
                            child: Icon(
                                rule.category == AlertCategory.tank
                                    ? Icons.propane_tank
                                    : rule.category == AlertCategory.license
                                        ? Icons.vpn_key
                                        : rule.category ==
                                                AlertCategory.consumption
                                            ? Icons.speed
                                            : rule.category ==
                                                    AlertCategory.station
                                                ? Icons.store
                                                : Icons.build,
                                color: rule.priority == AlertPriority.critical
                                    ? const Color(0xFFEF5350)
                                    : rule.priority == AlertPriority.high
                                        ? const Color(0xFFFFA726)
                                        : const Color(0xFF42A5F5),
                                size: 18)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(rule.name,
                                  style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12)),
                              Text(rule.description,
                                  style: GoogleFonts.cairo(
                                      color: Colors.grey[600], fontSize: 10)),
                            ])),
                        if (rule.threshold != null)
                          Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                  color: const Color(0xFF252830),
                                  borderRadius: BorderRadius.circular(6)),
                              child: Text(
                                  '${rule.threshold!.toStringAsFixed(0)}${rule.category == AlertCategory.tank && rule.id.contains('temp') ? "°C" : rule.category == AlertCategory.license ? " يوم" : "%"}',
                                  style: GoogleFonts.cairo(
                                      color: Colors.grey[400], fontSize: 10))),
                        Switch(
                            value: rule.enabled,
                            onChanged: (v) {
                              alert.toggleRule(rule.id, v);
                              ss(() {});
                            },
                            activeColor: const Color(0xFF10B981),
                            inactiveTrackColor: const Color(0xFF2D3748),
                            trackOutlineColor:
                                WidgetStateProperty.all(Colors.transparent)),
                      ]))),
                ]),
              ),
              const SizedBox(height: 20),

              // التنبيهات النشطة
              if (alert.activeAlerts.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                      color: AppColors.getSurface(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2D3748))),
                  child: Column(children: [
                    Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: Color(0xFF1E2127),
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16))),
                        child: Row(children: [
                          const Icon(Icons.warning_amber,
                              color: Color(0xFFEF5350), size: 18),
                          const SizedBox(width: 8),
                          Text('تنبيهات نشطة',
                              style: GoogleFonts.cairo(
                                  color: const Color(0xFFEF5350),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                          const Spacer(),
                          GestureDetector(
                              onTap: () {
                                alert.dismissAll();
                                ss(() {});
                              },
                              child: Text('إخفاء الكل',
                                  style: GoogleFonts.cairo(
                                      color: Colors.grey[500], fontSize: 11))),
                        ])),
                    ...alert.activeAlerts.take(10).map((a) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                            border: Border(
                                bottom: BorderSide(
                                    color: Colors.grey[800]!, width: 0.5))),
                        child: Row(children: [
                          Icon(a.icon, color: a.color, size: 16),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(a.title,
                                    style: GoogleFonts.cairo(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600)),
                                Text(a.message,
                                    style: GoogleFonts.cairo(
                                        color: Colors.grey[600], fontSize: 9),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ])),
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                  color: a.color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4)),
                              child: Text(a.priorityText,
                                  style: GoogleFonts.cairo(
                                      color: a.color, fontSize: 8))),
                          const SizedBox(width: 6),
                          GestureDetector(
                              onTap: () {
                                alert.dismissAlert(a.id);
                                ss(() {});
                              },
                              child: Icon(Icons.close,
                                  color: Colors.grey[600], size: 14)),
                        ]))),
                  ]),
                ),
            ])));
  }
}
