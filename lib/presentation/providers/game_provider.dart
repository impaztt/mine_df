import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/game_constants.dart';
import '../../data/balance/facility_data.dart';
import '../../data/balance/helper_data.dart';
import '../../data/balance/ore_data.dart';
import '../../data/models/enemy_type.dart';
import '../../data/models/facility.dart';
import '../../data/models/game_state.dart';
import '../../data/models/helper.dart';
import '../../data/repositories/save_repository.dart';
import '../../domain/idle_calculator.dart';

/// 게임 액션의 결과 — UI 피드백용
class ActionResult {
  final bool ok;
  final String? message;
  const ActionResult({required this.ok, this.message});

  static const success = ActionResult(ok: true);
  factory ActionResult.fail(String m) => ActionResult(ok: false, message: m);
}

/// 산신령 보너스 이벤트 정보
class SpiritBonus {
  final String id;
  final double oreBonus;
  final double coinBonus;
  SpiritBonus({
    required this.id,
    required this.oreBonus,
    required this.coinBonus,
  });
}

class GameProvider extends ChangeNotifier {
  GameProvider(this._repo);
  final SaveRepository _repo;

  GameState _state = GameState.initial();
  GameState get state => _state;

  bool _initialized = false;
  bool get initialized => _initialized;

  /// 시작 시 누적된 오프라인 보상 (UI에서 한 번 표시)
  double pendingOfflineOre = 0;

  /// 활성 산신령 (탭 가능)
  SpiritBonus? activeSpirit;
  Timer? _spiritTimer;

  /// 게임 틱 타이머 (자동 채굴)
  Timer? _tickTimer;
  DateTime _lastTick = DateTime.now();

  // === 초기화 / 종료 ===

  Future<void> initialize() async {
    final loaded = await _repo.load();
    final now = DateTime.now();
    pendingOfflineOre = IdleCalculator.offlineOreReward(loaded, now);
    _state = loaded.copyWith(
      ore: loaded.ore + pendingOfflineOre,
      lastSavedAt: now.millisecondsSinceEpoch,
    );
    _initialized = true;
    _startTick();
    _scheduleSpirit();
    notifyListeners();
    await _repo.save(_state);
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _spiritTimer?.cancel();
    super.dispose();
  }

