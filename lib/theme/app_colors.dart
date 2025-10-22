
import 'package:flutter/material.dart';

/// Central color palette for a fresh, Zepto-like look (but original).
/// Primary teal-green with soft coral accents.
class AppColors {
  // Brand
  static const Color primary = Color(0xFF00C897);
  static const Color primaryDark = Color(0xFF007A7A);
  static const Color accent = Color(0xFFFF6F61);

  // Neutral
  static const Color bg = Color(0xFFF7F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE6EEF1);
  static const Color text = Color(0xFF1F2937);
  static const Color textMuted = Color(0xFF6B7280);

  // States
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Shadows (used via BoxShadow with opacity)
  static const Color shadow = Color(0x1A000000); // 10% black
}
