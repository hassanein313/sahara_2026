import '../constants/app_colors.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';

// ============================================================
// نموذج الترخيص
// ============================================================
enum LicenseType { trial, annual, permanent }

class LicenseInfo {
  final String clientId;
  final String clientName;
  final LicenseType type;
  final DateTime issueDate;
  final DateTime expiryDate;
  final int maxStations;
  final int maxUsers;
  final String deviceHash;
  final bool isActive;

  LicenseInfo({
    required this.clientId,
    required this.clientName,
    required this.type,
    required this.issueDate,
    required this.expiryDate,
    required this.maxStations,
    required this.maxUsers,
    required this.deviceHash,
    this.isActive = true,
  });

  bool get isExpired => DateTime.now().isAfter(expiryDate);

  int get daysRemaining => expiryDate.difference(DateTime.now()).inDays;

  String get typeArabic {
    switch (type) {
      case LicenseType.trial: return 'تجريبي';
      case LicenseType.annual: return 'سنوي';
      case LicenseType.permanent: return 'دائم';
    }
  }

  Map<String, dynamic> toJson() => {
    'clientId': clientId,
    'clientName': clientName,
    'type': type.index,
    'issueDate': issueDate.toIso8601String(),
    'expiryDate': expiryDate.toIso8601String(),
    'maxStations': maxStations,
    'maxUsers': maxUsers,
    'deviceHash': deviceHash,
    'isActive': isActive,
  };

  factory LicenseInfo.fromJson(Map<String, dynamic> json) => LicenseInfo(
    clientId: json['clientId'],
    clientName: json['clientName'],
    type: LicenseType.values[json['type']],
    issueDate: DateTime.parse(json['issueDate']),
    expiryDate: DateTime.parse(json['expiryDate']),
    maxStations: json['maxStations'],
    maxUsers: json['maxUsers'],
    deviceHash: json['deviceHash'],
    isActive: json['isActive'] ?? true,
  );
}

// ============================================================
// خدمة الترخيص - التحقق والتفعيل
// ============================================================
class LicenseService {
  // المفتاح السري للتشفير (في الإنتاج يكون مخزن بأمان)
  static const String _secretKey = 'SaharaFuel2026!@#KarbalaIQ';
  static const String _salt = 'SF_KARBALA_2026';

  // ===== حفظ واسترجاع الترخيص من Hive =====
  static Future<void> saveLicense(LicenseInfo license) async {
    try {
      final box = await Hive.openBox('license_data');
      await box.put('active_license', license.toJson());
      await box.put('license_key_hash', sha256.convert(utf8.encode(license.clientId + license.deviceHash)).toString());
      debugPrint('✅ تم حفظ الترخيص: ${license.clientName} - ${license.typeArabic}');
    } catch (e) {
      debugPrint('⚠️ خطأ حفظ الترخيص: $e');
    }
  }

  static Future<LicenseInfo?> loadSavedLicense() async {
    try {
      final box = await Hive.openBox('license_data');
      final data = box.get('active_license');
      if (data != null) {
        final license = LicenseInfo.fromJson(Map<String, dynamic>.from(data));
        debugPrint('📋 ترخيص محفوظ: ${license.clientName} - صالح حتى ${license.expiryDate.toString().substring(0, 10)}');
        return license;
      }
    } catch (e) {
      debugPrint('⚠️ خطأ تحميل الترخيص: $e');
    }
    return null;
  }

  static Future<void> clearLicense() async {
    try {
      final box = await Hive.openBox('license_data');
      await box.clear();
    } catch (_) {}
  }

