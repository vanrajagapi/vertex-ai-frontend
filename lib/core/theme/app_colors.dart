import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary palette - Professional blue tones (inspired by MCA/Government portals)
  static const Color primaryDark = Color(0xFF0D2137);
  static const Color primary = Color(0xFF1A3A5C);
  static const Color primaryLight = Color(0xFF2B5F8A);
  static const Color primaryAccent = Color(0xFF3D7AB5);

  // Secondary palette
  static const Color secondary = Color(0xFFE8A317);
  static const Color secondaryLight = Color(0xFFF5C84C);
  static const Color secondaryDark = Color(0xFFC48A0A);

  // Accent colors
  static const Color accent = Color(0xFF00897B);
  static const Color accentLight = Color(0xFF4DB6AC);

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF8F9FA);
  static const Color lightGrey = Color(0xFFE9ECEF);
  static const Color grey = Color(0xFFADB5BD);
  static const Color darkGrey = Color(0xFF6C757D);
  static const Color dark = Color(0xFF343A40);
  static const Color black = Color(0xFF212529);

  // Status colors
  static const Color success = Color(0xFF28A745);
  static const Color error = Color(0xFFDC3545);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF17A2B8);

  // Background & surface
  static const Color background = Color(0xFFF0F4F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardShadow = Color(0x1A000000);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primaryLight],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF0D2137), Color(0xFF1A3A5C), Color(0xFF2B5F8A)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryLight],
  );
}
