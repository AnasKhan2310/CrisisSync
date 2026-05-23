import 'package:flutter/material.dart';

class AppTheme {
  // Theme Color Palette
  static const Color primary = Color(0xFF0B5D5B); // DeepSeaGreen
  static const Color secondary = Color(0xFF2E8B8B); // Teal
  static const Color accent = Color(0xFF1FBFB8); // Light Accent
  static const Color background = Color(0xFFF4F7F6); // Off-White
  static const Color cardColor = Colors.white;
  
  static const Color alertRed = Color(0xFFD72638);
  static const Color warningYellow = Color(0xFFF4B400);
  static const Color textDark = Color(0xFF1E2D2F);
  static const Color textLight = Color(0xFF6B7A7C);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient alertGradient = LinearGradient(
    colors: [alertRed, Color(0xFFE85D04)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glassmorphic Card Decoration (Slight border, shadows, transparency)
  static BoxDecoration glassCardDecoration({
    Color color = Colors.white,
    double opacity = 0.85,
    double borderRadius = 16.0,
    Color borderColor = Colors.white24,
  }) {
    return BoxDecoration(
      color: color.withOpacity(opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ],
    );
  }

  // Theme data settings
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        error: alertRed,
        surface: cardColor,
      ),
      fontFamily: 'Inter', // Will resolve to system sans-serif if font asset missing
      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 24),
        titleLarge: TextStyle(color: textDark, fontWeight: FontWeight.w600, fontSize: 20),
        bodyLarge: TextStyle(color: textDark, fontSize: 16, height: 1.4),
        bodyMedium: TextStyle(color: textLight, fontSize: 14),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white24, width: 1),
        ),
      ),
    );
  }
}