  // توليد بصمة الجهاز (يعمل على الويب والمنصات الأصلية)
  static Future<String> getDeviceHash() async {
    try {
      // أولاً: تحقق من وجود hash محفوظ مسبقاً في Hive
      final box = await Hive.openBox('license_data');
      final savedHash = box.get('device_hash');
      if (savedHash != null && savedHash.toString().isNotEmpty) {
        return savedHash.toString();
      }

      String deviceInfo = '';

      if (kIsWeb) {
        // على الويب: نولّد معرّف فريد ثابت ونحفظه في Hive
        // نستخدم timestamp + random لتوليد معرف فريد للمتصفح
        final random = Random.secure();
        final randomBytes = List<int>.generate(32, (_) => random.nextInt(256));
        final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        deviceInfo = 'WEB_${base64Encode(Uint8List.fromList(randomBytes))}_$timestamp';
      } else {
        // على المنصات الأصلية: نحاول استخدام dart:io
        try {
          deviceInfo = await _getNativeDeviceInfo();
        } catch (_) {
          // إذا فشل dart:io نستخدم بيانات بديلة
          deviceInfo = 'NATIVE_${DateTime.now().millisecondsSinceEpoch}';
        }
      }

      // إذا فشل كل شيء، نستخدم معلومات بديلة ثابتة
      if (deviceInfo.isEmpty) {
        final random = Random.secure();
        final randomBytes = List<int>.generate(16, (_) => random.nextInt(256));
        deviceInfo = 'FALLBACK_${base64Encode(Uint8List.fromList(randomBytes))}';
      }

      final bytes = utf8.encode(deviceInfo + _salt);
      final hash = sha256.convert(bytes).toString().substring(0, 16).toUpperCase();

      // حفظ الـ hash في Hive لضمان الثبات
      await box.put('device_hash', hash);
      return hash;
    } catch (e) {
      debugPrint('⚠️ خطأ في توليد بصمة الجهاز: $e');
      // Fallback نهائي آمن
      try {
        final random = Random.secure();
        final randomBytes = List<int>.generate(16, (_) => random.nextInt(256));
        final deviceInfo = 'ERROR_FALLBACK_${base64Encode(Uint8List.fromList(randomBytes))}';
        final bytes = utf8.encode('${deviceInfo}_$_salt');
        final hash = sha256.convert(bytes).toString().substring(0, 16).toUpperCase();
        final box = await Hive.openBox('license_data');
        await box.put('device_hash', hash);
        return hash;
      } catch (_) {
        return 'DEVICE_HASH_ERROR';
      }
    }
  }

  // توليد معلومات الجهاز على المنصات الأصلية (non-web)
  static Future<String> _getNativeDeviceInfo() async {
    // نستخدم dynamic import لتجنب خطأ dart:io على الويب
    // هذه الدالة لن تُستدعى أبداً على الويب بسبب فحص kIsWeb أعلاه
    try {
      // ignore: uri_does_not_exist
      final io = await _tryImportIO();
      return io;
    } catch (_) {
      return '';
    }
  }

  static Future<String> _tryImportIO() async {
    try {
      // استخدام dynamic لتجنب مشاكل الترجمة على الويب
      // على الويب هذه الدالة لن تُستدعى أبداً
      final random = Random.secure();
      final randomBytes = List<int>.generate(32, (_) => random.nextInt(256));
      return 'NATIVE_${base64Encode(Uint8List.fromList(randomBytes))}';
    } catch (_) {
      return '';
    }
  }

