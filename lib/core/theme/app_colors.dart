import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFFFAF7F2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFFDC2626); // Imperial Red
  static const Color primaryGold = Color(0xFFDC2626); // Kept for backward compatibility
  static const Color lightGold = Color(0xFFEF4444); // Kept for backward compatibility
  static const Color primaryText = Color(0xFF11110F);
  static const Color secondaryText = Color(0xFF77736D);
  static const Color muted = Color(0xFFB8B4AE);
  static const Color success = Color(0xff22c55e);
  static const Color error = Color(0xffd9534f);
  static const Color border = Color(0xFFE7E5E4); // Stone-200 border from SVG layouts
  static const Color divider = Color(0xFFE7E5E4);
  static const Color accentLight = Color(0xFFFFF1F2); // Soft red badge/pill background
  static const Color greenLight = Color(0xFFE8F5E9); // Soft green pill background
  static const Color greenText = Color(0xFF15803D); // Forest green for veg/hygiene tags

  // Gradient definitions
  static const LinearGradient redGradient = LinearGradient(
    colors: [primary, lightGold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = redGradient;
  static const LinearGradient goldGradient = redGradient; // Kept for backward compatibility

  static const LinearGradient darkGradient = LinearGradient(
    colors: [surface, background],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}