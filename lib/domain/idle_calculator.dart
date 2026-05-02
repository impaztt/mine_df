import '../core/constants/game_constants.dart';
import '../data/balance/essence_data.dart';
import '../data/balance/helper_data.dart';
import '../data/balance/ore_data.dart';
import '../data/balance/pickaxe_data.dart';
import '../data/balance/prestige_data.dart';
import '../data/balance/producer_data.dart';
import '../data/balance/tap_upgrade_data.dart';
import '../data/models/game_state.dart';

/// 자동 채굴 / 오프라인 / 탭 정산을 담당하는 순수 계산 모음.
class IdleCalculator {
  IdleCalculator._();

  // ===== 보너스 합산 =====

  static double _helperDamageBonus(GameState s) {
    double b = 0;
    for (final h in s.helpers.values) {
      if (!h.recruited) continue;
      final def = helperById(h.id);
      b += helperDamageMul(def, h.level);
    }
    return b;
  }

  static double _helperSpeedBonus(GameState s) {
    double b = 0;
    for (final h in s.helpers.values) {
      if (!h.recruited) continue;
      final def = helperById(h.id);
      b += helperFireBonus(def, h.level);
    }
    return b;
  }

  static double sellBonus(GameState s) {
    double b = PickaxeBalance.smeltBonus(s.pickaxe.smeltLevel);
    final dali = s.helpers['rabbit_dali'];
    if (dali != null && dali.recruited) {
      b += 0.04 * dali.level;
    }
    return b;
  }

  static double globalMultiplier(GameState s) {
    final essence = essenceStageMultiplier(s.essenceStage);
    final prestigeGlobal = 1 + prestigeGlobalBonus(s.prestigeLevels);
    return essence * prestigeGlobal;
  }

  // ===== 탭 광석 =====

  /// 한 번 탭 시 즉시 캐는 광석 수 (보너스 모두 반영).
  static double tapOrePerHit(GameState s) {
    // 베이스: 곡괭이 데미지 + 모든 탭 강화 합산
    double base =
        PickaxeBalance.orePerSwing(s.pickaxe).toDouble();
    for (final entry in s.tapUpgrades.entries) {
      final def = tapUpgradeById(entry.key);
      base += def.tapOrePerLevel * entry.value;
    }

    // 조수 데미지 보너스
    base *= 1 + _helperDamageBonus(s);

    // 환생 트리 — 탭 / 글로벌
    base *= 1 + prestigeTapBonus(s.prestigeLevels);
    base *= globalMultiplier(s);

    return base;
  }

  // ===== 자동 채굴 =====

  /// 광부 한 명이 내는 광석/초 (해당 광부의 레벨 기준)
  static double producerOrePerSec(GameState s, String id) {
    final p = s.producers[id];
    if (p == null || p.level <= 0) return 0;
    final def = producerById(id);
    return ProducerBalance.orePerSec(def, p.level);
  }

  /// 모든 광부 합산 광석/초 (광부 자체 보너스만, 글로벌 보너스 X)
  static double producersOrePerSecRaw(GameState s) {
    double total = 0;
    for (final p in s.producers.values) {
      if (p.level <= 0) continue;
      final def = producerById(p.id);
      total += ProducerBalance.orePerSec(def, p.level);
    }
    return total;
  }

  /// 1초당 자동 채굴되는 광석 수 (모든 보너스 반영)
  static double oresPerSecond(GameState s) {
    double rate = producersOrePerSecRaw(s);

    // 곡괭이 자체 자동 채굴 (속도 + 데미지 기반) — 기존 호환
    final swingInterval = PickaxeBalance.swingInterval(s.pickaxe) /
        (1 + _helperSpeedBonus(s));
    final swingsPerSec = swingInterval > 0 ? 1 / swingInterval : 0;
    final orePerSwing =
        PickaxeBalance.orePerSwing(s.pickaxe).toDouble() *
            (1 + _helperDamageBonus(s));
    rate += swingsPerSec * orePerSwing;

    // 환생 트리 — 자동 / 글로벌
    rate *= 1 + prestigeAutoBonus(s.prestigeLevels);
    rate *= globalMultiplier(s);

    return rate;
  }

  /// 1초당 자동으로 들어오는 코인 (자동 환전 가정)
  static double coinPerSecond(GameState s) {
    final ore = oreByRank(s.mineRank);
    return oresPerSecond(s) * ore.coinValue * (1 + sellBonus(s));
  }

  /// 오프라인 동안 누적된 코인
  static double offlineCoinReward(GameState s, DateTime now) {
    if (s.lastSavedAt == 0) return 0;
    final elapsed = now.millisecondsSinceEpoch - s.lastSavedAt;
    if (elapsed <= 0) return 0;
    final cappedMs =
        elapsed.clamp(0, GameConstants.offlineCap.inMilliseconds);
    final seconds = cappedMs / 1000.0;
    return coinPerSecond(s) * seconds;
  }
}
