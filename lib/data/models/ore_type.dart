import 'package:flutter/material.dart';
import 'tier.dart';

/// 발사용 광물 정의 (정적 데이터)
class OreDef {
  final String id;
  final String name;
  final String emoji;
  final Tier tier;
  final Color color;
  final int unlockDay;
  final String description;

  /// 데미지 배수 (기본 광물=1.0)
  final double damageMul;

  const OreDef({
    required this.id,
    required this.name,
    required this.emoji,
    required this.tier,
    required this.color,
    required this.unlockDay,
    required this.description,
    this.damageMul = 1.0,
  });
}
