import 'package:flutter/material.dart';

/// 별빛 광산 색상 팔레트
/// 기획서 7.1 색상 팔레트 섹션 기반.
class AppColors {
  AppColors._();

  // 주조색
  static const minerDusk = Color(0xFFE89B5C); // 광부 황혼
  static const deepShaft = Color(0xFF3A3A6E); // 깊은 갱도
  static const starlightCream = Color(0xFFFFF4D6); // 별빛 크림

  // 광물 빛
  static const crystalTeal = Color(0xFF5DC5C5);
  static const rubyPink = Color(0xFFFF6B9D);
  static const emeraldGreen = Color(0xFF4CB573);
  static const gold = Color(0xFFFFC847);
  static const diamondWhite = Color(0xFFE8F4FF);

  // 광맥 깊이별 그라데이션
  static const layer1Top = Color(0xFFE89B5C);
  static const layer1Bottom = Color(0xFF6E4C9F);

  static const layer2Top = Color(0xFF5DC5C5);
  static const layer2Bottom = Color(0xFF1A4B6E);

  static const layer3Top = Color(0xFFFF6B5C);
  static const layer3Bottom = Color(0xFF4B1A1A);

  static const layer4Top = Color(0xFFB8E0FF);
  static const layer4Bottom = Color(0xFF4A6E8C);

  static const layer5Top = Color(0xFF6E5C8C);
  static const layer5Bottom = Color(0xFF1A1B3A);

  // UI
  static const cardBackground = Color(0xFF2A2540);
  static const cardBackgroundLight = Color(0xFF3A3458);
  static const textPrimary = Color(0xFFFFF4D6);
  static const textSecondary = Color(0xFFB6B0CC);
  static const dividerColor = Color(0xFF4A4470);

  // 손님 / 침입자
  static const customerAura = Color(0xFFFFD86E);
  static const intruderAura = Color(0xFF8C4ABB);

  // 등급 색상 (조수/광물)
  static const tierCommon = Color(0xFFB6B6B6);
  static const tierRare = Color(0xFF5DA8FF);
  static const tierEpic = Color(0xFFB875FF);
  static const tierLegendary = Color(0xFFFFC847);
  static const tierMythic = Color(0xFFFF6B9D);

  /// 광맥 깊이에 따른 배경 그라데이션 컬러 페어
  static List<Color> layerGradient(int layer) {
    switch (layer) {
      case 1:
        return [layer1Top, layer1Bottom];
      case 2:
        return [layer2Top, layer2Bottom];
      case 3:
        return [layer3Top, layer3Bottom];
      case 4:
        return [layer4Top, layer4Bottom];
      case 5:
        return [layer5Top, layer5Bottom];
      default:
        return [layer1Top, layer1Bottom];
    }
  }
}
