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
import '../../data/models/pickaxe.dart';
import '../../data/repositories/save_repository.dart';
import '../../domain/idle_calculator.dart';

/// 게임 액션의 결과
class ActionResult {
  final bool ok;
  final String? message;

  /// 일괄 구매 시 실제 구매된 횟수
  final int times;
  final double cost;

  const ActionResult({
    required this.ok,
    this.message,
    this.times = 0,
    this.cost = 0,
  });

  static const success = ActionResult(ok: true);
  factory ActionResult.fail(String m) => ActionResult(ok: false, message: m);
}

/// 산신령 보너스 이벤트
class SpiritBonus {
  final String id;
  final double coinBonus;
  SpiritBonus({required this.id, required this.coinBonus});
}

/// 채굴 1회 결과 — UI 피드백
class MineHit {
  final int oreAmount;
  final bool isCritical;
  final double coinGained;

  /// 신규 발견된 광석 ID (있으면 보석 알림)
  final String? newlyDiscoveredOreId;

  /// 식별자
  final int seq;

  MineHit({
    required this.oreAmount,
    required this.isCritical,
    required this.coinGained,
    required this.seq,
    this.newlyDiscoveredOreId,
  });
}

/// 일괄 구매 모드
enum BulkBuyMode {
  x1(1, '×1'),
  x10(10, '×10'),
  x100(100, '×100'),
  max(0, 'MAX');

  final int count;
  final String label;
  const BulkBuyMode(this.count, this.label);
}

class GameProvider extends ChangeNotifier {
  GameProvider(this._repo);
  final SaveRepository _repo;

  GameState _state = GameState.initial();
  GameState get state => _state;

  bool _initialized = false;
  bool get initialized => _initialized;

  /// 시작 시 누적된 오프라인 보상
  double pendingOfflineCoin = 0;

  /// 활성 산신령
  SpiritBonus? activeSpirit;
  Timer? _spiritTimer;

  /// 자동 채굴 타이머
  Timer? _autoMineTimer;

  /// 가장 최근 채굴 시각
  DateTime? _lastSwingAt;

  /// 탭 가속 쿨다운 종료 시각
  DateTime _tapCooldownUntil = DateTime.fromMillisecondsSinceEpoch(0);

  /// 가장 최근 채굴 정보
  MineHit? lastHit;

  int _hitSeq = 0;

  /// 호랑이 범 — 마지막 강타 시각
  DateTime _lastTigerStrikeAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// notifyListeners 빈도 제한
  int _tickCounter = 0;

