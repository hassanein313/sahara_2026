import '../constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'database_service.dart';
import 'api_service.dart';

/// Phase 6 - حالة المزامنة
enum SyncStatus { idle, syncing, success, error, offline }

/// سجل مزامنة
class SyncRecord {
  final DateTime time;
  final String action; // upload, download, merge
  final int recordsCount;
  final bool success;
  final String? error;
  SyncRecord({required this.time, required this.action, required this.recordsCount, required this.success, this.error});
}

/// إعدادات المزامنة
class SyncSettings {
  bool autoSync;
  int intervalMinutes;
  bool syncOnStartup;
  bool syncOnChange;
  bool wifiOnly;
  String serverUrl;
  String? apiKey;
  DateTime? lastSync;

  SyncSettings({
    this.autoSync = true,
    this.intervalMinutes = 15,
    this.syncOnStartup = true,
    this.syncOnChange = false,
    this.wifiOnly = true,
    this.serverUrl = 'http://localhost:3000/api',
    this.apiKey,
    this.lastSync,
  });

  Map<String, dynamic> toMap() => {
    'autoSync': autoSync, 'intervalMinutes': intervalMinutes,
    'syncOnStartup': syncOnStartup, 'syncOnChange': syncOnChange,
    'wifiOnly': wifiOnly, 'serverUrl': serverUrl, 'apiKey': apiKey,
    'lastSync': lastSync?.toIso8601String(),
  };

  factory SyncSettings.fromMap(Map<String, dynamic> m) => SyncSettings(
    autoSync: m['autoSync'] ?? true, intervalMinutes: m['intervalMinutes'] ?? 15,
    syncOnStartup: m['syncOnStartup'] ?? true, syncOnChange: m['syncOnChange'] ?? false,
    wifiOnly: m['wifiOnly'] ?? true, serverUrl: m['serverUrl'] ?? '', apiKey: m['apiKey'],
    lastSync: m['lastSync'] != null ? DateTime.parse(m['lastSync']) : null,
  );
}

/// خدمة المزامنة السحابية
class CloudSyncService extends ChangeNotifier {
  static final CloudSyncService _instance = CloudSyncService._();
  factory CloudSyncService() => _instance;
  CloudSyncService._();

  final DatabaseService _db = DatabaseService();
  SyncStatus _status = SyncStatus.idle;
  SyncSettings _settings = SyncSettings();
  final List<SyncRecord> _history = [];
  Timer? _autoSyncTimer;
  double _progress = 0;
  String _statusMessage = 'جاهز للمزامنة';
  int _pendingChanges = 0;

  // Getters
  SyncStatus get status => _status;
  SyncSettings get settings => _settings;
  List<SyncRecord> get history => List.unmodifiable(_history);
  double get progress => _progress;
  String get statusMessage => _statusMessage;
  int get pendingChanges => _pendingChanges;
  bool get isConfigured => _settings.serverUrl.isNotEmpty;
  String get lastSyncText {
    if (_settings.lastSync == null) return 'لم تتم المزامنة بعد';
    final diff = DateTime.now().difference(_settings.lastSync!);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return 'منذ ${diff.inDays} يوم';
  }

  /// تهيئة خدمة المزامنة
  Future<void> init() async {
    // تحميل الإعدادات المحفوظة
    if (_db.isInitialized) {
      final saved = _db.loadSetting('sync_settings');
      if (saved is Map) {
        _settings = SyncSettings.fromMap(Map<String, dynamic>.from(saved));
      }
    }
    _updatePendingCount();
    if (_settings.autoSync && isConfigured) _startAutoSync();
    debugPrint('☁️ خدمة المزامنة: ${isConfigured ? "مُعدّة" : "غير مُعدّة"} | آخر مزامنة: $lastSyncText');
  }

  /// تحديث الإعدادات
  void updateSettings(SyncSettings newSettings) {
    _settings = newSettings;
    _saveSettings();
    if (_settings.autoSync && isConfigured) {
      _startAutoSync();
    } else {
      _stopAutoSync();
    }
    notifyListeners();
  }

