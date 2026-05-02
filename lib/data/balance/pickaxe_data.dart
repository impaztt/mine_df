import '../models/pickaxe.dart';

/// 곡괭이 시스템 밸런싱.
///
/// 디자인 목표:
/// - 검키우기류 클리커보다 약간 더 도전적인 곡선
/// - 비용은 1.25~1.35배 등비 증가 → 광석 가치 증가율(~4.5x/등급)보다
///   빠르게 누적되어 후반에 자연스러운 벽이 생김
/// - 데미지 레벨은 광석 캐는 양을 직접 결정 → 가장 즉각적인 보상
/// - 속도는 후반에 가성비가 더 좋아지도록 비용을 더 가파르게 책정
class PickaxeBalance {
  PickaxeBalance._();

  /// 한 번 곡괭이질에 캐는 광석 수.
  /// 시작 1, Lv4까지 +1씩 → 그 이후 매 레벨 ×1.32 (지수)
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

  /// 데미지 레벨업 비용 (코인). Lv1→2 = 50, 매 레벨 ×1.25.
  static double damageUpgradeCost(int currentLevel) {
    return 50 * _pow(1.25, currentLevel);
  }

  /// 곡괭이질 간격 (초). Lv1 = 1.0초, 매 레벨 ×0.93, 하한 0.20초.
  static double swingInterval(PickaxeStats s) {
    double t = 1.0;
    for (int i = 1; i < s.speedLevel; i++) {
      t *= 0.93;
    }
    return t.clamp(0.20, 1.0);
  }

  /// 속도 레벨업 비용 (코인). Lv1→2 = 200, 매 레벨 ×1.35.
  static double speedUpgradeCost(int currentLevel) {
    return 200 * _pow(1.35, currentLevel);
  }

  /// 속도 소프트 캡 (이후엔 클램프)
  static int get speedSoftCap => 35;
}

double _pow(double base, int exp) {
  double r = 1;
  for (int i = 0; i < exp; i++) {
    r *= base;
  }
  return r;
}
