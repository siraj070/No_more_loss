
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Common radii, spacing, and containers.
class AppDecorations {
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(12));
  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(8));

  static List<BoxShadow> get softShadow => const [
    BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 4)),
  ];

  static BoxDecoration get card => BoxDecoration(
    color: AppColors.surface,
    borderRadius: radiusLg,
    boxShadow: softShadow,
    border: Border.all(color: AppColors.border),
  );

  static InputBorder get inputBorder => OutlineInputBorder(
    borderRadius: radiusMd,
    borderSide: const BorderSide(color: AppColors.border, width: 1),
  );

  static InputBorder get inputFocusedBorder => OutlineInputBorder(
    borderRadius: radiusMd,
    borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
  );
}
