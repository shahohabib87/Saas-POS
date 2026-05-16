import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary palette
  static const Color primary = Color(0xFF4529E7);
  static const Color primaryLight = Color(0xFF5F4BFF);
  static const Color primaryFixed = Color(0xFFE3DFFF);
  static const Color primaryFixedDim = Color(0xFFC5C0FF);

  // Surface system (warm white scale)
  static const Color background = Color(0xFFFCF9F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLow = Color(0xFFF6F3F2);
  static const Color surfaceContainer = Color(0xFFF0EDED);
  static const Color surfaceHigh = Color(0xFFEAE7E7);

  // Sidebar
  static const Color sidebar = Color(0xFF130E3A);

  // Text / content
  static const Color onSurface = Color(0xFF1C1B1B);
  static const Color onSurfaceVariant = Color(0xFF474556);
  static const Color outline = Color(0xFF777588);
  static const Color outlineVariant = Color(0xFFC8C4D9);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFBA1A1A);

  // Legacy aliases — keep for files not yet updated
  static const Color textDark = Color(0xFF1C1B1B);
  static const Color textMid = Color(0xFF474556);
  static const Color textLight = Color(0xFF777588);
  static const Color divider = Color(0xFFC8C4D9);
  static const Color blueAccent = Color(0xFF4B76E6);
  static const Color chipBg = Color(0xFFE3DFFF);
  static const Color grey = Color(0xFFC8C4D9);
}
