import 'package:flutter/material.dart';

class AppColors {
  static bool isDark = true;

  // الألوان الأساسية
  static Color get primary =>
      isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF8FAFB);
  static Color get accent =>
      isDark ? const Color(0xFF00D9A3) : const Color(0xFF009D78);
  static Color get orange =>
      isDark ? const Color(0xFFF4A261) : const Color(0xFFD87A2A);
  static Color get cardBg =>
      isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);

  // الألوان المعرّفة مسبقاً (للاستخدام المباشر)
  static const Color _darkSurface = Color(0xFF1A1F2E);
  static const Color _darkSurfaceVariant = Color(0xFF252D3D);
  static const Color _darkDialogBg = Color(0xFF0F2438);

  // خلفية الصفحات (التدرج)
  static List<Color> get pageGradient => isDark
      ? [const Color(0xFF0D1B2A), _darkDialogBg, const Color(0xFF0F2847)]
      : [
          const Color(0xFFF5F7FA),
          const Color(0xFFE8ECF1),
          const Color(0xFFF0F2F5)
        ];

  // ألوان التدرج
  static Color get gradientStart =>
      isDark ? const Color(0xFF1F4D6D) : const Color(0xFFB3D9F2);
  static Color get gradientMiddle =>
      isDark ? const Color(0xFF0D2847) : const Color(0xFF7CB8DD);
  static Color get gradientEnd =>
      isDark ? const Color(0xFF1A3A52) : const Color(0xFFD4E7F7);

  // ألوان البطاقات
  static Color get cardGreen =>
      isDark ? const Color(0xFF00D9A3) : const Color(0xFF009D78);
  static Color get cardOrange =>
      isDark ? const Color(0xFFFFA726) : const Color(0xFFD87A2A);
  static Color get cardPurple =>
      isDark ? const Color(0xFFAB47BC) : const Color(0xFF7C3B8F);

  // ألوان النصوص
  static Color get textPrimary =>
      isDark ? Colors.white : const Color(0xFF0F1419);
  static Color get textSecondary =>
      isDark ? const Color(0xFFB0B0B0) : const Color(0xFF4B5563);

  // ألوان الحالات
  static Color get success =>
      isDark ? const Color(0xFF10B981) : const Color(0xFF059669);
  static Color get warning =>
      isDark ? const Color(0xFFFFA726) : const Color(0xFFD87A2A);
  static Color get error =>
      isDark ? const Color(0xFFEF5350) : const Color(0xFFD32F2F);
  static Color get info =>
      isDark ? const Color(0xFF42A5F5) : const Color(0xFF1976D2);

  // ألوان إضافية للثيم
  static Color get scaffold =>
      isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF8FAFB);
  static Color get surface =>
      isDark ? const Color(0xFF1A1F2E) : const Color(0xFFFFFFFF);
  static Color get surfaceVariant =>
      isDark ? const Color(0xFF252D3D) : const Color(0xFFF5F6F8);
  static Color get sidebar =>
      isDark ? const Color(0xFF1A1F2E) : const Color(0xFFFFFFFF);
  static Color get sidebarBorder =>
      isDark ? Colors.grey[800]! : const Color(0xFFE2E4E8);
  static Color get divider =>
      isDark ? Colors.grey[800]! : const Color(0xFFE2E4E8);
  static Color get inputBg =>
      isDark ? const Color(0xFF252D3D) : const Color(0xFFF5F6F8);
  static Color get dialogBg =>
      isDark ? const Color(0xFF0F2438) : const Color(0xFFFBFCFE);
  static Color get tableHeader =>
      isDark ? const Color(0xFF0F2438) : const Color(0xFFF2F4F8);
  static Color get hintText =>
      isDark ? Colors.grey[600]! : const Color(0xFF8A92A0);
  static Color get subtleText =>
      isDark ? Colors.grey[500]! : const Color(0xFF9CA5B3);
  static Color get cardShadow =>
      isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.08);
  static Color get iconDefault =>
      isDark ? Colors.grey[500]! : Colors.grey[600]!;

  // ألوان الأزرار
  static Color get badgeBg => isDark ? const Color(0xFF1A1F2E) : Colors.white;
  static Color get badgeBorder =>
      isDark ? accent.withOpacity(0.2) : const Color(0xFFD0D5DD);

  // ألوان الرسوم البيانية
  static Color get chartBlue =>
      isDark ? const Color(0xFF42A5F5) : const Color(0xFF1976D2);
  static Color get chartGreen =>
      isDark ? const Color(0xFF10B981) : const Color(0xFF059669);
  static Color get chartOrange =>
      isDark ? const Color(0xFFFFA726) : const Color(0xFFD87A2A);
  static Color get chartRed =>
      isDark ? const Color(0xFFEF5350) : const Color(0xFFD32F2F);
  static Color get chartPurple =>
      isDark ? const Color(0xFF8B5CF6) : const Color(0xFF6A1B9A);

  // ألوان البطاقات الإحصائية
  static Color get statBg =>
      isDark ? const Color(0xFF1A1F2E) : const Color(0xFFF5F7FA);
  static Color get statBorder =>
      isDark ? const Color(0xFF2D3748) : const Color(0xFFD0D5DD);

  // ألوان إضافية للجداول والحوارات
  static Color get tableRowEven => isDark
      ? const Color(0xFF1E2127).withOpacity(0.3)
      : const Color(0xFFF5F7FA);
  static Color get tableRowOdd =>
      isDark ? Colors.transparent : const Color(0xFFFFFFFF);
  static Color get dialogHeader =>
      isDark ? const Color(0xFF1E2127) : const Color(0xFFEFF1F5);

  // ==================== دوال ديناميكية تأخذ BuildContext ====================

  /// الألوان الأساسية الديناميكية
  static Color getPrimary(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? const Color(0xFF0D1B2A) : const Color(0xFFF8FAFB);
  }

  static Color getAccent(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? const Color(0xFF00D9A3) : const Color(0xFF009D78);
  }

  static Color getOrange(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? const Color(0xFFF4A261) : const Color(0xFFD87A2A);
  }

  static Color getCardBg(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
  }

  /// خلفية الصفحات الديناميكية
  static List<Color> getPageGradient(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode
        ? [const Color(0xFF0D1B2A), const Color(0xFF0F2438), const Color(0xFF0F2847)]
        : [
            const Color(0xFFF5F7FA),
            const Color(0xFFE8ECF1),
            const Color(0xFFF0F2F5)
          ];
  }

  static Color getGradientStart(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? const Color(0xFF1F4D6D) : const Color(0xFFB3D9F2);
  }

  static Color getGradientMiddle(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? const Color(0xFF0D2847) : const Color(0xFF7CB8DD);
  }

  static Color getGradientEnd(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? const Color(0xFF1A3A52) : const Color(0xFFD4E7F7);
  }

  /// ألوان البطاقات الديناميكية
  static Color getCardGreen(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? const Color(0xFF00D9A3) : const Color(0xFF009D78);
  }

  static Color getCardOrange(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? const Color(0xFFFFA726) : const Color(0xFFD87A2A);
  }

  static Color getCardPurple(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? const Color(0xFFAB47BC) : const Color(0xFF7C3B8F);
  }

  /// ألوان النصوص الديناميكية
  static Color getTextPrimary(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? Colors.white : const Color(0xFF0F1419);
  }

  static Color getTextSecondary(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? const Color(0xFFB0B0B0) : const Color(0xFF4B5563);
  }

  /// ألوان الحالات الديناميكية
  static Color getSuccess(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? const Color(0xFF10B981) : const Color(0xFF059669);
  }

  static Color getWarning(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? const Color(0xFFFFA726) : const Color(0xFFD87A2A);
  }

  static Color getError(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? const Color(0xFFEF5350) : const Color(0xFFD32F2F);
  }

  static Color getInfo(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? const Color(0xFF42A5F5) : const Color(0xFF1976D2);
  }

  /// ألوان السطح الديناميكية
  static Color getScaffold(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? const Color(0xFF0D1B2A) : const Color(0xFFF8FAFB);
  }

  static Color getSurface(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? const Color(0xFF1A1F2E) : const Color(0xFFFFFFFF);
  }

  static Color getSurfaceVariant(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? const Color(0xFF252D3D) : const Color(0xFFF5F6F8);
  }

  static Color getSidebar(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? const Color(0xFF1A1F2E) : const Color(0xFFFFFFFF);
  }

  static Color getSidebarBorder(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? Colors.grey[800]! : const Color(0xFFE2E4E8);
  }

  static Color getDivider(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? Colors.grey[800]! : const Color(0xFFE2E4E8);
  }

  static Color getInputBg(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? const Color(0xFF252D3D) : const Color(0xFFF5F6F8);
  }

  static Color getDialogBg(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? const Color(0xFF0F2438) : const Color(0xFFFBFCFE);
  }

  static Color getTableHeader(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? const Color(0xFF0F2438) : const Color(0xFFF2F4F8);
  }

  static Color getHintText(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? Colors.grey[600]! : const Color(0xFF8A92A0);
  }

  static Color getSubtleText(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? Colors.grey[500]! : const Color(0xFF9CA5B3);
  }

  static Color getCardShadow(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode
        ? Colors.black.withOpacity(0.3)
        : Colors.grey.withOpacity(0.08);
  }

  static Color getIconDefault(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? Colors.grey[500]! : Colors.grey[600]!;
  }

  static Color getBadgeBg(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? const Color(0xFF1A1F2E) : Colors.white;
  }

  static Color getBadgeBorder(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode
        ? const Color(0xFF00D9A3).withOpacity(0.2)
        : const Color(0xFFD0D5DD);
  }

  /// ألوان الرسوم البيانية الديناميكية
  static Color getChartBlue(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? const Color(0xFF42A5F5) : const Color(0xFF1976D2);
  }

  static Color getChartGreen(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? const Color(0xFF10B981) : const Color(0xFF059669);
  }

  static Color getChartOrange(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? const Color(0xFFFFA726) : const Color(0xFFD87A2A);
  }

  static Color getChartRed(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? const Color(0xFFEF5350) : const Color(0xFFD32F2F);
  }

  static Color getChartPurple(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? const Color(0xFF8B5CF6) : const Color(0xFF6A1B9A);
  }

  /// ألوان البطاقات الإحصائية الديناميكية
  static Color getStatBg(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? const Color(0xFF1A1F2E) : const Color(0xFFF5F7FA);
  }

  static Color getStatBorder(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? const Color(0xFF2D3748) : const Color(0xFFD0D5DD);
  }

  /// ألوان الجداول والحوارات الديناميكية
  static Color getTableRowEven(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode
        ? const Color(0xFF1E2127).withOpacity(0.3)
        : const Color(0xFFF5F7FA);
  }

  static Color getTableRowOdd(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? Colors.transparent : const Color(0xFFFFFFFF);
  }

  static Color getDialogHeader(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? const Color(0xFF1E2127) : const Color(0xFFEFF1F5);
  }

  /// مساعد للتحقق من الوضع الليلي
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
}
