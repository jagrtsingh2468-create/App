import 'package:flutter/material.dart';

/// Single source of truth for brand colors. Referenced by [AppTheme] to
/// build the Material 3 ColorScheme for both light and dark modes.
class AppColors {
  AppColors._();

  static const Color seed = Color(0xFF7C4DFF); // Deep violet - brand color
  static const Color accent = Color(0xFF00E5C3); // Teal accent for waveforms
  static const Color danger = Color(0xFFFF5252); // Delete / recording pulse
  static const Color success = Color(0xFF4CAF50);

  // Light theme surfaces
  static const Color lightBackground = Color(0xFFFAFAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);

  // Dark theme surfaces
  static const Color darkBackground = Color(0xFF121016);
  static const Color darkSurface = Color(0xFF1E1B24);
}
