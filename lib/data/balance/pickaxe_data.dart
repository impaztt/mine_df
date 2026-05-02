import '../models/pickaxe.dart';

/// 곡괭이 시스템 밸런싱.
///
/// 디자인:
/// - 검키우기류 클리커보다 약간 더 도전적인 곡선
/// - 비용은 모두 등비 증가 → 광석 가치 증가율(~4.5x/등급)보다 빨라
///   후반에 자연스러운 벽
/// - 새 항목들은 모두 소프트 캡이 있어 한 가지에 무한 투자할 수 없게 함
class PickaxeBalance {
  PickaxeBalance._();

  // ===== 곡괭이 데미지 (한 번에 캐는 광석 수) =====

  static int orePerSwing(PickaxeStats s) {
    final lv = s.damageLevel;
    if (lv <= 0) return 0;
    if (lv <= 4) return lv;
    double r = 4;
    for (int i = 4; i < lv; i++) {
      r *= 1.32;
    }
    return r.round();
  }

  static double damageUpgradeCost(int currentLevel) {
    return 50 * _pow(1.25, currentLevel);
  }

  // ===== 곡괭이 속도 (간격, 초) =====

  static double swingInterval(PickaxeStats s) {
    double t = 1.0;
    for (int i = 1; i < s.speedLevel; i++) {
      t *= 0.93;
    }
    return t.clamp(0.20, 1.0);
  }

  static double speedUpgradeCost(int currentLevel) {
    return 200 * _pow(1.35, currentLevel);
  }

  static int get speedSoftCap => 35;

  // ===== 크리티컬 확률 강화 (Lv당 +0.5%) =====

  /// 캡 50 Lv → 기본 3% + 25% = 최대 28% (까치 영입 시 추가)
  static int get critChanceCap => 50;

  static double critChanceBonus(int level) => 0.5 * level;

  static double critChanceUpgradeCost(int currentLevel) {
    return 1000 * _pow(1.30, currentLevel);
  }

  // ===== 크리티컬 위력 강화 (Lv당 +0.2배) =====

  /// 캡 25 Lv → 기본 ×3 + 5 = 최대 ×8
  static int get critPowerCap => 25;

  static double critPowerBonus(int level) => 0.2 * level;

  static double critPowerUpgradeCost(int currentLevel) {
    return 5000 * _pow(1.40, currentLevel);
  }

  // ===== 광석 제련 (환전 시 코인 +%) =====

  /// 캡 100 Lv → +100% (즉 환전 가치 ×2)
  static int get smeltCap => 100;

  /// 비율 (0.01 = 1%)
  static double smeltBonus(int level) => 0.01 * level;

  static double smeltUpgradeCost(int currentLevel) {
    return 800 * _pow(1.28, currentLevel);
  }

  // ===== 연쇄 채굴 (Lv당 +0.5% 확률, 캡 25%) =====

  /// 캡 50 Lv → 25%
  static int get chainMineCap => 50;

  /// 퍼센트 단위 (0.5 = 0.5%)
  static double chainMineProb(int level) => 0.5 * level;

  static double chainMineUpgradeCost(int currentLevel) {
    return 3000 * _pow(1.45, currentLevel);
  }

  /// 한 번 곡괭이질에서 최대 몇 번까지 연쇄될 수 있는가
  static int get chainMineMaxDepth => 5;

  // ===== 별의 운 (광석 신규 발견 시 보석 +N) =====

  /// 캡 7 Lv → +7 (기본 +3 더해 최대 +10 보석)
  static int get luckCap => 7;

  static int luckGemBonus(int level) => level;

  static double luckUpgradeCost(int currentLevel) {
    return 2000 * _pow(1.50, currentLevel);
  }
}

double _pow(double base, int exp) {
  double r = 1;
  for (int i = 0; i < exp; i++) {
    r *= base;
  }
  return r;
}
