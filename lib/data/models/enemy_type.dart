import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// 적의 두 가지 유형 — 손님 vs 침입자
enum EnemyKind {
  customer, // 손님 — 광산 도달 전 처치하면 코인 +평판 / 도달하면 그냥 사라짐
  intruder, // 침입자 — 광산 도달 시 페널티 (광물 약탈 / 체력 -1)
  boss, // 보스 — DAY 끝
}

class EnemyDef {
  final String id;
  final String name;
  final String emoji;
  final EnemyKind kind;

  /// 체력 배수 (DAY별 base에 곱하기)
  final double hpMul;

  /// 코인 배수
  final double coinMul;

  /// 이동 속도 배수
  final double speedMul;

  const EnemyDef({
    required this.id,
    required this.name,
    required this.emoji,
    required this.kind,
    this.hpMul = 1.0,
    this.coinMul = 1.0,
    this.speedMul = 1.0,
  });

  Color get auraColor => kind == EnemyKind.customer
      ? AppColors.customerAura
      : AppColors.intruderAura;
}
