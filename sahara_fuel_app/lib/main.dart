import '../constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'main_screen.dart';
import 'providers/fuel_provider.dart';
import 'services/license_service.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/api_service.dart';
import 'pages/activation_page.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة قاعدة البيانات المحلية
  await DatabaseService().init();

  // إعداد API Service
  // ملاحظة: غيّر الرابط حسب السيرفر الخاص بك
  // للويب: http://localhost:3000/api
  // للموبايل/إيميوليتر: http://10.0.2.2:3000/api (أندرويد) أو http://localhost:3000/api (iOS)
  ApiService().setBaseUrl('http://localhost:3000/api');

  // إنشاء الخدمات مع تحميل البيانات
  final fuelProvider = FuelProvider();
  final authService = AuthService();
  await fuelProvider.loadFromDatabase();
  await authService.loadFromDatabase();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: fuelProvider),
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'وقود صحاري كربلاء',
          locale: const Locale('ar'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ar'),
            Locale('en'),
          ],
          theme: ThemeData(
            brightness:
                themeProvider.isDark ? Brightness.dark : Brightness.light,
            scaffoldBackgroundColor: Colors.transparent,
          ),
          home: const LicenseCheckWrapper(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class LicenseCheckWrapper extends StatefulWidget {
  const LicenseCheckWrapper({super.key});

  @override
  State<LicenseCheckWrapper> createState() => _LicenseCheckWrapperState();
}

class _LicenseCheckWrapperState extends State<LicenseCheckWrapper> {
  @override
  void initState() {
    super.initState();
    _checkLicense();
  }

  Future<void> _checkLicense() async {
    // محاكاة تحميل بسيط للشعار
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final licenseService = LicenseService();
    // نحصل على النتيجة
    // ملاحظة: في النسخة النهائية يجب تفعيل فحص الوقت (NTP) بشكل صارم
    final result = await licenseService.validateLicense();

    if (!mounted) return;

    if (result.isValid) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ActivationPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo placeholder
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Color(0xFF00D9A3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_gas_station,
                  size: 50, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: Color(0xFF00D9A3)),
            const SizedBox(height: 16),
            const Text(
              'جاري التحقق من الترخيص...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late TextEditingController emailController;
  late TextEditingController passwordController;
  bool keepLogged = true;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _shakeController;

  // مفتاح الفورم للتحقق
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  /// التحقق من تسجيل الدخول - يحاول API أولاً ثم المحلي
  Future<void> _handleLogin() async {
    // التحقق من صحة الفورم
    if (!_formKey.currentState!.validate()) {
      _shakeError();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (!mounted) return;

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final provider = Provider.of<FuelProvider>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final api = ApiService();
    bool success = false;
    String? errorMsg;

    // ===== محاولة تسجيل الدخول عبر API أولاً =====
    try {
      final res = await api.login(email, password);
      if (res.success && res.data != null) {
        // نجاح API - مزامنة البيانات محلياً
        success = true;
        // مزامنة مع AuthService المحلي
        authService.login(email, password);
        provider.login(email, password);
        // تحميل البيانات من السيرفر
        await provider.syncWithApi();
        debugPrint('✅ تسجيل دخول ناجح عبر API + مزامنة');
      } else {
        // API رد بخطأ (بيانات خاطئة)
        errorMsg = res.error ?? 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      }
    } catch (e) {
      // السيرفر غير متاح - fallback للمحلي
      debugPrint('⚠️ السيرفر غير متاح، محاولة تسجيل الدخول محلياً...');
      success = authService.login(email, password);
      if (success) {
        provider.login(email, password);
        debugPrint('✅ تسجيل دخول ناجح محلياً (offline)');
      } else {
        errorMsg = 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      }
    }

    if (!mounted) return;

    if (success) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage =
            errorMsg ?? 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      });
      _shakeError();
    }
  }

  void _shakeError() {
    _shakeController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.pageGradient,
              ),
            ),
            child: CustomPaint(size: size, painter: ModernBackgroundPainter()),
          ),
          Center(
            child: Container(
              width: 900,
              height: 580,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Row(
                  children: [
                    // === الجانب الأيسر - الترحيب ===
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF1F4D6D),
                              Color(0xFF0D2847),
                              Color(0xFF1A3A52),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(50),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: CustomPaint(painter: DotPatternPainter()),
                            ),
                            const SizedBox(height: 40),
                            RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'JOIN THE\nLARGEST ',
                                    style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      height: 1.2,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'FUEL SYSTEM',
                                    style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF00D9A3),
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 25),
                            SizedBox(
                              width: 300,
                              child: Text(
                                'Explore fuel management and connect with teams.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[300],
                                  height: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            // معلومات الحسابات التجريبية
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.1)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'حسابات تجريبية:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[300],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _accountHint('مدير', 'admin@sahara-fuel.com',
                                      'admin123'),
                                  _accountHint('مدير محطة',
                                      'manager@sahara-fuel.com', 'manager123'),
                                  _accountHint(
                                      'مشغّل',
                                      'operator@sahara-fuel.com',
                                      'operator123'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // === الجانب الأيمن - نموذج الدخول ===
                    Expanded(
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(45),
                        child: Stack(
                          children: [
                            Positioned(
                              top: -20,
                              right: -20,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Color(0xFF00D9A3),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            SingleChildScrollView(
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // زر الإغلاق
                                    Align(
                                      alignment: Alignment.topRight,
                                      child: GestureDetector(
                                        onTap: () {},
                                        child: Container(
                                          width: 45,
                                          height: 45,
                                          decoration: BoxDecoration(
                                            color: Color(0xFF00D9A3),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    const Text(
                                      'Log In',
                                      style: TextStyle(
                                        fontSize: 38,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'Become a Manager . ',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const TextSpan(
                                            text: 'Join',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF00D9A3),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 30),

                                    // === رسالة الخطأ ===
                                    AnimatedBuilder(
                                      animation: _shakeController,
                                      builder: (context, child) {
                                        final offset = _shakeController.value <
                                                0.5
                                            ? (_shakeController.value * 20 - 5)
                                            : ((1 - _shakeController.value) *
                                                    20 -
                                                5);
                                        return Transform.translate(
                                          offset: Offset(
                                              _shakeController.isAnimating
                                                  ? offset
                                                  : 0,
                                              0),
                                          child: child,
                                        );
                                      },
                                      child: AnimatedSize(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        child: _errorMessage != null
                                            ? Container(
                                                width: double.infinity,
                                                margin: const EdgeInsets.only(
                                                    bottom: 16),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 12),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                      color:
                                                          Colors.red.shade200),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.error_outline,
                                                        color:
                                                            Colors.red.shade400,
                                                        size: 20),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Text(
                                                        _errorMessage!,
                                                        style: TextStyle(
                                                            color: Colors
                                                                .red.shade700,
                                                            fontSize: 13),
                                                      ),
                                                    ),
                                                    GestureDetector(
                                                      onTap: () => setState(
                                                          () => _errorMessage =
                                                              null),
                                                      child: Icon(Icons.close,
                                                          color: Colors
                                                              .red.shade300,
                                                          size: 18),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                    ),

                                    // === حقل البريد الإلكتروني ===
                                    TextFormField(
                                      controller: emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'يرجى إدخال البريد الإلكتروني';
                                        }
                                        return null;
                                      },
                                      onFieldSubmitted: (_) => _handleLogin(),
                                      decoration: InputDecoration(
                                        prefixIcon: Icon(
                                          Icons.person_outline,
                                          color: Colors.grey[400],
                                          size: 20,
                                        ),
                                        hintText: 'Email Address',
                                        hintStyle: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 14,
                                        ),
                                        border: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.grey[300]!),
                                        ),
                                        focusedBorder:
                                            const UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Color(0xFF00D9A3),
                                              width: 2),
                                        ),
                                        errorBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.red.shade300),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 25),

                                    // === حقل كلمة المرور ===
                                    TextFormField(
                                      controller: passwordController,
                                      obscureText: _obscurePassword,
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'يرجى إدخال كلمة المرور';
                                        }
                                        return null;
                                      },
                                      onFieldSubmitted: (_) => _handleLogin(),
                                      decoration: InputDecoration(
                                        prefixIcon: Icon(
                                          Icons.lock_outline,
                                          color: Colors.grey[400],
                                          size: 20,
                                        ),
                                        // زر إظهار/إخفاء كلمة المرور
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: Colors.grey[400],
                                            size: 20,
                                          ),
                                          onPressed: () => setState(() =>
                                              _obscurePassword =
                                                  !_obscurePassword),
                                        ),
                                        hintText: 'Password',
                                        hintStyle: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 14,
                                        ),
                                        border: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.grey[300]!),
                                        ),
                                        focusedBorder:
                                            const UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Color(0xFF00D9A3),
                                              width: 2),
                                        ),
                                        errorBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.red.shade300),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Keep me logged in
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: keepLogged,
                                          onChanged: (val) => setState(
                                              () => keepLogged = val ?? true),
                                          activeColor: const Color(0xFF00D9A3),
                                          side: BorderSide(
                                              color: Colors.grey[400]!),
                                        ),
                                        Expanded(
                                          child: Text(
                                            'Keep me logged in',
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[700]),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 25),

                                    // === زر تسجيل الدخول ===
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed:
                                            _isLoading ? null : _handleLogin,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF00D9A3),
                                          disabledBackgroundColor:
                                              const Color(0xFF00D9A3)
                                                  .withOpacity(0.6),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(25),
                                          ),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2.5,
                                                ),
                                              )
                                            : const Text(
                                                'LOG IN',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Center(
                                      child: Text(
                                        'Forgot your username or password?',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600]),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Center(
                                      child: RichText(
                                        textAlign: TextAlign.center,
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text:
                                                  'By clicking Log In, I confirm that I have read and agree to the ',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[600]),
                                            ),
                                            const TextSpan(
                                              text:
                                                  'Terms of Service, Privacy Policy',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF00D9A3),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            TextSpan(
                                              text: '.',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[600]),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountHint(String role, String email, String password) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: GestureDetector(
        onTap: () {
          setState(() {
            emailController.text = email;
            passwordController.text = password;
            _errorMessage = null;
          });
        },
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Color(0xFF00D9A3),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$role: $email / $password',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ModernBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    paint.color = const Color(0xFF1F4D6D).withOpacity(0.6);
    paint.strokeWidth = 3;
    paint.style = PaintingStyle.stroke;
    for (int i = 0; i < 6; i++) {
      canvas.drawLine(
        Offset(size.width * 0.2 + (i * 60), 0),
        Offset(0, size.height * 0.4 + (i * 60)),
        paint,
      );
    }
    for (int i = 0; i < 8; i++) {
      canvas.drawLine(
        Offset(size.width - (i * 80), size.height),
        Offset(size.width, size.height * 0.3 + (i * 80)),
        paint,
      );
    }
    paint.style = PaintingStyle.fill;
    paint.color = Colors.cyan.withOpacity(0.1);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.7), 120, paint);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.2), 100, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00D9A3)
      ..style = PaintingStyle.fill;
    final dotSize = 6.0;
    final spacing = 20.0;
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        canvas.drawCircle(
          Offset(spacing + (i * spacing), spacing + (j * spacing)),
          dotSize,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
