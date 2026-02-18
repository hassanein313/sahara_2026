import 'package:flutter/material.dart';
import 'dart:async';
import '../providers/fuel_provider.dart';
import '../services/license_service.dart';

/// Phase 7 - أنواع التنبيهات الذكية
enum AlertPriority { critical, high, medium, low, info }
enum AlertCategory { tank, license, consumption, station, system, maintenance }

/// قاعدة تنبيه ذكي
class AlertRule {
  final String id, name, description;
  final AlertCategory category;
  final AlertPriority priority;
  final bool enabled;
  final double? threshold; // نسبة أو قيمة
  final int cooldownMinutes; // عدم إعادة التنبيه خلال هذه الفترة

  const AlertRule({
    required this.id, required this.name, required this.description,
    required this.category, required this.priority,
    this.enabled = true, this.threshold, this.cooldownMinutes = 60,
  });

  AlertRule copyWith({bool? enabled, double? threshold}) => AlertRule(
    id: id, name: name, description: description, category: category,
    priority: priority, enabled: enabled ?? this.enabled,
    threshold: threshold ?? this.threshold, cooldownMinutes: cooldownMinutes,
  );
}

/// تنبيه ذكي مُولَّد
class SmartAlert {
  final String id, ruleId, title, message;
  final AlertPriority priority;
  final AlertCategory category;
  final DateTime time;
  bool dismissed;
  bool actioned;

  SmartAlert({
    required this.id, required this.ruleId, required this.title,
    required this.message, required this.priority, required this.category,
    required this.time, this.dismissed = false, this.actioned = false,
  });

  Color get color => switch (priority) {
    AlertPriority.critical => const Color(0xFFEF5350),
    AlertPriority.high => const Color(0xFFFFA726),
    AlertPriority.medium => const Color(0xFF42A5F5),
    AlertPriority.low => const Color(0xFF10B981),
    AlertPriority.info => const Color(0xFF8B5CF6),
  };

  IconData get icon => switch (priority) {
    AlertPriority.critical => Icons.error,
    AlertPriority.high => Icons.warning_amber,
    AlertPriority.medium => Icons.info,
    AlertPriority.low => Icons.check_circle,
    AlertPriority.info => Icons.lightbulb,
  };

  String get priorityText => switch (priority) {
    AlertPriority.critical => 'حرج',
    AlertPriority.high => 'عالي',
    AlertPriority.medium => 'متوسط',
    AlertPriority.low => 'منخفض',
    AlertPriority.info => 'معلومة',
  };

  String get categoryText => switch (category) {
    AlertCategory.tank => 'الخزانات',
    AlertCategory.license => 'الترخيص',
    AlertCategory.consumption => 'الاستهلاك',
    AlertCategory.station => 'المحطات',
    AlertCategory.system => 'النظام',
    AlertCategory.maintenance => 'الصيانة',
  };
}

/// خدمة التنبيهات الذكية
class SmartAlertService extends ChangeNotifier {
  static final SmartAlertService _i = SmartAlertService._();
  factory SmartAlertService() => _i;
  SmartAlertService._();

  Timer? _checkTimer;
  final Map<String, DateTime> _lastFired = {};
  final List<SmartAlert> _alerts = [];
  bool _soundEnabled = true;
  bool _popupEnabled = true;

  // قواعد التنبيه الافتراضية
  List<AlertRule> _rules = [
    const AlertRule(id: 'tank_critical', name: 'خزان حرج', description: 'تنبيه عندما ينخفض مستوى خزان تحت النسبة المحددة', category: AlertCategory.tank, priority: AlertPriority.critical, threshold: 15, cooldownMinutes: 30),
    const AlertRule(id: 'tank_low', name: 'خزان منخفض', description: 'تنبيه عندما ينخفض مستوى خزان تحت 25%', category: AlertCategory.tank, priority: AlertPriority.high, threshold: 25, cooldownMinutes: 60),
    const AlertRule(id: 'tank_temp', name: 'حرارة خزان', description: 'تنبيه عند ارتفاع درجة حرارة الخزان فوق الحد', category: AlertCategory.tank, priority: AlertPriority.high, threshold: 30, cooldownMinutes: 120),
    const AlertRule(id: 'license_expiry', name: 'انتهاء الترخيص', description: 'تنبيه قبل انتهاء الترخيص بعدد الأيام المحدد', category: AlertCategory.license, priority: AlertPriority.critical, threshold: 7, cooldownMinutes: 1440),
    const AlertRule(id: 'license_trial', name: 'الفترة التجريبية', description: 'تنبيه بخصوص الفترة التجريبية', category: AlertCategory.license, priority: AlertPriority.medium, threshold: 15, cooldownMinutes: 1440),
    const AlertRule(id: 'consumption_spike', name: 'ارتفاع استهلاك', description: 'تنبيه عند ارتفاع الاستهلاك اليومي فوق المعدل بنسبة', category: AlertCategory.consumption, priority: AlertPriority.medium, threshold: 30, cooldownMinutes: 240),
    const AlertRule(id: 'consumption_target', name: 'تجاوز الهدف', description: 'تنبيه عند اقتراب محطة من تجاوز الهدف الشهري', category: AlertCategory.station, priority: AlertPriority.high, threshold: 90, cooldownMinutes: 720),
    const AlertRule(id: 'station_offline', name: 'محطة متوقفة', description: 'تنبيه عند توقف محطة عن الإبلاغ', category: AlertCategory.station, priority: AlertPriority.critical, cooldownMinutes: 60),
    const AlertRule(id: 'maintenance_due', name: 'صيانة مستحقة', description: 'تنبيه عند اقتراب موعد صيانة خزان', category: AlertCategory.maintenance, priority: AlertPriority.medium, threshold: 3, cooldownMinutes: 1440),
    const AlertRule(id: 'coverage_days', name: 'أيام التغطية', description: 'تنبيه عندما تقل أيام التغطية المتاحة', category: AlertCategory.consumption, priority: AlertPriority.high, threshold: 5, cooldownMinutes: 720),
  ];