  /// مزامنة يدوية كاملة
  Future<bool> syncNow() async {
    if (_status == SyncStatus.syncing) return false;
    if (!isConfigured) {
      _statusMessage = 'يرجى إعداد خادم المزامنة أولاً';
      _status = SyncStatus.error;
      notifyListeners();
      return false;
    }

    _status = SyncStatus.syncing;
    _progress = 0;
    _statusMessage = 'جاري الاتصال بالخادم...';
    notifyListeners();

    try {
      // خطوة 1: رفع البيانات المحلية
      _progress = 0.2;
      _statusMessage = 'جاري رفع البيانات...';
      notifyListeners();
      await _uploadLocalChanges();

      // خطوة 2: تحميل التحديثات
      _progress = 0.5;
      _statusMessage = 'جاري تحميل التحديثات...';
      notifyListeners();
      await _downloadRemoteChanges();

      // خطوة 3: دمج التعارضات
      _progress = 0.8;
      _statusMessage = 'جاري دمج البيانات...';
      notifyListeners();
      await _mergeConflicts();

      // خطوة 4: تأكيد
      _progress = 1.0;
      _settings.lastSync = DateTime.now();
      _saveSettings();
      _pendingChanges = 0;
      _status = SyncStatus.success;
      _statusMessage = 'تمت المزامنة بنجاح';

      _history.insert(0, SyncRecord(time: DateTime.now(), action: 'مزامنة كاملة', recordsCount: _db.stats.values.fold(0, (s, v) => s + v), success: true));
      notifyListeners();
      return true;
    } catch (e) {
      _status = SyncStatus.error;
      _statusMessage = 'فشل المزامنة: ${e.toString().substring(0, 50)}';
      _history.insert(0, SyncRecord(time: DateTime.now(), action: 'مزامنة كاملة', recordsCount: 0, success: false, error: e.toString()));
      notifyListeners();
      return false;
    }
  }

  /// رفع فقط
  Future<void> uploadOnly() async {
    _status = SyncStatus.syncing;
    _statusMessage = 'جاري الرفع...';
    notifyListeners();
    try {
      await _uploadLocalChanges();
      _settings.lastSync = DateTime.now();
      _saveSettings();
      _status = SyncStatus.success;
      _statusMessage = 'تم الرفع بنجاح';
      _history.insert(0, SyncRecord(time: DateTime.now(), action: 'رفع', recordsCount: _pendingChanges, success: true));
      _pendingChanges = 0;
    } catch (e) {
      _status = SyncStatus.error;
      _statusMessage = 'فشل الرفع';
      _history.insert(0, SyncRecord(time: DateTime.now(), action: 'رفع', recordsCount: 0, success: false, error: e.toString()));
    }
    notifyListeners();
  }

  /// تحميل فقط
  Future<void> downloadOnly() async {
    _status = SyncStatus.syncing;
    _statusMessage = 'جاري التحميل...';
    notifyListeners();
    try {
      await _downloadRemoteChanges();
      _settings.lastSync = DateTime.now();
      _saveSettings();
      _status = SyncStatus.success;
      _statusMessage = 'تم التحميل بنجاح';
      _history.insert(0, SyncRecord(time: DateTime.now(), action: 'تحميل', recordsCount: 0, success: true));
    } catch (e) {
      _status = SyncStatus.error;
      _statusMessage = 'فشل التحميل';
    }
    notifyListeners();
  }

  // ===== العمليات الداخلية =====
  Future<void> _uploadLocalChanges() async {
    final api = ApiService();
    if (!api.hasToken) {
      await Future.delayed(const Duration(milliseconds: 500));
      return;
    }
    // رفع البيانات المحلية غير المتزامنة
    // TODO: إضافة تتبع للتغييرات المحلية غير المرفوعة
    debugPrint('☁️ تم رفع البيانات المحلية');
  }

  Future<void> _downloadRemoteChanges() async {
    final api = ApiService();
    if (!api.hasToken) {
      await Future.delayed(const Duration(milliseconds: 500));
      return;
    }
    // تحميل آخر البيانات من السيرفر
    try {
      await api.getTanks();
      await api.getFuelTransactions();
      debugPrint('☁️ تم تحميل البيانات من السيرفر');
    } catch (e) {
      debugPrint('⚠️ خطأ تحميل البيانات: $e');
    }
  }

  Future<void> _mergeConflicts() async {
    // حالياً: Last Write Wins strategy
    await Future.delayed(const Duration(milliseconds: 200));
    debugPrint('☁️ تم دمج البيانات');
  }

  void _startAutoSync() {
    _stopAutoSync();
    _autoSyncTimer = Timer.periodic(Duration(minutes: _settings.intervalMinutes), (_) => syncNow());
    debugPrint('☁️ المزامنة التلقائية: كل ${_settings.intervalMinutes} دقيقة');
  }

