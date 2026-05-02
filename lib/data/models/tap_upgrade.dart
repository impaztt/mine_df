import 'package:flutter/material.dart';

/// 탭당 광석 +N 영구 누적 강화.
class TapUpgradeDef {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color accent;

  /// Lv1 비용
  final double baseCost;

  /// 레벨당 추가되는 탭 광석 수
  final double tapOrePerLevel;

  const TapUpgradeDef({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.accent,
    required this.baseCost,
    required this.tapOrePerLevel,
  });
}
