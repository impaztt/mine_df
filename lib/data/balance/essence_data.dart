import 'dart:math' as math;

/// 광맥 정수 강화 — 단일 광맥에 +0~+50까지 강화.
///
/// 검클리커의 메인 검 강화를 그대로 차용.
/// 성공률 / 비용 / 실패 시 강등 패턴이 같음.
class EssenceCost {
  final int targetStage;
  final double coinCost;
  final double successRate; // 0..1
  final int penaltyOnFail;
  const EssenceCost({
    required this.targetStage,
    required this.coinCost,
    required this.successRate,
    required this.penaltyOnFail,
  });
}

const int kEssenceMaxStage = 50;

EssenceCost essenceCostFor(int targetStage) {
  final s = targetStage.clamp(1, kEssenceMaxStage);
  // 코인 곡선 — 1M × 1.7^(s-1)
  final coin = 1e6 * math.pow(1.7, s - 1).toDouble();

  // 성공률 — 96% → 1% 선형 감소 (50단계 기준)
  final success = math.max(0.01, 0.96 - (s - 1) * 0.0192);

  // 강등 페널티
  int penalty;
  if (s <= 5) {
    penalty = 0;
  } else if (s <= 25) {
    penalty = 1;
  } else if (s <= 40) {
    penalty = 2;
  } else {
    penalty = 3;
  }

  return EssenceCost(
    targetStage: s,
    coinCost: coin,
    successRate: success,
    penaltyOnFail: penalty,
  );
}

/// 보석으로 살 수 있는 일회용 부스트
enum EssenceBoost {
  none,
  small, // +10%p
  medium, // +25%p
  large, // +50%p
}

extension EssenceBoostInfo on EssenceBoost {
  int get gemCost => switch (this) {
        EssenceBoost.none => 0,
        EssenceBoost.small => 5,
        EssenceBoost.medium => 25,
        EssenceBoost.large => 80,
      };

  double get successBonus => switch (this) {
        EssenceBoost.none => 0,
        EssenceBoost.small => 0.10,
        EssenceBoost.medium => 0.25,
        EssenceBoost.large => 0.50,
      };

  String get label => switch (this) {
        EssenceBoost.none => '부스트 없음',
        EssenceBoost.small => '소 +10%',
        EssenceBoost.medium => '중 +25%',
        EssenceBoost.large => '대 +50%',
      };
}

/// 보호권 — 실패해도 강등 없음
const int kEssenceProtectionGemCost = 50;

/// 정수 강화 단계의 채굴량 배수
double essenceStageMultiplier(int stage) {
  if (stage <= 0) return 1.0;
  return 1.0 + stage * 0.20;
}