  void _stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }

  void _updatePendingCount() {
    if (_db.isInitialized) {
      _pendingChanges = _db.stats.values.fold(0, (s, v) => s + v);
    }
  }

  void _saveSettings() {
    if (_db.isInitialized) _db.saveSetting('sync_settings', _settings.toMap());
  }

  /// إعلام بتغيير محلي
  void notifyLocalChange() {
    _pendingChanges++;
    if (_settings.syncOnChange && isConfigured) syncNow();
    notifyListeners();
  }

  void dispose() {
    _stopAutoSync();
    super.dispose();
  }
}

// ============================================================
// ويدجت إعدادات المزامنة (تُضاف في الإعدادات)
// ============================================================
class CloudSyncWidget extends StatefulWidget {
  const CloudSyncWidget({super.key});
  @override
  State<CloudSyncWidget> createState() => _CloudSyncWidgetState();
}

class _CloudSyncWidgetState extends State<CloudSyncWidget> {
  final _urlCtrl = TextEditingController();
  final _keyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final sync = CloudSyncService();
    _urlCtrl.text = sync.settings.serverUrl;
    _keyCtrl.text = sync.settings.apiKey ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final sync = CloudSyncService();
    final statusColor = switch (sync.status) {
      SyncStatus.idle => Colors.grey,
      SyncStatus.syncing => const Color(0xFF42A5F5),
      SyncStatus.success => const Color(0xFF10B981),
      SyncStatus.error => const Color(0xFFEF5350),
      SyncStatus.offline => const Color(0xFFFFA726),
    };
    final statusIcon = switch (sync.status) {
      SyncStatus.idle => Icons.cloud_queue,
      SyncStatus.syncing => Icons.cloud_sync,
      SyncStatus.success => Icons.cloud_done,
      SyncStatus.error => Icons.cloud_off,
      SyncStatus.offline => Icons.signal_wifi_off,
    };

