import '../models/pickaxe.dart';

/// 곡괭이 시스템 밸런싱.
///
/// 30등급 4주 도달을 위해 전체적으로 비용 인상 + 성장 둔화:
/// - 곡괭이 데미지 성장 ×1.32 → ×1.20 (한 번에 캐는 광석 천천히)
/// - 곡괭이 데미지 비용 50 → 120, 곡선 ×1.25 → ×1.30
/// - 곡괭이 속도 비용 200 → 600, 곡선 ×1.35 → ×1.42
/// - 7개 항목의 비용 곡선 모두 가파르게
class PickaxeBalance {
  PickaxeBalance._();

  // ===== 곡괭이 데미지 (한 번에 캐는 광석 수) =====

  /// 1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 14 ... — Lv6까지 +1, 그 후 ×1.20
  static int orePerSwing(PickaxeStats s) {
    final lv = s.damageLevel;
    if (lv <= 0) return 0;
    if (lv <= 6) return lv;
    double r = 6;
    for (int i = 6; i < lv; i++) {
      r *= 1.20;
    }
    return r.round();
  }

  static double damageUpgradeCost(int currentLevel) {
    return 120 * _pow(1.30, currentLevel);
  }

  // ===== 곡괭이 속도 (간격, 초) =====

  /// Lv1=1.0초, 매 레벨 ×0.95, 하한 0.20초.
  /// 매 레벨 -5%로 둔화 (이전 -7%)
  static double swingInterval(PickaxeStats s) {
    double t = 1.0;
    for (int i = 1; i < s.speedLevel; i++) {
      t *= 0.95;
    }
    return t.clamp(0.20, 1.0);
  }

  static double speedUpgradeCost(int currentLevel) {
    return 600 * _pow(1.42, currentLevel);
  }

  static int get speedSoftCap => 35;

  // ===== 크리티컬 확률 강화 (Lv당 +0.5%) =====

  static int get critChanceCap => 50;
  static double critChanceBonus(int level) => 0.5 * level;

  static double critChanceUpgradeCost(int currentLevel) {
    return 2500 * _pow(1.35, currentLevel);
  }

  // ===== 크리티컬 위력 강화 (Lv당 +0.2배) =====

  static int get critPowerCap => 25;
  static double critPowerBonus(int level) => 0.2 * level;

  static double critPowerUpgradeCost(int currentLevel) {
    return 12000 * _pow(1.45, currentLevel);
  }

  // ===== 광석 제련 (환전 시 코인 +%) =====

  static int get smeltCap => 100;
  static double smeltBonus(int level) => 0.01 * level;

  static double smeltUpgradeCost(int currentLevel) {
    return 2000 * _pow(1.32, currentLevel);
  }

  // ===== 연쇄 채굴 (Lv당 +0.5% 확률, 캡 25%) =====

  static int get chainMineCap => 50;
  static double chainMineProb(int level) => 0.5 * level;

  static double chainMineUpgradeCost(int currentLevel) {
    return 8000 * _pow(1.50, currentLevel);
  }

  static int get chainMineMaxDepth => 5;

  // ===== 별의 운 (광석 신규 발견 시 보석 +N) =====

  static int get luckCap => 7;
  static int luckGemBonus(int level) => level;

  static double luckUpgradeCost(int currentLevel) {
    return 5000 * _pow(1.55, currentLevel);
  }
}

double _pow(double base, int exp) {
  double r = 1;
  for (int i = 0; i < exp; i++) {
    r *= base;
  }
  return r;
}
