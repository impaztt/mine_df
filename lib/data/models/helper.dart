import 'package:flutter/material.dart';
import 'tier.dart';

/// 조수 정의 (정적 데이터)
class HelperDef {
  final String id;
  final String name;
  final String emoji;
  final Tier tier;
  final String description;

  /// Lv1 기준 추가 발사 데미지 비율 (1.0 = 100%)
  final double baseDamageMul;

  /// Lv1 기준 발사 속도 보너스 (초당 추가 발사)
  final double baseFireRateBonus;

  /// 영입 비용 (코인)
  final double recruitCost;

  /// 레벨업 비용 (코인)
  final double upgradeCost;

  const HelperDef({
    required this.id,
    required this.name,
    required this.emoji,
    required this.tier,
    required this.description,
    required this.baseDamageMul,
    required this.baseFireRateBonus,
    required this.recruitCost,
    required this.upgradeCost,
  });

  Color get color => tier.color;
}

class HelperState {
  final String id;
  final bool recruited;
  final int level;

  const HelperState({
    required this.id,
    this.recruited = false,
    this.level = 0,
  });

  HelperState copyWith({bool? recruited, int? level}) => HelperState(
        id: id,
        recruited: recruited ?? this.recruited,
        level: level ?? this.level,
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'recruited': recruited, 'level': level};

  factory HelperState.fromJson(Map<String, dynamic> j) => HelperState(
        id: j['id'] as String,
        recruited: j['recruited'] as bool? ?? false,
        level: j['level'] as int? ?? 0,
      );
}