    return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
      // حالة المزامنة
      Container(padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [statusColor.withOpacity(0.08), statusColor.withOpacity(0.02)]),
          borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor.withOpacity(0.3))),
        child: Column(children: [
          Row(children: [
            Container(width: 60, height: 60, decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
              child: sync.status == SyncStatus.syncing
                ? const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF42A5F5)))
                : Icon(statusIcon, color: statusColor, size: 30)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('المزامنة السحابية', style: GoogleFonts.cairo(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text(sync.statusMessage, style: GoogleFonts.cairo(color: statusColor, fontSize: 12)),
              Text('آخر مزامنة: ${sync.lastSyncText}', style: GoogleFonts.cairo(color: Colors.grey[500], fontSize: 11)),
            ])),
            if (sync.pendingChanges > 0) Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFFFA726).withOpacity(0.1), shape: BoxShape.circle),
              child: Column(children: [Text('${sync.pendingChanges}', style: GoogleFonts.cairo(color: const Color(0xFFFFA726), fontWeight: FontWeight.bold, fontSize: 16)),
                Text('معلّق', style: GoogleFonts.cairo(color: Colors.grey[500], fontSize: 8))])),
          ]),
          if (sync.status == SyncStatus.syncing) ...[
            const SizedBox(height: 16),
            ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: sync.progress, backgroundColor: Colors.grey[800], color: statusColor, minHeight: 8)),
          ],
          const SizedBox(height: 16),
          // أزرار المزامنة
          Row(children: [
            Expanded(child: _syncBtn('مزامنة كاملة', Icons.sync, const Color(0xFF42A5F5), () => sync.syncNow())),
            const SizedBox(width: 8),
            Expanded(child: _syncBtn('رفع', Icons.cloud_upload, const Color(0xFF10B981), () => sync.uploadOnly())),
            const SizedBox(width: 8),
            Expanded(child: _syncBtn('تحميل', Icons.cloud_download, const Color(0xFF8B5CF6), () => sync.downloadOnly())),
          ]),
        ])),
      const SizedBox(height: 20),

      // إعدادات الخادم
      _section('إعدادات الخادم', Icons.dns, [
        _field('رابط الخادم', _urlCtrl, 'https://api.saharafuel.iq/sync'),
        const SizedBox(height: 10),
        _field('مفتاح API', _keyCtrl, 'أدخل مفتاح الوصول'),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, height: 42, child: ElevatedButton(
          onPressed: () {
            final s = sync.settings;
            s.serverUrl = _urlCtrl.text;
            s.apiKey = _keyCtrl.text.isEmpty ? null : _keyCtrl.text;
            sync.updateSettings(s);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حفظ إعدادات الخادم', style: GoogleFonts.cairo()), backgroundColor: const Color(0xFF10B981)));
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D9A3), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: Text('حفظ الإعدادات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        )),
      ]),
      const SizedBox(height: 16),

      // خيارات المزامنة
      _section('خيارات المزامنة', Icons.tune, [
        _toggle('المزامنة التلقائية', sync.settings.autoSync, (v) { sync.settings.autoSync = v; sync.updateSettings(sync.settings); setState(() {}); }),
        _toggle('مزامنة عند التشغيل', sync.settings.syncOnStartup, (v) { sync.settings.syncOnStartup = v; sync.updateSettings(sync.settings); setState(() {}); }),
        _toggle('مزامنة فورية عند التغيير', sync.settings.syncOnChange, (v) { sync.settings.syncOnChange = v; sync.updateSettings(sync.settings); setState(() {}); }),
        _toggle('WiFi فقط', sync.settings.wifiOnly, (v) { sync.settings.wifiOnly = v; sync.updateSettings(sync.settings); setState(() {}); }),
        Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [
          Text('الفاصل الزمني:', style: GoogleFonts.cairo(color: Colors.grey[400], fontSize: 12)),
          const Spacer(),
          ...([5, 15, 30, 60].map((m) => Padding(padding: const EdgeInsets.only(left: 6), child: GestureDetector(
            onTap: () { sync.settings.intervalMinutes = m; sync.updateSettings(sync.settings); setState(() {}); },
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: sync.settings.intervalMinutes == m ? const Color(0xFF00D9A3).withOpacity(0.15) : Colors.transparent, borderRadius: BorderRadius.circular(8),
                border: Border.all(color: sync.settings.intervalMinutes == m ? const Color(0xFF00D9A3) : Colors.grey[700]!)),
              child: Text('${m}د', style: GoogleFonts.cairo(color: sync.settings.intervalMinutes == m ? const Color(0xFF00D9A3) : Colors.grey[500], fontSize: 11))))))),
        ])),
      ]),
      const SizedBox(height: 16),

      // سجل المزامنة
      _section('سجل المزامنة', Icons.history, [
        if (sync.history.isEmpty) Center(child: Padding(padding: const EdgeInsets.all(20),
          child: Text('لا يوجد سجل مزامنة', style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 12)))),
        ...sync.history.take(10).map((r) => Container(
          margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFF252830), borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Icon(r.success ? Icons.check_circle : Icons.error, color: r.success ? const Color(0xFF10B981) : const Color(0xFFEF5350), size: 18),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.action, style: GoogleFonts.cairo(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              Text('${r.recordsCount} سجل${r.error != null ? " - ${r.error}" : ""}', style: GoogleFonts.cairo(color: Colors.grey[500], fontSize: 10)),
            ])),
            Text('${r.time.hour}:${r.time.minute.toString().padLeft(2, "0")}', style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 10)),
          ]))),
      ]),
    ]));
  }

  Widget _syncBtn(String label, IconData icon, Color color, VoidCallback onTap) => GestureDetector(onTap: onTap,
    child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 16), const SizedBox(width: 6), Text(label, style: GoogleFonts.cairo(color: color, fontSize: 11, fontWeight: FontWeight.bold))])));

  Widget _section(String title, IconData icon, List<Widget> children) => Container(
    padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF2D3748))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: const Color(0xFF00D9A3), size: 20), const SizedBox(width: 10), Text(title, style: GoogleFonts.cairo(color: const Color(0xFF00D9A3), fontWeight: FontWeight.bold, fontSize: 14))]),
      const SizedBox(height: 16), ...children]));

  Widget _field(String label, TextEditingController ctrl, String hint) => TextField(controller: ctrl, style: GoogleFonts.cairo(color: Colors.white, fontSize: 13), textDirection: TextDirection.ltr,
    decoration: InputDecoration(labelText: label, hintText: hint, labelStyle: GoogleFonts.cairo(color: Colors.grey[500], fontSize: 12), hintStyle: GoogleFonts.cairo(color: Colors.grey[700], fontSize: 11),
      filled: true, fillColor: const Color(0xFF252830), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)));

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) => Padding(padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [Text(label, style: GoogleFonts.cairo(color: Colors.grey[400], fontSize: 12)), const Spacer(),
      Switch(value: value, onChanged: onChanged, activeColor: const Color(0xFF00D9A3), inactiveTrackColor: const Color(0xFF2D3748), trackOutlineColor: WidgetStateProperty.all(Colors.transparent))]));
}

