import '../core/constants/game_constants.dart';
import '../data/balance/facility_data.dart';
import '../data/models/game_state.dart';

/// 오프라인 / 자동 채굴 계산기
class IdleCalculator {
  /// 게임 상태의 초당 광물 채굴량 (모든 시설 합산)
  static double oreRatePerSecond(GameState state) {
    double total = 0;
    for (final entry in state.facilities.entries) {
      final def = facilityById(entry.key);
      total += facilityRate(def, entry.value.level);
    }
    return total;
  }

  /// 오프라인 동안 누적된 광물 (캡 적용)
  static double offlineOreReward(GameState state, DateTime now) {
    if (state.lastSavedAt == 0) return 0;
    final elapsed = now.millisecondsSinceEpoch - state.lastSavedAt;
    if (elapsed <= 0) return 0;

    final cappedMs = elapsed.clamp(0, GameConstants.offlineCap.inMilliseconds);
    final seconds = cappedMs / 1000.0;
    return oreRatePerSecond(state) * seconds;
  }
}
