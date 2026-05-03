import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/game_constants.dart';
import '../../data/balance/country_data.dart';
import '../../data/balance/essence_data.dart';
import '../../data/balance/helper_data.dart';
import '../../data/balance/ore_data.dart';
import '../../data/balance/pickaxe_data.dart';
import '../../data/balance/prestige_data.dart';
import '../../data/balance/producer_data.dart';
import '../../data/balance/tap_upgrade_data.dart';
import '../../data/models/country.dart';
import '../../data/models/game_state.dart';
import '../../data/models/helper.dart';
import '../../data/models/pickaxe.dart';
import '../../data/models/producer.dart';
import '../../data/repositories/save_repository.dart';
import '../../domain/idle_calculator.dart';

/// 게임 액션의 결과
class ActionResult {
  final bool ok;
  final String? message;
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

class SpiritBonus {
  final String id;
  final double coinBonus;
  SpiritBonus({required this.id, required this.coinBonus});
}

/// 채굴(탭/자동/연쇄) 1회 결과 — UI 피드백
class MineHit {
  final double oreAmount;
  final bool isCritical;
  final double coinGained;
  final String? newlyDiscoveredOreId;
  final bool fromTap;
  final int seq;

  MineHit({
    required this.oreAmount,
    required this.isCritical,
    required this.coinGained,
    required this.seq,
    this.fromTap = false,
    this.newlyDiscoveredOreId,
  });
}

/// 정수 강화 시도 결과
class EssenceAttemptResult {
  final bool success;
  final int newStage;
  final bool downgraded;
  final double coinSpent;
  EssenceAttemptResult({
    required this.success,
    required this.newStage,
    required this.downgraded,
    required this.coinSpent,
  });
}

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

  double pendingOfflineCoin = 0;

  SpiritBonus? activeSpirit;
  Timer? _spiritTimer;

  Timer? _autoTickTimer;
  Timer? _marketTickTimer;
  DateTime? _lastSwingAt;
  MineHit? lastHit;
  int _hitSeq = 0;
  DateTime _lastTigerStrikeAt = DateTime.fromMillisecondsSinceEpoch(0);

