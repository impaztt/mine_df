import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/game_constants.dart';
import '../../data/balance/helper_data.dart';
import '../../data/balance/ore_data.dart';
import '../../data/balance/pickaxe_data.dart';
import '../../data/models/game_state.dart';
import '../../data/models/helper.dart';
import '../../data/repositories/save_repository.dart';
import '../../domain/idle_calculator.dart';

/// 게임 액션의 결과
class ActionResult {
  final bool ok;
  final String? message;
  const ActionResult({required this.ok, this.message});

  static const success = ActionResult(ok: true);
  factory ActionResult.fail(String m) => ActionResult(ok: false, message: m);
}

/// 산신령 보너스 이벤트
class SpiritBonus {
  final String id;
  final double coinBonus;
  SpiritBonus({required this.id, required this.coinBonus});
}

/// 채굴 1회 결과 — UI에서 짧은 피드백(콤보, 크리티컬 표시)에 사용
class MineHit {
  final int oreAmount;
  final bool isCritical;
  final int comboCount;
  final double coinGained;

  MineHit({
    required this.oreAmount,
    required this.isCritical,
    required this.comboCount,
    required this.coinGained,
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
  double pendingOfflineCoin = 0;

  /// 활성 산신령
  SpiritBonus? activeSpirit;
  Timer? _spiritTimer;

  /// 자동 채굴 타이머
  Timer? _autoMineTimer;

  /// 가장 최근 채굴 시각 (콤보 윈도우 계산용)
  DateTime? _lastSwingAt;

  /// 탭 가속 쿨다운 종료 시각
  DateTime _tapCooldownUntil = DateTime.fromMillisecondsSinceEpoch(0);

  /// 현재 콤보 카운트
  int _combo = 0;
  int get combo => _combo;

  /// 가장 최근 채굴 정보 (UI 피드백)
  MineHit? lastHit;

  /// 호랑이 범 — 마지막 강타 시각
  DateTime _lastTigerStrikeAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// notifyListeners 빈도 제한 (1Hz UI 갱신)
  int _tickCounter = 0;

  // === 초기화 / 종료 ===

  Future<void> initialize() async {
    final loaded = await _repo.load();
    final now = DateTime.now();
    pendingOfflineCoin = IdleCalculator.offlineCoinReward(loaded, now);
    _state = loaded.copyWith(
      coin: loaded.coin + pendingOfflineCoin,
      lastSavedAt: now.millisecondsSinceEpoch,
    );
    _initialized = true;
    _startAutoMine();
    _scheduleSpirit();
    notifyListeners();
    await _repo.save(_state);
  }

  @override
  void dispose() {
    _autoMineTimer?.cancel();
    _spiritTimer?.cancel();
    super.dispose();
  }

  Future<void> persist() async {
    _state = _state.copyWith(
      lastSavedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _repo.save(_state);
  }

  // === 자동 채굴 ===

  void _startAutoMine() {
    _autoMineTimer?.cancel();
    // 250ms 마다 검사하면서 swing interval 도달 시 채굴
    _autoMineTimer = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => _autoMineTick(),
    );
  }

  void _autoMineTick() {
    final now = DateTime.now();
    final interval = _effectiveSwingInterval();
    final lastAt = _lastSwingAt;
    if (lastAt == null ||
        now.difference(lastAt).inMilliseconds >= interval * 1000) {
      _performMine(now: now, isTap: false);
    } else {
      // 1초마다 정도 UI에 갱신 알림 (콤보 만료, 등)
      _tickCounter++;
      if (_tickCounter >= 5) {
        _tickCounter = 0;
        _maybeExpireCombo(now);
        notifyListeners();
      }
    }
  }

  void _maybeExpireCombo(DateTime now) {
    final lastAt = _lastSwingAt;
    if (lastAt == null) return;
    if (now.difference(lastAt).inMilliseconds >
        (GameConstants.comboWindow * 1000).round()) {
      if (_combo > 0) {
        _combo = 0;
      }
    }
  }

  // === 채굴 액션 ===

  /// 화면 탭 — 즉시 추가 곡괭이질
  ActionResult tap() {
    final now = DateTime.now();
    if (now.isBefore(_tapCooldownUntil)) {
      return ActionResult.fail('잠시만!');
    }
    _tapCooldownUntil =
        now.add(Duration(milliseconds: (GameConstants.tapCooldown * 1000).round()));
    _performMine(now: now, isTap: true);
    return ActionResult.success;
  }

  void _performMine({required DateTime now, required bool isTap}) {
    final lastAt = _lastSwingAt;
    final withinCombo = lastAt != null &&
        now.difference(lastAt).inMilliseconds <=
            (GameConstants.comboWindow * 1000).round();
    _combo = withinCombo ? (_combo + 1).clamp(0, 999) : 1;
    _lastSwingAt = now;

    // 채굴 광석 수
    int amount = PickaxeBalance.orePerSwing(_state.pickaxe);
    final dmgBonus = _damageBonus();
    amount = (amount * (1 + dmgBonus)).round().clamp(1, 1 << 30);

    // 콤보 보너스 (탭일 때만 — 자동은 아주 약간만)
    final comboMul = _comboMultiplier();
    if (isTap) {
      amount = (amount * comboMul).round();
    }

    // 크리티컬
    final critChance = _critChance();
    final isCritical = _rng.nextDouble() * 100 < critChance;
    if (isCritical) {
      amount = (amount * GameConstants.critMultiplier).round();
    }

    // 호랑이 범 — 8초마다 ×10 일격
    final tiger = _state.helpers['tiger_beom'];
    if (tiger != null && tiger.recruited) {
      if (now.difference(_lastTigerStrikeAt).inSeconds >= 8) {
        _lastTigerStrikeAt = now;
        amount *= 10;
      }
    }

    // 구미호 — 일정 확률로 ×2
    final gumiho = _state.helpers['gumiho_yawol'];
    if (gumiho != null && gumiho.recruited) {
      final p = 0.015 * gumiho.level * 100; // 백분율
      if (_rng.nextDouble() * 100 < p) {
        amount *= 2;
      }
    }

    // 광석 → 코인 또는 인벤토리
    final ore = oreByRank(_state.mineRank);
    final sellBonus = _sellBonus();
    final coinGain =
        amount * ore.coinValue * (1 + sellBonus);

    final newDiscovered = _state.discoveredOres.contains(ore.id)
        ? _state.discoveredOres
        : <String>{..._state.discoveredOres, ore.id};

    if (_state.autoSell) {
      _state = _state.copyWith(
        coin: _state.coin + coinGain,
        totalSwings: _state.totalSwings + 1,
        discoveredOres: newDiscovered,
      );
    } else {
      final inv = Map<String, double>.from(_state.oreInventory);
      inv[ore.id] = (inv[ore.id] ?? 0) + amount;
      _state = _state.copyWith(
        oreInventory: inv,
        totalSwings: _state.totalSwings + 1,
        discoveredOres: newDiscovered,
      );
    }

    lastHit = MineHit(
      oreAmount: amount,
      isCritical: isCritical,
      comboCount: _combo,
      coinGained: _state.autoSell ? coinGain : 0,
    );

    notifyListeners();
  }

  double _effectiveSwingInterval() {
    final base = PickaxeBalance.swingInterval(_state.pickaxe);
    final speedBonus = _speedBonus();
    return (base / (1 + speedBonus)).clamp(0.10, 5.0);
  }

  double _damageBonus() {
    double b = 0;
    for (final h in _state.helpers.values) {
      if (!h.recruited) continue;
      final def = helperById(h.id);
      b += helperDamageMul(def, h.level);
    }
    return b;
  }

  double _speedBonus() {
    double b = 0;
    for (final h in _state.helpers.values) {
      if (!h.recruited) continue;
      final def = helperById(h.id);
      b += helperFireBonus(def, h.level);
    }
    return b;
  }

  double _critChance() {
    double c = GameConstants.baseCritChance;
    final chichi = _state.helpers['magpie_chichi'];
    if (chichi != null && chichi.recruited) {
      c += chichi.level.toDouble();
    }
    return c.clamp(0, 80);
  }

  double _sellBonus() {
    final dali = _state.helpers['rabbit_dali'];
    if (dali == null || !dali.recruited) return 0;
    return 0.06 * dali.level;
  }

  double _comboMultiplier() {
    final mults = GameConstants.comboMultipliers;
    final idx = _combo.clamp(0, mults.length - 1);
    return mults[idx];
  }

  final math.Random _rng = math.Random();

  // === 환전 / 자동매도 토글 ===

  void toggleAutoSell() {
    _state = _state.copyWith(autoSell: !_state.autoSell);
    notifyListeners();
  }

  /// 인벤토리에 모인 광석을 일괄 환전
  void sellAllInventory() {
    if (_state.oreInventory.isEmpty) return;
    final sellBonus = _sellBonus();
    double gained = 0;
    for (final entry in _state.oreInventory.entries) {
      final def = kOres.firstWhere(
        (o) => o.id == entry.key,
        orElse: () => kOres.first,
      );
      gained += entry.value * def.coinValue * (1 + sellBonus);
    }
    _state = _state.copyWith(
      coin: _state.coin + gained,
      oreInventory: const {},
    );
    notifyListeners();
  }

  // === 업그레이드 ===

  ActionResult upgradePickaxeDamage() {
    final cost =
        PickaxeBalance.damageUpgradeCost(_state.pickaxe.damageLevel);
    if (_state.coin < cost) {
      return ActionResult.fail('코인이 부족합니다');
    }
    _state = _state.copyWith(
      coin: _state.coin - cost,
      pickaxe: _state.pickaxe
          .copyWith(damageLevel: _state.pickaxe.damageLevel + 1),
    );
    notifyListeners();
    return ActionResult.success;
  }

  ActionResult upgradePickaxeSpeed() {
    final cost =
        PickaxeBalance.speedUpgradeCost(_state.pickaxe.speedLevel);
    if (_state.coin < cost) {
      return ActionResult.fail('코인이 부족합니다');
    }
    _state = _state.copyWith(
      coin: _state.coin - cost,
      pickaxe: _state.pickaxe
          .copyWith(speedLevel: _state.pickaxe.speedLevel + 1),
    );
    notifyListeners();
    return ActionResult.success;
  }

  ActionResult upgradeMineRank() {
    if (_state.mineRank >= maxMineRank) {
      return ActionResult.fail('이미 최고 등급입니다');
    }
    final cost = mineUpgradeCost(_state.mineRank);
    if (_state.coin < cost) {
      return ActionResult.fail('코인이 부족합니다');
    }
    final newRank = _state.mineRank + 1;
    // 층 자동 진입
    int newLayer = ((newRank - 1) ~/ GameConstants.oreRanksPerLayer) + 1;
    if (newLayer > GameConstants.maxLayer) newLayer = GameConstants.maxLayer;

    final newOreId = oreByRank(newRank).id;
    _state = _state.copyWith(
      coin: _state.coin - cost,
      mineRank: newRank,
      layer: newLayer,
      discoveredOres: {..._state.discoveredOres, newOreId},
    );
    notifyListeners();
    return ActionResult.success;
  }

  // === 조수 ===

  ActionResult recruitOrUpgradeHelper(String id) {
    final def = helperById(id);
    final cur = _state.helpers[id];
    final newMap = Map<String, HelperState>.from(_state.helpers);

    if (cur == null || !cur.recruited) {
      if (_state.coin < def.recruitCost) {
        return ActionResult.fail('코인이 부족합니다');
      }
      newMap[id] = HelperState(id: id, recruited: true, level: 1);
      _state = _state.copyWith(
        coin: _state.coin - def.recruitCost,
        helpers: newMap,
      );
    } else {
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

  // === 산신령 ===

  void _scheduleSpirit() {
    _spiritTimer?.cancel();
    final minS = GameConstants.spiritMinInterval.inSeconds;
    final maxS = GameConstants.spiritMaxInterval.inSeconds;
    final sec = minS + _rng.nextInt(maxS - minS + 1);
    _spiritTimer = Timer(Duration(seconds: sec), _spawnSpirit);
  }

  void _spawnSpirit() {
    final coinPerSec = IdleCalculator.coinPerSecond(_state);
    activeSpirit = SpiritBonus(
      id: 'spirit_${DateTime.now().millisecondsSinceEpoch}',
      coinBonus: math.max(coinPerSec * 90.0, 100.0),
    );
    notifyListeners();
    Timer(const Duration(seconds: 15), () {
      if (activeSpirit != null) {
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
    _combo = 0;
    _lastSwingAt = null;
    notifyListeners();
  }

  // === 디버그 헬퍼 (UI에서 노출용 read-only) ===

  double get currentSwingInterval => _effectiveSwingInterval();
  double get currentCritChance => _critChance();
  double get currentSellBonus => _sellBonus();
  int get currentOrePerSwing {
    final base = PickaxeBalance.orePerSwing(_state.pickaxe);
    return (base * (1 + _damageBonus())).round();
  }
}

/// SaveRepository 싱글톤
final saveRepositoryProvider =
    Provider<SaveRepository>((ref) => SaveRepository());

/// GameProvider — 전역 상태
final gameProvider = ChangeNotifierProvider<GameProvider>((ref) {
  final repo = ref.watch(saveRepositoryProvider);
  final p = GameProvider(repo);
  Timer.periodic(const Duration(seconds: 10), (_) {
    if (p.initialized) p.persist();
  });
  ref.onDispose(() {
    if (p.initialized) p.persist();
  });
  return p;
});

// ignore: unused_element
void _dbgUnused() {
  // ChangeNotifier 사용을 보장하기 위한 더미 (foundation import 유지)
  ChangeNotifier();
}