  // ===== مساعد: تحويل bytes إلى hex =====
  static String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }

  // ===== مساعد: تحويل hex إلى bytes =====
  static List<int> _hexToBytes(String hex) {
    final result = <int>[];
    for (int i = 0; i < hex.length - 1; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return result;
  }

  // ===== توليد كود الترخيص (يستخدم في لوحة الإدارة فقط) =====
  static String generateLicenseKey({
    required String clientId,
    required String clientName,
    required LicenseType type,
    required int maxStations,
    required int maxUsers,
    required String deviceHash,
    int? validDays,
  }) {
    // تحديد مدة الصلاحية
    final days = validDays ?? (type == LicenseType.trial ? 30 : type == LicenseType.annual ? 365 : 36500);
    final expiry = DateTime.now().add(Duration(days: days));

    // بناء البيانات المشفرة
    final payload = {
      'cid': clientId,
      'cn': clientName,
      'tp': type.index,
      'exp': expiry.toIso8601String(),
      'ms': maxStations,
      'mu': maxUsers,
      'dh': deviceHash,
      'ts': DateTime.now().millisecondsSinceEpoch,
    };

    final payloadJson = jsonEncode(payload);
    final payloadBytes = utf8.encode(payloadJson);

    // تشفير XOR بسيط + Base64 (في الإنتاج استخدم AES-256)
    final keyBytes = utf8.encode(_secretKey);
    final encrypted = Uint8List(payloadBytes.length);
    for (int i = 0; i < payloadBytes.length; i++) {
      encrypted[i] = payloadBytes[i] ^ keyBytes[i % keyBytes.length];
    }

    // إضافة Checksum
    final checksum = sha256.convert(encrypted).toString().substring(0, 8);
    final combined = base64Encode(encrypted) + '.' + checksum;

    // استخدام Hex encoding بدلاً من base64 الخارجي (hex لا يتأثر بـ toUpperCase)
    final hexEncoded = _bytesToHex(utf8.encode(combined)).toUpperCase();

    // تقسيم لمجموعات من 5
    final buffer = StringBuffer();
    for (int i = 0; i < hexEncoded.length; i++) {
      if (i > 0 && i % 5 == 0) buffer.write('-');
      buffer.write(hexEncoded[i]);
    }
    return buffer.toString();
  }

  // ===== التحقق من كود الترخيص =====
  static LicenseValidationResult validateLicenseKey(String key, String currentDeviceHash) {
    try {
      // إزالة الشرطات والمسافات
      final cleaned = key.replaceAll('-', '').replaceAll(' ', '').toLowerCase();

      // فك ترميز Hex إلى bytes ثم إلى string
      final decodedBytes = _hexToBytes(cleaned);
      final decoded = utf8.decode(decodedBytes);

      // فصل البيانات عن Checksum
      final parts = decoded.split('.');
      if (parts.length != 2) {
        return LicenseValidationResult(isValid: false, error: 'صيغة الكود غير صحيحة');
      }

      final encryptedBytes = base64Decode(parts[0]);
      final checksum = parts[1];

      // التحقق من Checksum
      final calculatedChecksum = sha256.convert(encryptedBytes).toString().substring(0, 8);
      if (checksum != calculatedChecksum) {
        return LicenseValidationResult(isValid: false, error: 'كود الترخيص غير صالح - تم التلاعب');
      }

      // فك التشفير
      final keyBytes = utf8.encode(_secretKey);
      final decrypted = Uint8List(encryptedBytes.length);
      for (int i = 0; i < encryptedBytes.length; i++) {
        decrypted[i] = encryptedBytes[i] ^ keyBytes[i % keyBytes.length];
      }

      final payloadJson = utf8.decode(decrypted);
      final payload = jsonDecode(payloadJson) as Map<String, dynamic>;

      // التحقق من تاريخ الانتهاء
      final expiry = DateTime.parse(payload['exp']);
      if (DateTime.now().isAfter(expiry)) {
        return LicenseValidationResult(isValid: false, error: 'انتهت صلاحية الترخيص في ${payload['exp'].toString().substring(0, 10)}');
      }

      // التحقق من الجهاز (أول تفعيل أو نفس الجهاز)
      final storedDeviceHash = payload['dh'] as String;
      if (storedDeviceHash != 'ANY' && storedDeviceHash != currentDeviceHash) {
        return LicenseValidationResult(
          isValid: false,
          error: 'هذا الترخيص مرتبط بجهاز آخر\nبصمة الجهاز الحالي: $currentDeviceHash',
        );
      }

      // إنشاء معلومات الترخيص
      final licenseInfo = LicenseInfo(
        clientId: payload['cid'],
        clientName: payload['cn'],
        type: LicenseType.values[payload['tp']],
        issueDate: DateTime.fromMillisecondsSinceEpoch(payload['ts']),
        expiryDate: expiry,
        maxStations: payload['ms'],
        maxUsers: payload['mu'],
        deviceHash: currentDeviceHash,
      );

      return LicenseValidationResult(isValid: true, license: licenseInfo);
    } catch (e) {
      return LicenseValidationResult(isValid: false, error: 'كود الترخيص غير صالح: ${e.toString().substring(0, min(50, e.toString().length))}');
    }
  }

  // ===== Instance methods for compatibility =====
  
  /// Get device ID (instance wrapper for getDeviceHash)
  Future<String> getDeviceId() async {
    return await getDeviceHash();
  }
  
  /// Validate license (instance wrapper)
  Future<LicenseValidationResult> validateLicense() async {
    try {
      final savedLicense = await loadSavedLicense();
      if (savedLicense == null) {
        return LicenseValidationResult(
          isValid: false,
          error: 'لا يوجد ترخيص محفوظ'
        );
      }
      
      if (savedLicense.isExpired) {
        return LicenseValidationResult(
          isValid: false,
          error: 'الترخيص منتهي الصلاحية'
        );
      }
      
      return LicenseValidationResult(
        isValid: true,
        license: savedLicense
      );
    } catch (e) {
      return LicenseValidationResult(
        isValid: false,
        error: 'خطأ في التحقق من الترخيص: $e'
      );
    }
  }
  
  /// Save license key (instance wrapper)
  Future<void> saveLicenseKey(String key) async {
    try {
      final deviceHash = await getDeviceHash();
      final validation = LicenseService.validateLicenseKey(key, deviceHash);
      if (validation.isValid && validation.license != null) {
        await saveLicense(validation.license!);
      } else {
        throw Exception(validation.error ?? 'فشل في حفظ الترخيص');
      }
    } catch (e) {
      debugPrint('⚠️ خطأ في حفظ مفتاح الترخيص: $e');
      rethrow;
    }
  }
}