  int _tickCounter = 0;

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
      totalCoinEarned: loaded.totalCoinEarned + pendingOfflineCoin,
      lastSavedAt: now.millisecondsSinceEpoch,
    );
    _initialized = true;
    _ensureMarketsInitialized();
    _startAutoTick();
    _startMarketTick();
    _scheduleSpirit();
    notifyListeners();
    await _repo.save(_state);
  }

  @override
  void dispose() {
    _autoTickTimer?.cancel();
    _marketTickTimer?.cancel();
    _spiritTimer?.cancel();
    super.dispose();
  }

  // === 광산 지분 거래소 ===

  /// 첫 진입 / 새 국가 추가 시 빠진 국가 상태 초기화.
  void _ensureMarketsInitialized() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final map = Map<String, CountryState>.from(_state.markets);
    bool changed = false;
    for (final c in kCountries) {
      if (!map.containsKey(c.id)) {
        map[c.id] = CountryState(
          id: c.id,
          price: c.intrinsicPrice,
          priceHistory: [c.intrinsicPrice],
          lastTickAt: now,
          cycleStartedAt: now,
        );
        changed = true;
      }
    }
    if (changed) {
      _state = _state.copyWith(markets: map);
    }
  }

  /// 매 1초마다 모든 국가 가격 업데이트.
  void _startMarketTick() {
    _marketTickTimer?.cancel();
    _marketTickTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _tickMarketPrices(),
    );
  }

  void _tickMarketPrices() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final map = Map<String, CountryState>.from(_state.markets);
    for (final c in kCountries) {
      final cur = map[c.id];
      if (cur == null) continue;
      final next = nextPriceTick(
        def: c,
        currentPrice: cur.price,
        cycleStartedAt:
            cur.cycleStartedAt == 0 ? now : cur.cycleStartedAt,
        nowMs: now,
        rng: _rng,
      );
      // 히스토리 — 최대 길이 유지
      final hist = List<double>.from(cur.priceHistory)..add(next);
      while (hist.length > kPriceHistoryLength) {
        hist.removeAt(0);
      }
      map[c.id] = cur.copyWith(
        price: next,
        priceHistory: hist,
        lastTickAt: now,
        cycleStartedAt: cur.cycleStartedAt == 0 ? now : cur.cycleStartedAt,
      );
    }
    _state = _state.copyWith(markets: map);
    notifyListeners();
  }

  // ---- 광석 즉시 매도 (인벤토리 → 코인, 국가 시세 적용) ----

  /// 특정 국가에 보유 광석을 일괄 판매.
  /// 시세 배율 = currentPrice / intrinsicPrice.
  ActionResult sellAllOreToCountry(String countryId) {
    final c = countryById(countryId);
    final market = _state.markets[countryId];
    if (market == null) return ActionResult.fail('국가 정보 없음');

    final mult = market.priceMultiplier(c.intrinsicPrice);
    final invMap = Map<String, double>.from(_state.oreInventory);
    final sellBonus = IdleCalculator.sellBonus(_state);
    double totalCoin = 0;
    int kinds = 0;

    for (final entry in invMap.entries.toList()) {
      final ore = kOres.firstWhere(
        (o) => o.id == entry.key,
        orElse: () => kOres.first,
      );
      final rank = kOres.indexOf(ore) + 1;
      if (rank < c.minRank || rank > c.maxRank) continue;
      if (entry.value <= 0) continue;
      totalCoin += entry.value * ore.coinValue * mult * (1 + sellBonus);
      kinds++;
      invMap.remove(entry.key);
    }
    if (kinds == 0) {
      return ActionResult.fail('해당 국가가 매입할 광석이 없습니다');
    }
    _state = _state.copyWith(
      coin: _state.coin + totalCoin,
      totalCoinEarned: _state.totalCoinEarned + totalCoin,
      oreInventory: invMap,
    );
    notifyListeners();
    return ActionResult(ok: true, cost: totalCoin, times: kinds);
  }

  double previewOreSellRevenue(String countryId) {
    final c = countryById(countryId);
    final market = _state.markets[countryId];
    if (market == null) return 0;
    final mult = market.priceMultiplier(c.intrinsicPrice);
    final sellBonus = IdleCalculator.sellBonus(_state);
    double total = 0;
    for (final entry in _state.oreInventory.entries) {
      if (entry.value <= 0) continue;
      final ore = kOres.firstWhere(
        (o) => o.id == entry.key,
        orElse: () => kOres.first,
      );
      final rank = kOres.indexOf(ore) + 1;
      if (rank < c.minRank || rank > c.maxRank) continue;
      total += entry.value * ore.coinValue * mult * (1 + sellBonus);
    }
    return total;
  }

  int countryEligibleOreKinds(String countryId) {
    final c = countryById(countryId);
    int count = 0;
    for (final entry in _state.oreInventory.entries) {
      if (entry.value <= 0) continue;
      final ore = kOres.firstWhere(
        (o) => o.id == entry.key,
        orElse: () => kOres.first,
      );
      final rank = kOres.indexOf(ore) + 1;
      if (rank >= c.minRank && rank <= c.maxRank) count++;
    }
    return count;
  }

  // ---- 주식 매수 / 매도 ----

  /// 매수 — `shares` 주를 현재 가격으로 구매. 수수료 2%.
  ActionResult buyShares(String countryId, int shares) {
    if (shares <= 0) return ActionResult.fail('수량 입력 필요');
    final market = _state.markets[countryId];
    if (market == null) return ActionResult.fail('국가 정보 없음');

    final gross = shares * market.price;
    final fee = gross * kStockTradeFee;
    final total = gross + fee;
    if (_state.coin < total) {
      return ActionResult.fail('코인이 부족합니다');
    }

    // 평균가 갱신 — (기존가 × 기존주 + 매수가 × 신규주) / 총주
    final newShares = market.shares + shares;
    final newAvg = market.shares <= 0
        ? market.price
        : (market.avgCost * market.shares + market.price * shares) /
            newShares;

    final newMarkets = Map<String, CountryState>.from(_state.markets);
    newMarkets[countryId] = market.copyWith(
      shares: newShares,
      avgCost: newAvg,
      totalTrades: market.totalTrades + 1,
    );
    _state = _state.copyWith(
      coin: _state.coin - total,
      markets: newMarkets,
    );
    notifyListeners();
    return ActionResult(ok: true, times: shares, cost: total);
  }

  /// 매도 — `shares` 주를 현재 가격으로 판매. 수수료 2%.
  ActionResult sellShares(String countryId, int shares) {
    if (shares <= 0) return ActionResult.fail('수량 입력 필요');
    final market = _state.markets[countryId];
    if (market == null) return ActionResult.fail('국가 정보 없음');
    if (market.shares < shares) {
      return ActionResult.fail('보유 주식이 부족합니다');
    }

    final gross = shares * market.price;
    final fee = gross * kStockTradeFee;
    final net = gross - fee;

    // 실현 손익 = (현재가 - 평균가) × 주식 수
    final realized = (market.price - market.avgCost) * shares;

    final remaining = market.shares - shares;
    final newAvg = remaining <= 0 ? 0.0 : market.avgCost;

    final newMarkets = Map<String, CountryState>.from(_state.markets);
    newMarkets[countryId] = market.copyWith(
      shares: remaining,
      avgCost: newAvg,
      totalTrades: market.totalTrades + 1,
      totalRealizedProfit: market.totalRealizedProfit + realized,
    );
    _state = _state.copyWith(
      coin: _state.coin + net,
      totalCoinEarned: _state.totalCoinEarned + (net > 0 ? net : 0),
      markets: newMarkets,
    );
    notifyListeners();
    return ActionResult(ok: true, times: shares, cost: net);
  }

  /// 현재 코인으로 매수 가능한 최대 주식 수 (수수료 포함)
  int maxBuyableShares(String countryId) {
    final market = _state.markets[countryId];
    if (market == null || market.price <= 0) return 0;
    final unit = market.price * (1 + kStockTradeFee);
    if (unit <= 0) return 0;
    return (_state.coin / unit).floor();
  }

  Future<void> persist() async {
    _state = _state.copyWith(
      lastSavedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _repo.save(_state);
  }

  // === 자동 채굴 — 매 200ms 틱 ===

  void _startAutoTick() {
    _autoTickTimer?.cancel();
    _lastSwingAt = DateTime.now();
    _autoTickTimer = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => _autoTick(),
    );
  }

  /// 200ms 마다 누적 광석을 적용. 광부 + 곡괭이 자동 채굴 모두 합산.
  void _autoTick() {
    final now = DateTime.now();
    final last = _lastSwingAt ?? now;
    final dt = now.difference(last).inMilliseconds / 1000.0;
    _lastSwingAt = now;
    if (dt <= 0) return;

    final orePerSec = IdleCalculator.oresPerSecond(_state);
    if (orePerSec > 0) {
      final amount = orePerSec * dt;
      _depositOre(amount: amount, isCritical: false, fromTap: false);
    }

    _tickCounter++;
    if (_tickCounter >= 5) {
      _tickCounter = 0;
      notifyListeners();
    }
  }

  // === 탭 액션 — 즉시 광석, 쿨다운 없음 ===

  ActionResult tap() {
    final base = IdleCalculator.tapOrePerHit(_state);
    if (base <= 0) return ActionResult.success;

    // 크리티컬
    final critChance = _critChance();
    final isCritical = _rng.nextDouble() * 100 < critChance;
    final amount = isCritical ? base * _critMultiplier() : base;

    _depositOre(
      amount: amount,
      isCritical: isCritical,
      fromTap: true,
    );

    // 호랑이 범 — 8초마다 ×10 강타 (탭에 동기화)
    final tiger = _state.helpers['tiger_beom'];
    if (tiger != null && tiger.recruited) {
      final now = DateTime.now();
      if (now.difference(_lastTigerStrikeAt).inSeconds >= 8) {
        _lastTigerStrikeAt = now;
        _depositOre(
            amount: amount * 10, isCritical: true, fromTap: false);
      }
    }

    return ActionResult.success;
  }

  /// 광석을 인벤토리/코인에 누적. UI 피드백(MineHit)도 함께 갱신.
  void _depositOre({
    required double amount,
    required bool isCritical,
    required bool fromTap,
  }) {
    if (amount <= 0) return;

    final ore = oreByRank(_state.mineRank);
    final sellBonus = IdleCalculator.sellBonus(_state);
    final coinGain = amount * ore.coinValue * (1 + sellBonus);

    final isNew = !_state.discoveredOres.contains(ore.id);
    final newDiscovered = isNew
        ? <String>{..._state.discoveredOres, ore.id}
        : _state.discoveredOres;
    final gemBonus = isNew
        ? GameProvider.newOreDiscoveryGem +
            PickaxeBalance.luckGemBonus(_state.pickaxe.luckLevel)
        : 0;

    if (_state.autoSell) {
      _state = _state.copyWith(
        coin: _state.coin + coinGain,
        totalCoinEarned: _state.totalCoinEarned + coinGain,
        gem: _state.gem + gemBonus,
        totalSwings: fromTap ? _state.totalSwings + 1 : _state.totalSwings,
        discoveredOres: newDiscovered,
      );
    } else {
      final inv = Map<String, double>.from(_state.oreInventory);
      inv[ore.id] = (inv[ore.id] ?? 0) + amount;
      _state = _state.copyWith(
        oreInventory: inv,
        gem: _state.gem + gemBonus,
        totalSwings: fromTap ? _state.totalSwings + 1 : _state.totalSwings,
        discoveredOres: newDiscovered,
      );
    }

    lastHit = MineHit(
      oreAmount: amount,
      isCritical: isCritical,
      coinGained:
          _state.autoSell ? coinGain : amount * ore.coinValue,
      seq: ++_hitSeq,
      fromTap: fromTap,
      newlyDiscoveredOreId: isNew ? ore.id : null,
    );

    if (fromTap) {
      // 즉시 알림 (탭은 매번 시각 효과 필요)
      notifyListeners();

      // 연쇄 채굴 — 탭에서만 추가 발사
      _maybeChain();
    }
  }

  void _maybeChain() {
    int depth = 0;
    while (depth < PickaxeBalance.chainMineMaxDepth) {
      final p = PickaxeBalance.chainMineProb(
          _state.pickaxe.chainMineLevel);
      if (p <= 0 || _rng.nextDouble() * 100 >= p) break;
      depth++;
      // 연쇄는 탭과 동일한 광석량을 추가로
      final base = IdleCalculator.tapOrePerHit(_state);
      _depositOre(amount: base, isCritical: false, fromTap: false);
    }
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

  final math.Random _rng = math.Random();

  // === 환전 ===

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
    final bonus = IdleCalculator.sellBonus(_state);
    double gained = 0;
    for (final entry in _state.oreInventory.entries) {
      final def = kOres.firstWhere(
        (o) => o.id == entry.key,
        orElse: () => kOres.first,
      );
      gained += entry.value * def.coinValue * (1 + bonus);
    }
    _state = _state.copyWith(
      coin: _state.coin + gained,
      totalCoinEarned: _state.totalCoinEarned + gained,
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
    final bonus = IdleCalculator.sellBonus(_state);
    final gained = count * def.coinValue * (1 + bonus);
    final inv = Map<String, double>.from(_state.oreInventory);
    inv.remove(oreId);
    _state = _state.copyWith(
      coin: _state.coin + gained,
      totalCoinEarned: _state.totalCoinEarned + gained,
      oreInventory: inv,
    );
    notifyListeners();
  }

  double inventoryTotalValue() {
    final bonus = IdleCalculator.sellBonus(_state);
    double total = 0;
    for (final entry in _state.oreInventory.entries) {
      final def = kOres.firstWhere(
        (o) => o.id == entry.key,
        orElse: () => kOres.first,
      );
      total += entry.value * def.coinValue * (1 + bonus);
    }
    return total;
  }

  int inventoryKindCount() => _state.oreInventory.entries
      .where((e) => e.value > 0)
      .length;

  double inventoryTotalCount() =>
      _state.oreInventory.values.fold<double>(0, (a, b) => a + b);

  // === 일괄 구매 헬퍼 ===

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

  ({int times, double cost}) previewBulk({
    required int currentLevel,
    required int? cap,
    required double Function(int level) costFn,
  }) {
    return _planBulk(
      costFn: costFn,
      currentLevel: currentLevel,
      cap: cap,
      requested: _bulkMode.count,
      availableCoin: _state.coin,
    );
  }

  /// UI 표시 전용 — 현재 [bulkMode]의 buyCount와 합계 비용을
  /// **살 수 없어도** 그대로 반환한다 (sw_clicker 스타일).
  ///
  /// - ×1: buyCount = 1, totalCost = 다음 +1 비용
  /// - ×10/×100: buyCount = mode 숫자, totalCost = 그 횟수 합계 (cap에 막히면 그만큼만)
  /// - MAX: 코인이 닿는 만큼; 못 사면 buyCount=1로 fallback (다음 +1 비용 표시)
  ({int buyCount, double totalCost, bool affordable, bool atCap})
      priceForMode({
    required int currentLevel,
    required int? cap,
    required double Function(int level) costFn,
  }) {
    final capLeft = cap != null
        ? (cap - currentLevel).clamp(0, 9999)
        : 9999;
    if (capLeft == 0) {
      return (
        buyCount: 0,
        totalCost: 0,
        affordable: false,
        atCap: true,
      );
    }

    final mode = _bulkMode;
    if (mode == BulkBuyMode.max) {
      int t = 0;
      double total = 0;
      while (t < capLeft) {
        final next = costFn(currentLevel + t);
        if (total + next > _state.coin) break;
        total += next;
        t++;
        if (t > 9999) break;
      }
      if (t == 0) {
        // 살 수 없으면 ×1처럼 표시 — 다음 +1 비용
        return (
          buyCount: 1,
          totalCost: costFn(currentLevel),
          affordable: false,
          atCap: false,
        );
      }
      return (buyCount: t, totalCost: total, affordable: true, atCap: false);
    }

    final target = mode.count.clamp(1, capLeft);
    double total = 0;
    for (int i = 0; i < target; i++) {
      total += costFn(currentLevel + i);
    }
    return (
      buyCount: target,
      totalCost: total,
      affordable: _state.coin >= total,
      atCap: false,
    );
  }

  int _bulkRequested() => _bulkMode.count;

  // === 곡괭이 강화 (기존) ===

  ActionResult upgradePickaxeDamage([int? times]) => _bulkPickaxe(
        currentLevel: _state.pickaxe.damageLevel,
        cap: null,
        costFn: PickaxeBalance.damageUpgradeCost,
        requested: times ?? _bulkRequested(),
        applyLevel: (lv) => _state.pickaxe.copyWith(damageLevel: lv),
      );

  ActionResult upgradePickaxeSpeed([int? times]) => _bulkPickaxe(
        currentLevel: _state.pickaxe.speedLevel,
        cap: null,
        costFn: PickaxeBalance.speedUpgradeCost,
        requested: times ?? _bulkRequested(),
        applyLevel: (lv) => _state.pickaxe.copyWith(speedLevel: lv),
      );

  ActionResult upgradeCritChance([int? times]) => _bulkPickaxe(
        currentLevel: _state.pickaxe.critChanceLevel,
        cap: PickaxeBalance.critChanceCap,
        costFn: PickaxeBalance.critChanceUpgradeCost,
        requested: times ?? _bulkRequested(),
        applyLevel: (lv) => _state.pickaxe.copyWith(critChanceLevel: lv),
      );

  ActionResult upgradeCritPower([int? times]) => _bulkPickaxe(
        currentLevel: _state.pickaxe.critPowerLevel,
        cap: PickaxeBalance.critPowerCap,
        costFn: PickaxeBalance.critPowerUpgradeCost,
        requested: times ?? _bulkRequested(),
        applyLevel: (lv) => _state.pickaxe.copyWith(critPowerLevel: lv),
      );

  ActionResult upgradeSmelt([int? times]) => _bulkPickaxe(
        currentLevel: _state.pickaxe.smeltLevel,
        cap: PickaxeBalance.smeltCap,
        costFn: PickaxeBalance.smeltUpgradeCost,
        requested: times ?? _bulkRequested(),
        applyLevel: (lv) => _state.pickaxe.copyWith(smeltLevel: lv),
      );

  ActionResult upgradeChainMine([int? times]) => _bulkPickaxe(
        currentLevel: _state.pickaxe.chainMineLevel,
        cap: PickaxeBalance.chainMineCap,
        costFn: PickaxeBalance.chainMineUpgradeCost,
        requested: times ?? _bulkRequested(),
        applyLevel: (lv) => _state.pickaxe.copyWith(chainMineLevel: lv),
      );

  ActionResult upgradeLuck([int? times]) => _bulkPickaxe(
        currentLevel: _state.pickaxe.luckLevel,
        cap: PickaxeBalance.luckCap,
        costFn: PickaxeBalance.luckUpgradeCost,
        requested: times ?? _bulkRequested(),
        applyLevel: (lv) => _state.pickaxe.copyWith(luckLevel: lv),
      );

  ActionResult _bulkPickaxe({
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

  // === 광맥 등급 (단발) ===

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

  // === 광부 (Producer) ===

  ActionResult upgradeProducer(String id, [int? times]) {
    final def = producerById(id);
    final cur = _state.producers[id]?.level ?? 0;
    final plan = _planBulk(
      costFn: (lv) => ProducerBalance.upgradeCost(def, lv),
      currentLevel: cur,
      cap: null,
      requested: times ?? _bulkRequested(),
      availableCoin: _state.coin,
    );
    if (plan.times <= 0) {
      return ActionResult.fail('코인이 부족합니다');
    }
    final map = Map<String, ProducerState>.from(_state.producers);
    map[id] = ProducerState(id: id, level: cur + plan.times);
    _state = _state.copyWith(
      coin: _state.coin - plan.cost,
      producers: map,
    );
    notifyListeners();
    return ActionResult(ok: true, times: plan.times, cost: plan.cost);
  }

  // === 탭 강화 ===

  ActionResult upgradeTap(String id, [int? times]) {
    final def = tapUpgradeById(id);
    final cur = _state.tapUpgrades[id] ?? 0;
    final plan = _planBulk(
      costFn: (lv) => TapUpgradeBalance.upgradeCost(def, lv),
      currentLevel: cur,
      cap: null,
      requested: times ?? _bulkRequested(),
      availableCoin: _state.coin,
    );
    if (plan.times <= 0) {
      return ActionResult.fail('코인이 부족합니다');
    }
    final map = Map<String, int>.from(_state.tapUpgrades);
    map[id] = cur + plan.times;
    _state = _state.copyWith(
      coin: _state.coin - plan.cost,
      tapUpgrades: map,
    );
    notifyListeners();
    return ActionResult(ok: true, times: plan.times, cost: plan.cost);
  }

  // === 조수 ===

  ActionResult recruitOrUpgradeHelper(String id, [int? times]) {
    final def = helperById(id);
    final cur = _state.helpers[id];

    if (cur == null || !cur.recruited) {
      if (_state.coin < def.recruitCost) {
        return ActionResult.fail('코인이 부족합니다');
      }
      final map = Map<String, HelperState>.from(_state.helpers);
      map[id] = HelperState(id: id, recruited: true, level: 1);
      _state = _state.copyWith(
        coin: _state.coin - def.recruitCost,
        helpers: map,
      );
      notifyListeners();
      return ActionResult(ok: true, times: 1, cost: def.recruitCost);
    }

    final plan = _planBulk(
      costFn: (lv) => helperUpgradeCost(def, lv),
      currentLevel: cur.level,
      cap: null,
      requested: times ?? _bulkRequested(),
      availableCoin: _state.coin,
    );
    if (plan.times <= 0) {
      return ActionResult.fail('코인이 부족합니다');
    }
    final map = Map<String, HelperState>.from(_state.helpers);
    map[id] = cur.copyWith(level: cur.level + plan.times);
    _state = _state.copyWith(
      coin: _state.coin - plan.cost,
      helpers: map,
    );
    notifyListeners();
    return ActionResult(ok: true, times: plan.times, cost: plan.cost);
  }

  // === 광맥 정수 강화 ===

  EssenceAttemptResult tryEssence({
    required EssenceBoost boost,
    required bool useProtection,
  }) {
    if (_state.essenceStage >= kEssenceMaxStage) {
      return EssenceAttemptResult(
        success: false,
        newStage: _state.essenceStage,
        downgraded: false,
        coinSpent: 0,
      );
    }
    final target = _state.essenceStage + 1;
    final cost = essenceCostFor(target);
    if (_state.coin < cost.coinCost) {
      return EssenceAttemptResult(
        success: false,
        newStage: _state.essenceStage,
        downgraded: false,
        coinSpent: 0,
      );
    }
    int gemSpend = 0;
    if (useProtection) gemSpend += kEssenceProtectionGemCost;
    gemSpend += boost.gemCost;
    if (_state.gem < gemSpend) {
      return EssenceAttemptResult(
        success: false,
        newStage: _state.essenceStage,
        downgraded: false,
        coinSpent: 0,
      );
    }

    final rate = (cost.successRate + boost.successBonus).clamp(0.0, 1.0);
    final roll = _rng.nextDouble();
    final success = roll < rate;

    int newStage = _state.essenceStage;
    bool downgraded = false;
    if (success) {
      newStage = target;
    } else if (!useProtection) {
      newStage =
          (_state.essenceStage - cost.penaltyOnFail).clamp(0, kEssenceMaxStage);
      downgraded = newStage < _state.essenceStage;
    }

    _state = _state.copyWith(
      coin: _state.coin - cost.coinCost,
      gem: _state.gem - gemSpend,
      essenceStage: newStage,
    );
    notifyListeners();

    return EssenceAttemptResult(
      success: success,
      newStage: newStage,
      downgraded: downgraded,
      coinSpent: cost.coinCost,
    );
  }

  // === 환생 ===

  bool get canRebirthNow =>
      canRebirth(_state.mineRank, _state.totalCoinEarned);

  /// 지금 환생 시 받게 될 별의 결정 (보너스 포함)
  int previewStardustReward() {
    final base = baseStardustReward(_state.totalCoinEarned);
    final bonus = 1 + prestigeStardustGainBonus(_state.prestigeLevels);
    return (base * bonus).floor().clamp(0, 1 << 31);
  }

  ActionResult performRebirth() {
    if (!canRebirthNow) {
      return ActionResult.fail('환생 조건을 만족하지 않습니다');
    }
    final reward = previewStardustReward();
    if (reward <= 0) {
      return ActionResult.fail('아직 환생 보상이 없습니다');
    }
    _state = _state.rebirthReset(
      newRebirthCount: _state.rebirthCount + 1,
      addedStardust: reward,
    );
    notifyListeners();
    return ActionResult(ok: true, cost: reward.toDouble(), times: 1);
  }

  ActionResult upgradePrestigeNode(String id) {
    final def = prestigeNodeById(id);
    final cur = _state.prestigeLevels[id] ?? 0;
    if (cur >= def.maxLevel) {
      return ActionResult.fail('이미 최대 레벨');
    }
    final cost = prestigeNodeCost(def, cur);
    final costInt = cost.ceil();
    if (_state.stardust < costInt) {
      return ActionResult.fail('별의 결정이 부족합니다');
    }
    final map = Map<String, int>.from(_state.prestigeLevels);
    map[id] = cur + 1;
    _state = _state.copyWith(
      stardust: _state.stardust - costInt,
      prestigeLevels: map,
    );
    notifyListeners();
    return ActionResult(ok: true, cost: costInt.toDouble(), times: 1);
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
      coinBonus:
          math.max(coinPerSec * GameConstants.spiritCoinSeconds, 50.0),
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
    final gain = s.coinBonus * multiplier;
    _state = _state.copyWith(
      coin: _state.coin + gain,
      totalCoinEarned: _state.totalCoinEarned + gain,
    );
    activeSpirit = null;
    notifyListeners();
    _scheduleSpirit();
  }

  // === 디버그 ===

  Future<void> hardReset() async {
    await _repo.clear();
    _state = GameState.initial();
    _bulkMode = BulkBuyMode.x1;
    _lastSwingAt = null;
    notifyListeners();
  }

  // === UI 표시 헬퍼 ===

  double get currentSellBonus => IdleCalculator.sellBonus(_state);
  double get currentCritChance => _critChance();
  double get currentCritMultiplier => _critMultiplier();
  double get currentTapOre => IdleCalculator.tapOrePerHit(_state);
  double get currentOrePerSec => IdleCalculator.oresPerSecond(_state);
  double get currentCoinPerSec => IdleCalculator.coinPerSecond(_state);

  /// 곡괭이 자동 채굴 간격 (조수 속도 보너스 반영)
  double get currentSwingInterval {
    double bonus = 0;
    for (final h in _state.helpers.values) {
      if (!h.recruited) continue;
      final def = helperById(h.id);
      bonus += helperFireBonus(def, h.level);
    }
    final base = PickaxeBalance.swingInterval(_state.pickaxe);
    return (base / (1 + bonus)).clamp(0.10, 5.0);
  }

  /// 곡괭이 자동 채굴 1회당 광석 (조수 데미지 보너스 반영, 글로벌 X)
  int get currentOrePerSwing {
    double bonus = 0;
    for (final h in _state.helpers.values) {
      if (!h.recruited) continue;
      final def = helperById(h.id);
      bonus += helperDamageMul(def, h.level);
    }
    final base = PickaxeBalance.orePerSwing(_state.pickaxe);
    return (base * (1 + bonus)).round();
  }
}

final saveRepositoryProvider =
    Provider<SaveRepository>((ref) => SaveRepository());

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

// foundation import 보존
// ignore: unused_element
void _ensureFoundationImport() {
  if (kDebugMode) debugPrint('');
}