  /// 현재 일괄 구매 모드 — 곡괭이/조수 시트에서 공통 사용
  BulkBuyMode _bulkMode = BulkBuyMode.x1;
  BulkBuyMode get bulkMode => _bulkMode;
  void setBulkMode(BulkBuyMode mode) {
    if (_bulkMode == mode) return;
    _bulkMode = mode;
    notifyListeners();
  }

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
      _tickCounter++;
      if (_tickCounter >= 5) {
        _tickCounter = 0;
        notifyListeners();
      }
    }
  }

  // === 채굴 액션 ===

  ActionResult tap() {
    final now = DateTime.now();
    if (now.isBefore(_tapCooldownUntil)) {
      return ActionResult.fail('잠시만!');
    }
    _tapCooldownUntil = now.add(
      Duration(milliseconds: (GameConstants.tapCooldown * 1000).round()),
    );
    _performMine(now: now, isTap: true);
    return ActionResult.success;
  }

  void _performMine({
    required DateTime now,
    required bool isTap,
    int chainDepth = 0,
  }) {
    _lastSwingAt = now;

    int amount = PickaxeBalance.orePerSwing(_state.pickaxe);
    final dmgBonus = _damageBonus();
    amount = (amount * (1 + dmgBonus)).round().clamp(1, 1 << 30);

    final critChance = _critChance();
    final isCritical = _rng.nextDouble() * 100 < critChance;
    if (isCritical) {
      amount = (amount * _critMultiplier()).round();
    }

    // 호랑이 범 — 8초마다 강타
    final tiger = _state.helpers['tiger_beom'];
    if (tiger != null && tiger.recruited) {
      if (now.difference(_lastTigerStrikeAt).inSeconds >= 8) {
        _lastTigerStrikeAt = now;
        amount *= 10;
      }
    }

    // 구미호 — ×2 확률
    final gumiho = _state.helpers['gumiho_yawol'];
    if (gumiho != null && gumiho.recruited) {
      final p = 1.2 * gumiho.level;
      if (_rng.nextDouble() * 100 < p) {
        amount *= 2;
      }
    }

    final ore = oreByRank(_state.mineRank);
    final sellBonus = _sellBonus();
    final coinGain = amount * ore.coinValue * (1 + sellBonus);

    final isNewDiscovery = !_state.discoveredOres.contains(ore.id);
    final newDiscovered = isNewDiscovery
        ? <String>{..._state.discoveredOres, ore.id}
        : _state.discoveredOres;
    final gemBonus = isNewDiscovery
        ? GameProvider.newOreDiscoveryGem +
            PickaxeBalance.luckGemBonus(_state.pickaxe.luckLevel)
        : 0;

    if (_state.autoSell) {
      _state = _state.copyWith(
        coin: _state.coin + coinGain,
        gem: _state.gem + gemBonus,
        totalSwings: _state.totalSwings + 1,
        discoveredOres: newDiscovered,
      );
    } else {
      final inv = Map<String, double>.from(_state.oreInventory);
      inv[ore.id] = (inv[ore.id] ?? 0) + amount;
      _state = _state.copyWith(
        oreInventory: inv,
        gem: _state.gem + gemBonus,
        totalSwings: _state.totalSwings + 1,
        discoveredOres: newDiscovered,
      );
    }

    lastHit = MineHit(
      oreAmount: amount,
      isCritical: isCritical,
      coinGained: _state.autoSell ? coinGain : amount * ore.coinValue,
      seq: ++_hitSeq,
      newlyDiscoveredOreId: isNewDiscovery ? ore.id : null,
    );

    notifyListeners();

    // 연쇄 채굴 — 확률적으로 즉시 한 번 더
    if (chainDepth < PickaxeBalance.chainMineMaxDepth) {
      final chainP =
          PickaxeBalance.chainMineProb(_state.pickaxe.chainMineLevel);
      if (chainP > 0 && _rng.nextDouble() * 100 < chainP) {
        _performMine(now: now, isTap: false, chainDepth: chainDepth + 1);
      }
    }
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
    c += PickaxeBalance.critChanceBonus(_state.pickaxe.critChanceLevel);
    final chichi = _state.helpers['magpie_chichi'];
    if (chichi != null && chichi.recruited) {
      c += 0.8 * chichi.level;
    }
    return c.clamp(0, 80);
  }

  double _critMultiplier() {
    return GameConstants.critMultiplier +
        PickaxeBalance.critPowerBonus(_state.pickaxe.critPowerLevel);
  }

  double _sellBonus() {
    double b = PickaxeBalance.smeltBonus(_state.pickaxe.smeltLevel);
    final dali = _state.helpers['rabbit_dali'];
    if (dali != null && dali.recruited) {
      b += 0.04 * dali.level;
    }
    return b;
  }

  final math.Random _rng = math.Random();

  // === 환전 / 자동매도 ===

  static const int autoSellUnlockGemCost = 50;
  static const int newOreDiscoveryGem = 3;

  ActionResult unlockAutoSell() {
    if (_state.autoSellUnlocked) {
      return ActionResult.fail('이미 잠금 해제됨');
    }
    if (_state.gem < autoSellUnlockGemCost) {
      return ActionResult.fail(
          '보석이 부족합니다 ($autoSellUnlockGemCost개 필요)');
    }
    _state = _state.copyWith(
      gem: _state.gem - autoSellUnlockGemCost,
      autoSellUnlocked: true,
      autoSell: true,
    );
    notifyListeners();
    return ActionResult.success;
  }

  ActionResult toggleAutoSell() {
    if (!_state.autoSellUnlocked) {
      return ActionResult.fail('자동환전이 잠겨 있습니다');
    }
    _state = _state.copyWith(autoSell: !_state.autoSell);
    notifyListeners();
    return ActionResult.success;
  }

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

  void sellOre(String oreId) {
    final count = _state.oreInventory[oreId];
    if (count == null || count <= 0) return;
    final def = kOres.firstWhere(
      (o) => o.id == oreId,
      orElse: () => kOres.first,
    );
    final sellBonus = _sellBonus();
    final gained = count * def.coinValue * (1 + sellBonus);
    final inv = Map<String, double>.from(_state.oreInventory);
    inv.remove(oreId);
    _state = _state.copyWith(
      coin: _state.coin + gained,
      oreInventory: inv,
    );
    notifyListeners();
  }

  double inventoryTotalValue() {
    final sellBonus = _sellBonus();
    double total = 0;
    for (final entry in _state.oreInventory.entries) {
      final def = kOres.firstWhere(
        (o) => o.id == entry.key,
        orElse: () => kOres.first,
      );
      total += entry.value * def.coinValue * (1 + sellBonus);
    }
    return total;
  }

  int inventoryKindCount() => _state.oreInventory.entries
      .where((e) => e.value > 0)
      .length;

  /// 인벤토리 전체 광석 개수 합
  double inventoryTotalCount() => _state.oreInventory.values
      .fold<double>(0, (a, b) => a + b);

  // === 일괄 구매 헬퍼 ===

  /// 비용 함수와 캡을 받아 현재 코인으로 살 수 있는 횟수와 합계 비용을 계산.
  ({int times, double cost}) _planBulk({
    required double Function(int level) costFn,
    required int currentLevel,
    required int? cap,
    required int requested,
    required double availableCoin,
  }) {
    int t = 0;
    double total = 0;
    while (true) {
      if (cap != null && currentLevel + t >= cap) break;
      final next = costFn(currentLevel + t);
      if (total + next > availableCoin) break;
      total += next;
      t++;
      if (requested > 0 && t >= requested) break;
      if (t > 9999) break;
    }
    return (times: t, cost: total);
  }

  int _bulkRequested() => _bulkMode.count; // 0 = max

  // === 곡괭이 강화 ===

  ActionResult upgradePickaxeDamage([int? times]) =>
      _bulkUpgrade(
        currentLevel: _state.pickaxe.damageLevel,
        cap: null,
        costFn: PickaxeBalance.damageUpgradeCost,
        requested: times ?? _bulkRequested(),
        applyLevel: (lv) =>
            _state.pickaxe.copyWith(damageLevel: lv),
      );

  ActionResult upgradePickaxeSpeed([int? times]) =>
      _bulkUpgrade(
        currentLevel: _state.pickaxe.speedLevel,
        cap: null,
        costFn: PickaxeBalance.speedUpgradeCost,
        requested: times ?? _bulkRequested(),
        applyLevel: (lv) => _state.pickaxe.copyWith(speedLevel: lv),
      );

  ActionResult upgradeCritChance([int? times]) => _bulkUpgrade(
        currentLevel: _state.pickaxe.critChanceLevel,
        cap: PickaxeBalance.critChanceCap,
        costFn: PickaxeBalance.critChanceUpgradeCost,
        requested: times ?? _bulkRequested(),
        applyLevel: (lv) =>
            _state.pickaxe.copyWith(critChanceLevel: lv),
      );

  ActionResult upgradeCritPower([int? times]) => _bulkUpgrade(
        currentLevel: _state.pickaxe.critPowerLevel,
        cap: PickaxeBalance.critPowerCap,
        costFn: PickaxeBalance.critPowerUpgradeCost,
        requested: times ?? _bulkRequested(),
        applyLevel: (lv) =>
            _state.pickaxe.copyWith(critPowerLevel: lv),
      );

  ActionResult upgradeSmelt([int? times]) => _bulkUpgrade(
        currentLevel: _state.pickaxe.smeltLevel,
        cap: PickaxeBalance.smeltCap,
        costFn: PickaxeBalance.smeltUpgradeCost,
        requested: times ?? _bulkRequested(),
        applyLevel: (lv) => _state.pickaxe.copyWith(smeltLevel: lv),
      );

  ActionResult upgradeChainMine([int? times]) => _bulkUpgrade(
        currentLevel: _state.pickaxe.chainMineLevel,
        cap: PickaxeBalance.chainMineCap,
        costFn: PickaxeBalance.chainMineUpgradeCost,
        requested: times ?? _bulkRequested(),
        applyLevel: (lv) =>
            _state.pickaxe.copyWith(chainMineLevel: lv),
      );

  ActionResult upgradeLuck([int? times]) => _bulkUpgrade(
        currentLevel: _state.pickaxe.luckLevel,
        cap: PickaxeBalance.luckCap,
        costFn: PickaxeBalance.luckUpgradeCost,
        requested: times ?? _bulkRequested(),
        applyLevel: (lv) => _state.pickaxe.copyWith(luckLevel: lv),
      );

  ActionResult _bulkUpgrade({
    required int currentLevel,
    required int? cap,
    required double Function(int level) costFn,
    required int requested,
    required PickaxeStats Function(int newLevel) applyLevel,
  }) {
    final plan = _planBulk(
      costFn: costFn,
      currentLevel: currentLevel,
      cap: cap,
      requested: requested,
      availableCoin: _state.coin,
    );
    if (plan.times <= 0) {
      if (cap != null && currentLevel >= cap) {
        return ActionResult.fail('이미 최대 레벨');
      }
      return ActionResult.fail('코인이 부족합니다');
    }
    _state = _state.copyWith(
      coin: _state.coin - plan.cost,
      pickaxe: applyLevel(currentLevel + plan.times),
    );
    notifyListeners();
    return ActionResult(ok: true, times: plan.times, cost: plan.cost);
  }

  // === 광맥 강화 (단발 — 1번에 한 등급씩) ===

  ActionResult upgradeMineRank() {
    if (_state.mineRank >= maxMineRank) {
      return ActionResult.fail('이미 최고 등급입니다');
    }
    final cost = mineUpgradeCost(_state.mineRank);
    if (_state.coin < cost) {
      return ActionResult.fail('코인이 부족합니다');
    }
    final newRank = _state.mineRank + 1;
    int newLayer =
        ((newRank - 1) ~/ GameConstants.oreRanksPerLayer) + 1;
    if (newLayer > GameConstants.maxLayer) newLayer = GameConstants.maxLayer;

    final newOreId = oreByRank(newRank).id;
    _state = _state.copyWith(
      coin: _state.coin - cost,
      mineRank: newRank,
      layer: newLayer,
      discoveredOres: {..._state.discoveredOres, newOreId},
    );
    notifyListeners();
    return ActionResult(ok: true, times: 1, cost: cost);
  }

  // === 조수 ===

  ActionResult recruitOrUpgradeHelper(String id, [int? times]) {
    final def = helperById(id);
    final cur = _state.helpers[id];

    // 영입은 단발
    if (cur == null || !cur.recruited) {
      if (_state.coin < def.recruitCost) {
        return ActionResult.fail('코인이 부족합니다');
      }
      final newMap = Map<String, HelperState>.from(_state.helpers);
      newMap[id] = HelperState(id: id, recruited: true, level: 1);
      _state = _state.copyWith(
        coin: _state.coin - def.recruitCost,
        helpers: newMap,
      );
      notifyListeners();
      return ActionResult(ok: true, times: 1, cost: def.recruitCost);
    }

    // 강화 — bulk 적용
    final requested = times ?? _bulkRequested();
    final plan = _planBulk(
      costFn: (lv) => helperUpgradeCost(def, lv),
      currentLevel: cur.level,
      cap: null,
      requested: requested,
      availableCoin: _state.coin,
    );
    if (plan.times <= 0) {
      return ActionResult.fail('코인이 부족합니다');
    }
    final newMap = Map<String, HelperState>.from(_state.helpers);
    newMap[id] = cur.copyWith(level: cur.level + plan.times);
    _state = _state.copyWith(
      coin: _state.coin - plan.cost,
      helpers: newMap,
    );
    notifyListeners();
    return ActionResult(ok: true, times: plan.times, cost: plan.cost);
  }

  // === Bulk 미리 계산 (UI용) ===

  /// 곡괭이 항목 강화 시 살 수 있는 횟수와 합계 비용 (구매 안 함, 표시용).
  ({int times, double cost}) previewBulk({
    required int currentLevel,
    required int? cap,
    required double Function(int level) costFn,
  }) {
    return _planBulk(
      costFn: costFn,
      currentLevel: currentLevel,
      cap: cap,
      requested: _bulkRequested(),
      availableCoin: _state.coin,
    );
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
      coinBonus: math.max(coinPerSec * GameConstants.spiritCoinSeconds, 50.0),
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
    _lastSwingAt = null;
    _bulkMode = BulkBuyMode.x1;
    notifyListeners();
  }

  // === UI 표시용 read-only ===

  double get currentSwingInterval => _effectiveSwingInterval();
  double get currentCritChance => _critChance();
  double get currentCritMultiplier => _critMultiplier();
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

// foundation import 사용 보장 (kDebugMode 등 다른 빌드에서 사용 가능)
// ignore: unused_element
void _ensureFoundationImport() {
  if (kDebugMode) debugPrint('');
}