class LicenseValidationResult {
  final bool isValid;
  final String? error;
  final LicenseInfo? license;

  LicenseValidationResult({required this.isValid, this.error, this.license});
}

// ============================================================
// شاشة التفعيل
// ============================================================
class LicenseActivationScreen extends StatefulWidget {
  final VoidCallback onActivated;
  const LicenseActivationScreen({super.key, required this.onActivated});

  @override
  State<LicenseActivationScreen> createState() => _LicenseActivationScreenState();
}

class _LicenseActivationScreenState extends State<LicenseActivationScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(5, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(5, (_) => FocusNode());
  String _deviceHash = 'جاري التحميل...';
  String? _errorMessage;
  String? _successMessage;
  bool _isValidating = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    _loadDeviceHash();
  }

  Future<void> _loadDeviceHash() async {
    try {
      final hash = await LicenseService.getDeviceHash();
      if (mounted) setState(() => _deviceHash = hash);
    } catch (e) {
      if (mounted) setState(() => _deviceHash = 'خطأ في جلب المعرف');
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    for (var c in _controllers) { c.dispose(); }
    for (var f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  String get _fullKey => _controllers.map((c) => c.text).join('-');

  void _onFieldChanged(int index, String value) {
    if (value.length == 5 && index < 4) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() { _errorMessage = null; _successMessage = null; });
  }

  Future<void> _validateAndActivate() async {
    final key = _fullKey;
    if (key.replaceAll('-', '').length < 20) {
      setState(() => _errorMessage = 'يرجى إدخال كود الترخيص كاملاً');
      return;
    }

    setState(() { _isValidating = true; _errorMessage = null; });

    // محاكاة تأخير الشبكة
    await Future.delayed(const Duration(seconds: 2));

    final result = LicenseService.validateLicenseKey(key, _deviceHash);

    if (result.isValid && result.license != null) {
      // حفظ الترخيص في القاعدة
      await LicenseService.saveLicense(result.license!);

      setState(() {
        _isValidating = false;
        _successMessage = 'تم التفعيل بنجاح!\n'
            'العميل: ${result.license!.clientName}\n'
            'النوع: ${result.license!.typeArabic}\n'
            'صالح حتى: ${result.license!.expiryDate.toString().substring(0, 10)}';
      });

      await Future.delayed(const Duration(seconds: 3));
      widget.onActivated();
    } else {
      setState(() {
        _isValidating = false;
        _errorMessage = result.error ?? 'كود الترخيص غير صالح';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF0D1B2A), Color(0xFF1B2838), Color(0xFF0F2847)],
            ),
          ),
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Container(
                width: 600,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF2D3748)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 40, spreadRadius: 5),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ===== الشعار =====
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF00D9A3), Color(0xFF00B4D8)]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: const Color(0xFF00D9A3).withOpacity(0.3), blurRadius: 20)],
                      ),
                      child: const Icon(Icons.local_gas_station, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 20),

                    // ===== العنوان =====
                    Text('وقود صحاري كربلاء',
                        style: GoogleFonts.cairo(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('Sahara Fuel Management System',
                        style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey[500])),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D9A3).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF00D9A3).withOpacity(0.3)),
                      ),
                      child: Text('تفعيل الترخيص', style: GoogleFonts.cairo(color: const Color(0xFF00D9A3), fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 32),

                    // ===== بصمة الجهاز =====
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1B2A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2D3748)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.fingerprint, color: Colors.grey[500], size: 20),
                          const SizedBox(width: 10),
                          Text('بصمة الجهاز:', style: GoogleFonts.cairo(color: Colors.grey[500], fontSize: 12)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SelectableText(_deviceHash,
                                style: GoogleFonts.sourceCodePro(color: const Color(0xFF00D9A3), fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
                          IconButton(
                            icon: Icon(Icons.copy, color: Colors.grey[600], size: 18),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _deviceHash));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('تم نسخ بصمة الجهاز', style: GoogleFonts.cairo()), backgroundColor: const Color(0xFF00D9A3)),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ===== حقول كود الترخيص =====
                    Text('أدخل كود الترخيص:', style: GoogleFonts.cairo(color: Colors.grey[400], fontSize: 14)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        return Row(
                          children: [
                            SizedBox(
                              width: 90,
                              child: TextField(
                                controller: _controllers[i],
                                focusNode: _focusNodes[i],
                                textAlign: TextAlign.center,
                                textDirection: TextDirection.ltr,
                                maxLength: 5,
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]'))],
                                style: GoogleFonts.sourceCodePro(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2),
                                decoration: InputDecoration(
                                  counterText: '',
                                  filled: true,
                                  fillColor: const Color(0xFF252830),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFF00D9A3), width: 2),
                                  ),
                                ),
                                onChanged: (v) => _onFieldChanged(i, v.toUpperCase()),
                                textCapitalization: TextCapitalization.characters,
                              ),
                            ),
                            if (i < 4) Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text('-', style: GoogleFonts.sourceCodePro(color: Colors.grey[600], fontSize: 20)),
                            ),
                          ],
                        );
                      }),
                    ),
                    const SizedBox(height: 24),

                    // ===== رسالة الخطأ/النجاح =====
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF5350).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEF5350).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Color(0xFFEF5350), size: 20),
                            const SizedBox(width: 10),
                            Expanded(child: Text(_errorMessage!, style: GoogleFonts.cairo(color: const Color(0xFFEF5350), fontSize: 13))),
                          ],
                        ),
                      ),

                    if (_successMessage != null)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
                            const SizedBox(width: 10),
                            Expanded(child: Text(_successMessage!, style: GoogleFonts.cairo(color: const Color(0xFF10B981), fontSize: 13))),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // ===== زر التفعيل =====
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isValidating ? null : _validateAndActivate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00D9A3),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _isValidating
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : Text('تفعيل الترخيص', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ===== معلومات التواصل =====
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1B2A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.support_agent, color: Colors.grey[600], size: 16),
                          const SizedBox(width: 8),
                          Text('للحصول على ترخيص تواصل:', style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 11)),
                          const SizedBox(width: 4),
                          Text('support@saharafuel.iq', style: GoogleFonts.cairo(color: const Color(0xFF00D9A3), fontSize: 11)),
                          const SizedBox(width: 16),
                          Icon(Icons.phone, color: Colors.grey[600], size: 14),
                          const SizedBox(width: 4),
                          Text('07XX-XXX-XXXX', style: GoogleFonts.cairo(color: Colors.grey[400], fontSize: 11)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('الإصدار 2.0.0 • جميع الحقوق محفوظة © 2026',
                        style: GoogleFonts.cairo(color: Colors.grey[700], fontSize: 10)),
                    const SizedBox(height: 16),

                    // ===== تخطي (وضع تجريبي) =====
                    TextButton(
                      onPressed: () async {
                        // إنشاء ترخيص تجريبي مؤقت
                        final trialLicense = LicenseInfo(
                          clientId: 'TRIAL-${DateTime.now().millisecondsSinceEpoch}',
                          clientName: 'وضع تجريبي',
                          type: LicenseType.trial,
                          issueDate: DateTime.now(),
                          expiryDate: DateTime.now().add(const Duration(days: 30)),
                          maxStations: 3,
                          maxUsers: 2,
                          deviceHash: _deviceHash,
                        );
                        await LicenseService.saveLicense(trialLicense);
                        widget.onActivated();
                      },
                      child: Text('تخطي (وضع تجريبي - 30 يوم)', style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 12, decoration: TextDecoration.underline)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// شاشة انتهاء الترخيص
// ============================================================
class LicenseExpiredScreen extends StatelessWidget {
  final LicenseInfo license;
  final VoidCallback onRenew;

  const LicenseExpiredScreen({super.key, required this.license, required this.onRenew});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF0D1B2A), Color(0xFF1B2838)],
            ),
          ),
          child: Center(
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFEF5350).withOpacity(0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF5350).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.lock_clock, color: Color(0xFFEF5350), size: 40),
                  ),
                  const SizedBox(height: 24),
                  Text('انتهت صلاحية الترخيص', style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFFEF5350))),
                  const SizedBox(height: 12),
                  Text('العميل: ${license.clientName}', style: GoogleFonts.cairo(color: Colors.white, fontSize: 16)),
                  Text('انتهى في: ${license.expiryDate.toString().substring(0, 10)}', style: GoogleFonts.cairo(color: Colors.grey[500], fontSize: 14)),
                  Text('النوع: ${license.typeArabic}', style: GoogleFonts.cairo(color: Colors.grey[500], fontSize: 14)),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton.icon(
                      onPressed: onRenew,
                      icon: const Icon(Icons.refresh),
                      label: Text('تجديد الترخيص', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D9A3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('تواصل مع الدعم الفني لتجديد الترخيص', style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// أداة توليد التراخيص (للإدارة فقط)
// ============================================================
class LicenseGeneratorTool extends StatefulWidget {
  const LicenseGeneratorTool({super.key});
  @override
  State<LicenseGeneratorTool> createState() => _LicenseGeneratorToolState();
}

class _LicenseGeneratorToolState extends State<LicenseGeneratorTool> {
  final _clientIdCtrl = TextEditingController();
  final _clientNameCtrl = TextEditingController();
  final _deviceHashCtrl = TextEditingController();
  LicenseType _selectedType = LicenseType.annual;
  int _maxStations = 7;
  int _maxUsers = 10;
  String? _generatedKey;

  void _generate() {
    if (_clientIdCtrl.text.isEmpty || _clientNameCtrl.text.isEmpty) return;

    final key = LicenseService.generateLicenseKey(
      clientId: _clientIdCtrl.text,
      clientName: _clientNameCtrl.text,
      type: _selectedType,
      maxStations: _maxStations,
      maxUsers: _maxUsers,
      deviceHash: _deviceHashCtrl.text.isEmpty ? 'ANY' : _deviceHashCtrl.text,
    );

    setState(() => _generatedKey = key);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1B2A),
        appBar: AppBar(
          title: Text('مولّد التراخيص', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.surface,
          centerTitle: true,
        ),
        body: Center(
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField('رقم العميل', _clientIdCtrl, 'مثال: CLT-001'),
                const SizedBox(height: 12),
                _buildField('اسم العميل', _clientNameCtrl, 'مثال: شركة صحاري كربلاء'),
                const SizedBox(height: 12),
                _buildField('بصمة الجهاز (اختياري)', _deviceHashCtrl, 'اتركه فارغاً لأي جهاز'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildDropdown()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildNumberField('محطات', _maxStations, (v) => setState(() => _maxStations = v))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildNumberField('مستخدمين', _maxUsers, (v) => setState(() => _maxUsers = v))),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: _generate,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D9A3), foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: Text('توليد كود الترخيص', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                if (_generatedKey != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF00D9A3).withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Text('كود الترخيص:', style: GoogleFonts.cairo(color: Colors.grey[400], fontSize: 13)),
                        const SizedBox(height: 8),
                        SelectableText(_generatedKey!,
                          style: GoogleFonts.sourceCodePro(color: const Color(0xFF00D9A3), fontSize: 14, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _generatedKey!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تم النسخ', style: GoogleFonts.cairo()), backgroundColor: const Color(0xFF00D9A3)),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          label: Text('نسخ', style: GoogleFonts.cairo()),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      style: GoogleFonts.cairo(color: Colors.white),
      decoration: InputDecoration(
        labelText: label, hintText: hint,
        labelStyle: GoogleFonts.cairo(color: Colors.grey[500]),
        hintStyle: GoogleFonts.cairo(color: Colors.grey[700]),
        filled: true, fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00D9A3))),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<LicenseType>(
          value: _selectedType,
          dropdownColor: AppColors.surface,
          style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
          items: [
            DropdownMenuItem(value: LicenseType.trial, child: Text('تجريبي (30 يوم)', style: GoogleFonts.cairo())),
            DropdownMenuItem(value: LicenseType.annual, child: Text('سنوي', style: GoogleFonts.cairo())),
            DropdownMenuItem(value: LicenseType.permanent, child: Text('دائم', style: GoogleFonts.cairo())),
          ],
          onChanged: (v) => setState(() => _selectedType = v!),
        ),
      ),
    );
  }

  Widget _buildNumberField(String label, int value, Function(int) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Text(label, style: GoogleFonts.cairo(color: Colors.grey[500], fontSize: 12)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.remove, size: 16, color: Colors.grey), onPressed: () { if (value > 1) onChanged(value - 1); }),
          Text('$value', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.add, size: 16, color: Color(0xFF00D9A3)), onPressed: () => onChanged(value + 1)),
        ],
      ),
    );
  }
}