  Future<void> persist() async {
    _state = _state.copyWith(
      lastSavedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _repo.save(_state);
  }

  // === 게임 틱 ===

  void _startTick() {
    _tickTimer?.cancel();
    _lastTick = DateTime.now();
    _tickTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      final now = DateTime.now();
      final dt = now.difference(_lastTick).inMilliseconds / 1000.0;
      _lastTick = now;
      _tick(dt);
    });
  }

  /// 자동 채굴 적용
  void _tick(double dt) {
    final rate = IdleCalculator.oreRatePerSecond(_state);
    if (rate <= 0) return;
    _state = _state.copyWith(ore: _state.ore + rate * dt);
    notifyListeners();
  }

  // === 광물 / 코인 (전투 시스템에서 호출) ===

  /// 발사체가 적에게 피해를 줄 때, 광물을 소모하지는 않음 (광물은 자동 채굴됨)
  /// 단 데미지는 현재 장착 광물 + 조수 강화에 의해 결정됨
  double currentDamage() {
    final ore = oreForDay(_state.day) ?? kOres.first;
    double base = ore.damageMul *
        (1 + math.log(_state.ore + 10) / math.ln10 * 0.1);
    // 조수 데미지 합산
    for (final h in _state.helpers.values) {
      if (!h.recruited) continue;
      final def = helperById(h.id);
      base *= (1 + helperDamageMul(def, h.level));
    }
    return base.clamp(1.0, double.infinity);
  }

  double currentFireRate() {
    double rate = GameConstants.baseFireRate;
    for (final h in _state.helpers.values) {
      if (!h.recruited) continue;
      final def = helperById(h.id);
      rate += helperFireBonus(def, h.level);
    }
    return rate;
  }

  double currentEnemyHp(EnemyDef def, {bool isBoss = false}) {
    final base = GameConstants.baseEnemyHp *
        math.pow(GameConstants.enemyHpGrowth, _state.day - 1);
    final mul = isBoss ? GameConstants.bossHpMultiplier : 1.0;
    return base * def.hpMul * mul;
  }

  double currentCoinReward(EnemyDef def) {
    final base = GameConstants.baseCoinReward *
        math.pow(GameConstants.coinGrowth, _state.day - 1);
    return base * def.coinMul;
  }

  /// 적 처치 시 호출 — 손님이면 보너스, 침입자면 코인만
  void onEnemyKilled(EnemyDef def) {
    final coin = currentCoinReward(def);
    double coinGain = coin;
    // 토끼 달이가 영입된 경우 코인 +20%
    final dali = _state.helpers['rabbit_dali'];
    if (dali != null && dali.recruited) {
      coinGain *= 1.20;
    }
    _state = _state.copyWith(
      coin: _state.coin + coinGain,
      dayKills: def.kind == EnemyKind.boss
          ? _state.dayKills
          : _state.dayKills + 1,
    );

    if (def.kind == EnemyKind.boss) {
      // 보스 처치 → DAY 클리어
      _advanceDay();
    } else {
      _checkDayProgress();
    }
    notifyListeners();
  }

  /// 적이 광산에 도달함
  void onEnemyReachedMine(EnemyDef def) {
    switch (def.kind) {
      case EnemyKind.customer:
        // 손님은 도달해도 페널티 없음 (단, 보상도 없음)
        // 다음 적 카운트만 증가시켜 DAY 진행이 막히지 않게
        _state = _state.copyWith(dayKills: _state.dayKills + 1);
        _checkDayProgress();
        break;
      case EnemyKind.intruder:
        // 광물 약탈 (5초치) + 광산 체력 -1
        final loss = IdleCalculator.oreRatePerSecond(_state) * 5;
        final newHp = (_state.mineHp - 1).clamp(0, 5);
        _state = _state.copyWith(
          ore: math.max(0, _state.ore - loss),
          mineHp: newHp,
          dayKills: _state.dayKills + 1,
        );
        if (newHp <= 0) {
          // DAY 실패 — DAY 유지 + 체력 회복
          _state = _state.copyWith(mineHp: 5, dayKills: 0, bossPhase: false);
        } else {
          _checkDayProgress();
        }
        break;
      case EnemyKind.boss:
        // 보스가 광산에 도달 — 페널티 크게
        _state = _state.copyWith(
          mineHp: (_state.mineHp - 2).clamp(0, 5),
        );
        if (_state.mineHp <= 0) {
          _state = _state.copyWith(mineHp: 5, dayKills: 0, bossPhase: false);
        }
        break;
    }
    notifyListeners();
  }

  void _checkDayProgress() {
    final required = GameConstants.enemiesPerDay(_state.day);
    if (_state.dayKills >= required && !_state.bossPhase) {
      // 보스 등장 조건? — 10 DAY 마다
      if (_state.day % GameConstants.bossDayInterval == 0) {
        _state = _state.copyWith(bossPhase: true);
      } else {
        _advanceDay();
      }
    }
  }

  void _advanceDay() {
    final newDay = _state.day + 1;
    int newLayer = _state.layer;
    if (newDay > 1 &&
        (newDay - 1) % GameConstants.depthLayerInterval == 0 &&
        newLayer < GameConstants.maxLayer) {
      newLayer = newLayer + 1;
    }
    _state = _state.copyWith(
      day: newDay,
      dayKills: 0,
      bossPhase: false,
      mineHp: 5, // DAY 클리어 시 광산 체력 회복
      layer: newLayer,
    );
    persist();
  }

  // === 시설 / 조수 액션 ===

  ActionResult buyOrUpgradeFacility(String id) {
    final def = facilityById(id);
    if (_state.day < def.unlockDay) {
      return ActionResult.fail('DAY ${def.unlockDay} 부터 해금됩니다');
    }
    final cur = _state.facilities[id];
    final level = cur?.level ?? 0;
    final cost = facilityUpgradeCost(def, level);
    if (_state.coin < cost) {
      return ActionResult.fail('코인이 부족합니다');
    }
    final next = FacilityState(id: id, level: level + 1);
    final newMap = Map<String, FacilityState>.from(_state.facilities);
    newMap[id] = next;
    _state = _state.copyWith(
      coin: _state.coin - cost,
      facilities: newMap,
    );
    notifyListeners();
    return ActionResult.success;
  }

  ActionResult recruitOrUpgradeHelper(String id) {
    final def = helperById(id);
    final cur = _state.helpers[id];
    final newMap = Map<String, HelperState>.from(_state.helpers);

    if (cur == null || !cur.recruited) {
      // 영입
      if (_state.coin < def.recruitCost) {
        return ActionResult.fail('코인이 부족합니다');
      }
      newMap[id] = HelperState(id: id, recruited: true, level: 1);
      _state = _state.copyWith(
        coin: _state.coin - def.recruitCost,
        helpers: newMap,
      );
    } else {
      // 강화
      final cost = helperUpgradeCost(def, cur.level);
      if (_state.coin < cost) {
        return ActionResult.fail('코인이 부족합니다');
      }
      newMap[id] = cur.copyWith(level: cur.level + 1);
      _state = _state.copyWith(
        coin: _state.coin - cost,
        helpers: newMap,
      );
    }
    notifyListeners();
    return ActionResult.success;
  }

  /// 광물 장착 변경
  void equipOre(String oreId) {
    final ore = kOres.firstWhere(
      (o) => o.id == oreId,
      orElse: () => kOres.first,
    );
    if (_state.day < ore.unlockDay) return;
    _state = _state.copyWith(equippedOreId: oreId);
    notifyListeners();
  }

  // === 산신령 (보너스 이벤트) ===

  void _scheduleSpirit() {
    _spiritTimer?.cancel();
    final rng = math.Random();
    final minS = GameConstants.spiritMinInterval.inSeconds;
    final maxS = GameConstants.spiritMaxInterval.inSeconds;
    final sec = minS + rng.nextInt(maxS - minS + 1);
    _spiritTimer = Timer(Duration(seconds: sec), _spawnSpirit);
  }

  void _spawnSpirit() {
    final rate = IdleCalculator.oreRatePerSecond(_state);
    activeSpirit = SpiritBonus(
      id: 'spirit_${DateTime.now().millisecondsSinceEpoch}',
      oreBonus: rate * GameConstants.spiritRewardMultiplier,
      coinBonus: 50.0 *
          math.pow(GameConstants.coinGrowth, _state.day - 1).toDouble(),
    );
    notifyListeners();
    // 15초 후 자동 사라짐
    Timer(const Duration(seconds: 15), () {
      if (activeSpirit?.id == activeSpirit?.id) {
        activeSpirit = null;
        notifyListeners();
        _scheduleSpirit();
      }
    });
  }

  void claimSpirit({double multiplier = 1.0}) {
    final s = activeSpirit;
    if (s == null) return;
    _state = _state.copyWith(
      ore: _state.ore + s.oreBonus * multiplier,
      coin: _state.coin + s.coinBonus * multiplier,
    );
    activeSpirit = null;
    notifyListeners();
    _scheduleSpirit();
  }

  // === 디버그 / 리셋 ===

  Future<void> hardReset() async {
    await _repo.clear();
    _state = GameState.initial();
    notifyListeners();
  }
}

/// SaveRepository 싱글톤
final saveRepositoryProvider =
    Provider<SaveRepository>((ref) => SaveRepository());

/// GameProvider — 전역 상태
final gameProvider = ChangeNotifierProvider<GameProvider>((ref) {
  final repo = ref.watch(saveRepositoryProvider);
  final p = GameProvider(repo);
  // 자동 저장 주기 (10초)
  Timer.periodic(const Duration(seconds: 10), (_) {
    if (p.initialized) p.persist();
  });
  ref.onDispose(() {
    if (p.initialized) p.persist();
  });
  return p;
});
