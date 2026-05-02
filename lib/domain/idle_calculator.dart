import '../core/constants/game_constants.dart';
import '../data/balance/helper_data.dart';
import '../data/balance/ore_data.dart';
import '../data/balance/pickaxe_data.dart';
import '../data/models/game_state.dart';

/// 자동 채굴 / 오프라인 보상 계산기
class IdleCalculator {
  /// 1초당 자동 채굴되는 광석 개수
  static double oresPerSecond(GameState state) {
    final interval = PickaxeBalance.swingInterval(state.pickaxe);
    final perSwing = PickaxeBalance.orePerSwing(state.pickaxe).toDouble();
    final speedBonus = _speedBonus(state);
    final dmgBonus = _damageBonus(state);
    final swingsPerSec = (1 / interval) * (1 + speedBonus);
    return swingsPerSec * perSwing * (1 + dmgBonus);
  }

  /// 1초당 자동으로 들어오는 코인 (자동 환전 가정)
  static double coinPerSecond(GameState state) {
    final ore = oreByRank(state.mineRank);
    return oresPerSecond(state) * ore.coinValue * (1 + _sellBonus(state));
  }

  /// 오프라인 동안 누적된 코인
  static double offlineCoinReward(GameState state, DateTime now) {
    if (state.lastSavedAt == 0) return 0;
    final elapsed = now.millisecondsSinceEpoch - state.lastSavedAt;
    if (elapsed <= 0) return 0;
    final cappedMs =
        elapsed.clamp(0, GameConstants.offlineCap.inMilliseconds);
    final seconds = cappedMs / 1000.0;
    return coinPerSecond(state) * seconds;
  }

  static double _damageBonus(GameState state) {
    double bonus = 0;
    for (final h in state.helpers.values) {
      if (!h.recruited) continue;
      final def = helperById(h.id);
      bonus += helperDamageMul(def, h.level);
    }
    return bonus;
  }

  static double _speedBonus(GameState state) {
    double bonus = 0;
    for (final h in state.helpers.values) {
      if (!h.recruited) continue;
      final def = helperById(h.id);
      bonus += helperFireBonus(def, h.level);
    }
    return bonus;
  }

  /// 환전율 보너스 (rabbit_dali가 영입돼있으면 +)
  static double _sellBonus(GameState state) {
    final dali = state.helpers['rabbit_dali'];
    if (dali == null || !dali.recruited) return 0;
    return 0.04 * dali.level;
  }
}
