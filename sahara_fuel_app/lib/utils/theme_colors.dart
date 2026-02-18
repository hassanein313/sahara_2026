import 'package:flutter/material.dart';

/// نظام الألوان الديناميكي
class ThemeColors {
  // Light Mode Colors
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightCard = Colors.white;
  static const Color lightText = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF666666);
  static const Color lightBorder = Color(0xFFE0E0E0);
  static const Color lightSurfaceLight = Color(0xFFFAFAFA);

  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF0F0F0F);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkBorder = Color(0xFF333333);
  static const Color darkSurfaceLight = Color(0xFF2A2A2A);

  // Neutral Colors (same in both modes)
  static const Color primary = Color(0xFFD4A843);
  static const Color accent = Color(0xFF2DD4BF);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Sand/Desert Colors
  static const Color sandLight = Color(0xFFF5E6D3);
  static const Color sandMedium = Color(0xFFD4B896);
  static const Color sandDark = Color(0xFFBFA07A);

  /// Get text color based on theme
  static Color getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkText
        : lightText;
  }

  /// Get secondary text color based on theme
  static Color getTextSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextSecondary
        : lightTextSecondary;
  }

  /// Get background color based on theme
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackground
        : lightBackground;
  }

  /// Get card color based on theme
  static Color getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkCard
        : lightCard;
  }

  /// Get border color based on theme
  static Color getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBorder
        : lightBorder;
  }

  /// Get surface light color based on theme
  static Color getSurfaceLightColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurfaceLight
        : lightSurfaceLight;
  }

  /// Check if dark mode
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
}