  // Getters
  List<SmartAlert> get alerts => List.unmodifiable(_alerts);
  List<SmartAlert> get activeAlerts => _alerts.where((a) => !a.dismissed).toList();
  List<SmartAlert> get criticalAlerts => activeAlerts.where((a) => a.priority == AlertPriority.critical).toList();
  int get activeCount => activeAlerts.length;
  int get criticalCount => criticalAlerts.length;
  List<AlertRule> get rules => List.unmodifiable(_rules);
  bool get soundEnabled => _soundEnabled;
  bool get popupEnabled => _popupEnabled;

  /// بدء المراقبة
  void startMonitoring(FuelProvider provider) {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(minutes: 5), (_) => _runChecks(provider));
    // تشغيل فوري
    _runChecks(provider);
    debugPrint('🔔 نظام التنبيهات الذكية: بدأ المراقبة (${_rules.where((r) => r.enabled).length} قاعدة نشطة)');
  }

  /// إيقاف المراقبة
  void stopMonitoring() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  /// تشغيل جميع الفحوصات
  Future<void> _runChecks(FuelProvider prov) async {
    for (final rule in _rules.where((r) => r.enabled)) {
      if (_isInCooldown(rule.id)) continue;

      switch (rule.id) {
        case 'tank_critical': _checkTankLevels(prov, rule, critical: true);
        case 'tank_low': _checkTankLevels(prov, rule, critical: false);
        case 'tank_temp': _checkTankTemperatures(prov, rule);
        case 'license_expiry': await _checkLicenseExpiry(rule);
        case 'license_trial': await _checkLicenseTrial(rule);
        case 'consumption_spike': _checkConsumptionSpike(prov, rule);
        case 'consumption_target': _checkStationTargets(prov, rule);
        case 'coverage_days': _checkCoverageDays(prov, rule);
        default: break;
      }
    }
    notifyListeners();
  }

  // ===== فحوصات الخزانات =====
  void _checkTankLevels(FuelProvider prov, AlertRule rule, {required bool critical}) {
    for (final tank in prov.tanks) {
      final pct = tank.percentage;
      if (pct < (rule.threshold ?? 25)) {
        _fire(rule, '${critical ? "⛔" : "⚠️"} خزان ${tank.name}',
          'مستوى ${tank.name} وصل إلى ${pct.toStringAsFixed(0)}% (${FuelProvider.formatNumber(tank.current)} / ${FuelProvider.formatNumber(tank.capacity)} لتر) - ${tank.location}',
          suffix: tank.id);
      }
    }
  }

  void _checkTankTemperatures(FuelProvider prov, AlertRule rule) {
    for (final tank in prov.tanks) {
      if (tank.temperature > (rule.threshold ?? 30)) {
        _fire(rule, '🌡️ ارتفاع حرارة ${tank.name}',
          'درجة حرارة ${tank.name} وصلت ${tank.temperature}°C (الحد: ${rule.threshold?.toStringAsFixed(0) ?? "30"}°C)',
          suffix: 'temp_${tank.id}');
      }
    }
  }

  // ===== فحوصات الترخيص =====
  Future<void> _checkLicenseExpiry(AlertRule rule) async {
    final lic = await LicenseService.loadSavedLicense();
    if (lic == null) return;
    if (lic.daysRemaining <= (rule.threshold?.toInt() ?? 7)) {
      _fire(rule, '📋 الترخيص ينتهي قريباً!',
        'متبقي ${lic.daysRemaining} يوم على انتهاء الترخيص (${lic.typeArabic}). يرجى التجديد.');
    }
  }

  Future<void> _checkLicenseTrial(AlertRule rule) async {
    final lic = await LicenseService.loadSavedLicense();
    if (lic == null || lic.type != LicenseType.trial) return;
    if (lic.daysRemaining <= (rule.threshold?.toInt() ?? 15)) {
      _fire(rule, '🔑 الفترة التجريبية تنتهي',
        'متبقي ${lic.daysRemaining} يوم من الفترة التجريبية. الحد الأقصى: ${lic.maxStations} محطات و ${lic.maxUsers} مستخدمين.');
    }
  }

  // ===== فحوصات الاستهلاك =====
  void _checkConsumptionSpike(FuelProvider prov, AlertRule rule) {
    final avg = prov.averageDailyConsumption;
    if (avg <= 0) return;
    final today = prov.todayOutgoing;
    final spikePct = ((today - avg) / avg) * 100;
    if (spikePct > (rule.threshold ?? 30)) {
      _fire(rule, '📈 ارتفاع غير طبيعي في الاستهلاك',
        'الاستهلاك اليوم ${FuelProvider.formatNumber(today)} لتر أعلى بنسبة ${spikePct.toStringAsFixed(0)}% من المعدل (${FuelProvider.formatNumber(avg)} لتر)');
    }
  }

  void _checkStationTargets(FuelProvider prov, AlertRule rule) {
    for (final st in prov.stations) {
      if (st.monthlyTarget <= 0) continue;
      final projected = st.dailyConsumption * 30;
      final targetPct = (projected / st.monthlyTarget) * 100;
      if (targetPct > (rule.threshold ?? 90)) {
        _fire(rule, '🏭 ${st.name} تقترب من الحد',
          '${st.name} متوقع أن تستهلك ${targetPct.toStringAsFixed(0)}% من الهدف الشهري (${FuelProvider.formatNumber(projected)} / ${FuelProvider.formatNumber(st.monthlyTarget)} لتر)',
          suffix: st.id);
      }
    }
  }

  void _checkCoverageDays(FuelProvider prov, AlertRule rule) {
    if (prov.todayOutgoing <= 0) return;
    final stock = prov.totalCurrentStock;
    final days = stock / prov.todayOutgoing;
    if (days < (rule.threshold ?? 5)) {
      _fire(rule, '⏰ أيام التغطية منخفضة!',
        'المخزون الحالي يكفي ${days.toStringAsFixed(1)} يوم فقط بمعدل الاستهلاك الحالي. يُنصح بتعجيل الشحنات.');
    }
  }

  // ===== إدارة التنبيهات =====
  void _fire(AlertRule rule, String title, String message, {String suffix = ''}) {
    final key = '${rule.id}_$suffix';
    if (_isInCooldown(key)) return;

    _alerts.insert(0, SmartAlert(
      id: 'sa_${DateTime.now().millisecondsSinceEpoch}_${_alerts.length}',
      ruleId: rule.id, title: title, message: message,
      priority: rule.priority, category: rule.category, time: DateTime.now(),
    ));
    _lastFired[key] = DateTime.now();

    // حفظ آخر 100 تنبيه فقط
    if (_alerts.length > 100) _alerts.removeRange(100, _alerts.length);
  }

  bool _isInCooldown(String key) {
    final last = _lastFired[key];
    if (last == null) return false;
    final rule = _rules.firstWhere((r) => key.startsWith(r.id), orElse: () => _rules.first);
    return DateTime.now().difference(last).inMinutes < rule.cooldownMinutes;
  }

  void dismissAlert(String id) {
    final idx = _alerts.indexWhere((a) => a.id == id);
    if (idx != -1) { _alerts[idx].dismissed = true; notifyListeners(); }
  }

  void dismissAll() {
    for (var a in _alerts) a.dismissed = true;
    notifyListeners();
  }

  void clearDismissed() {
    _alerts.removeWhere((a) => a.dismissed);
    notifyListeners();
  }

  void toggleRule(String ruleId, bool enabled) {
    final idx = _rules.indexWhere((r) => r.id == ruleId);
    if (idx != -1) { _rules[idx] = _rules[idx].copyWith(enabled: enabled); notifyListeners(); }
  }

  void updateRuleThreshold(String ruleId, double threshold) {
    final idx = _rules.indexWhere((r) => r.id == ruleId);
    if (idx != -1) { _rules[idx] = _rules[idx].copyWith(threshold: threshold); notifyListeners(); }
  }

  void toggleSound(bool v) { _soundEnabled = v; notifyListeners(); }
  void togglePopup(bool v) { _popupEnabled = v; notifyListeners(); }

  @override
  void dispose() { stopMonitoring(); super.dispose(); }
}

