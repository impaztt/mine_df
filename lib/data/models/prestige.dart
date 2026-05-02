import 'package:flutter/material.dart';

/// 환생(별의 의식) 영구 트리 노드.
class PrestigeNodeDef {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color accent;
  final double baseCost; // 별의 결정
  final double growthRate; // 매 레벨 비용 ×
  final int maxLevel;

  /// 트리별 효과 — 각 노드는 한 가지 카테고리에만 영향.
  final double tapBonusPerLevel; // 탭 광석 +N%
  final double autoBonusPerLevel; // 자동 광석 +N%
  final double globalBonusPerLevel; // 전체 광석 +N%
  final double stardustGainBonusPerLevel; // 환생 별의 결정 +N%

  const PrestigeNodeDef({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.accent,
    required this.baseCost,
    required this.growthRate,
    required this.maxLevel,
    this.tapBonusPerLevel = 0,
    this.autoBonusPerLevel = 0,
    this.globalBonusPerLevel = 0,
    this.stardustGainBonusPerLevel = 0,
  });
}
