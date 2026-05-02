import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  /// 한글 텍스트 스타일 헬퍼 — Flame TextPaint 등에서 사용.
  static TextStyle koreanStyle({
    double fontSize = 14,
    Color color = AppColors.textPrimary,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return GoogleFonts.notoSansKr(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
    );
  }

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.deepShaft,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.minerDusk,
        secondary: AppColors.gold,
        surface: AppColors.cardBackground,
      ),
      textTheme: GoogleFonts.notoSansKrTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.cardBackground,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.minerDusk,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: GoogleFonts.notoSansKr(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        contentTextStyle: GoogleFonts.notoSansKr(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
