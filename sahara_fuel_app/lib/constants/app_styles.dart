import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// أنماط النصوص والـ Decorations المستخدمة في التطبيق
class AppStyles {
  // عناوين رئيسية
  static TextStyle get headingLarge => GoogleFonts.cairo(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static TextStyle get headingMedium => GoogleFonts.cairo(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static TextStyle get headingSmall => GoogleFonts.cairo(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  // نص عادي
  static TextStyle get bodyLarge => GoogleFonts.cairo(
    fontSize: 18,
    color: AppColors.textPrimary,
  );
  
  static TextStyle get bodyMedium => GoogleFonts.cairo(
    fontSize: 16,
    color: AppColors.textPrimary,
  );
  
  static TextStyle get bodySmall => GoogleFonts.cairo(
    fontSize: 14,
    color: AppColors.textSecondary,
  );
  
  // تنسيق البطاقات
  static BoxDecoration cardDecoration({Color? color}) => BoxDecoration(
    color: AppColors.cardBg,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.2),
        blurRadius: 15,
        offset: const Offset(0, 5),
      ),
    ],
  );
  
  // تنسيق التدرج للبطاقات
  static BoxDecoration gradientCardDecoration(Color color) => BoxDecoration(
    borderRadius: BorderRadius.circular(20),
    gradient: LinearGradient(
      colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
    ),
  );
  
  // تنسيق الهيدر البرتقالي
  static BoxDecoration get orangeHeaderDecoration => BoxDecoration(
    color: AppColors.orange,
  );
}

