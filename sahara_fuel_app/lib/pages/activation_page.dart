import '../constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/license_service.dart';
import '../main.dart';
import 'admin_license_page.dart';

class ActivationPage extends StatefulWidget {
  const ActivationPage({super.key});

  @override
  State<ActivationPage> createState() => _ActivationPageState();
}

class _ActivationPageState extends State<ActivationPage> {
  final _licenseService = LicenseService();
  final _keyController = TextEditingController();
  String _deviceId = 'Loading...';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  Future<void> _loadDeviceId() async {
    try {
      final id = await _licenseService.getDeviceId();
      if (mounted) {
        setState(() {
          _deviceId = id;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _deviceId = 'خطأ في جلب المعرف';
        });
      }
    }
  }

  Future<void> _activate() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final key = _keyController.text.trim();
    if (key.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'يرجى إدخال كود التفعيل';
      });
      return;
    }

    try {
      // حفظ الكود أولاً
      await _licenseService.saveLicenseKey(key);

      // التحقق من صلاحيته
      final result = await _licenseService.validateLicense();

      if (result.isValid) {
        if (!mounted) return;
        // الانتقال للشاشة الرئيسية أو تسجيل الدخول
        // هنا سنفترض أنه يذهب لصفحة تسجيل الدخول أو الرئيسية مباشرة حسب المنطق
        // سنعيد تشغيل التطبيق أو نذهب للرئيسية
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      } else {
        setState(() {
          _errorMessage = result.error ?? 'فشل التفعيل';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ أثناء التفعيل: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: Center(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.getSurfaceVariant(context),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.security,
                size: 64,
                color: Color(0xFF00D9A3),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onDoubleTap: () {
                  // Secret way to access admin panel (e.g., for developers/admins to generate keys)
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminLicensePage()),
                  );
                },
                child: const Text(
                  'تفعيل النسخة',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'يرجى إرسال معرف الجهاز إلى المسؤول للحصول على كود التفعيل',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              // Device ID Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'معرف الجهاز (Device ID):',
                            style: TextStyle(
                              color: Colors.cyan,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            _deviceId,
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'monospace',
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _deviceId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم نسخ المعرف')),
                        );
                      },
                      icon: const Icon(Icons.copy, color: Color(0xFF00D9A3)),
                      tooltip: 'نسخ',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Key Input
              TextField(
                controller: _keyController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'كود التفعيل',
                  labelStyle:
                      TextStyle(color: AppColors.getTextSecondary(context)),
                  filled: true,
                  fillColor: Colors.black12,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.vpn_key, color: Colors.grey),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.redAccent, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 32),

              // Activate Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _activate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D9A3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.getTextPrimary(context),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'تفعيل الآن',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
