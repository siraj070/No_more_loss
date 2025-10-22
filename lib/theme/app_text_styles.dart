
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography system using Poppins for a clean e-commerce feel.
class AppTextStyles {
  static TextStyle get h1 => GoogleFonts.poppins(
    fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.text,
  );

  static TextStyle get h2 => GoogleFonts.poppins(
    fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.text,
  );

  static TextStyle get h3 => GoogleFonts.poppins(
    fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.text,
  );

  static TextStyle get body => GoogleFonts.poppins(
    fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.text,
  );

  static TextStyle get bodyMuted => GoogleFonts.poppins(
    fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textMuted,
  );

  static TextStyle get caption => GoogleFonts.poppins(
    fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textMuted,
  );

  static TextStyle get button => GoogleFonts.poppins(
    fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white,
  );
}
