import '../models/pickaxe.dart';

/// 곡괭이 시스템 밸런싱

class PickaxeBalance {
  PickaxeBalance._();

  /// 데미지 레벨 1 기준 광석 수 (= 1)
  static int orePerSwing(PickaxeStats s) {
    // 1, 2, 3, 5, 8, 12, 18, 27, 41 ... (Lv별 ~1.5배 곡선, 단 시작은 +1씩)
    final lv = s.damageLevel;
    if (lv <= 4) return lv;
    double r = 4;
    for (int i = 4; i < lv; i++) {
      r *= 1.45;
    }
    return r.round();
  }

  /// 데미지 레벨업 비용 (코인)
  static double damageUpgradeCost(int currentLevel) {
    return 12 * _pow(1.18, currentLevel);
  }

  /// 곡괭이 속도 — 1회 곡괭이질 사이의 간격 (초)
  /// Lv1 = 1.0초, 매 레벨 -7%, 최소 0.18초
  static double swingInterval(PickaxeStats s) {
    double t = 1.0;
    for (int i = 1; i < s.speedLevel; i++) {
      t *= 0.93;
    }
    return t.clamp(0.18, 1.0);
  }

  /// 속도 레벨업 비용 (코인)
  static double speedUpgradeCost(int currentLevel) {
    return 30 * _pow(1.22, currentLevel);
  }

  /// 속도 레벨이 의미가 있는 마지막 레벨 (이후엔 클램프됨)
  static int get speedSoftCap => 30;
}

double _pow(double base, int exp) {
  double r = 1;
  for (int i = 0; i < exp; i++) {
    r *= base;
  }
  return r;
}
