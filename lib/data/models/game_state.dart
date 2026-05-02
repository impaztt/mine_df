import 'dart:convert';

import 'helper.dart';
import 'pickaxe.dart';
import 'producer.dart';

/// 게임 전체 상태 — 직렬화 가능 (JSON / SharedPreferences).
///
/// 검클리커 구조 적용 후:
/// - producers: 자동 채굴 광부 13종 (Lv0=미영입, Lv1+=영입+레벨)
/// - tapUpgrades: 탭 강화 11종 (Lv0=미구매, Lv1+=레벨)
/// - essenceStage: 광맥 정수 강화 단계 (+0~+50)
/// - prestigeLevels: 환생 영구 트리 레벨
/// - totalCoinEarned: 환생 시 별의 결정 산출용 (누적)
class GameState {
  final Map<String, double> oreInventory;

  final double coin;
  final double totalCoinEarned;
  final int stardust;
  final int gem;

  /// 광맥 등급 (1~30) — 캐는 광석 종류 결정
  final int mineRank;

  /// 광맥 정수 강화 단계 (0~50)
  final int essenceStage;

  /// 곡괭이 (탭 단가 = 곡괭이 데미지 × 탭 강화 합산 × 보너스)
  final PickaxeStats pickaxe;

  /// 광부들 (자동 채굴)
  final Map<String, ProducerState> producers;

  /// 탭 강화 (영구 누적)
  final Map<String, int> tapUpgrades;

  /// 조수
  final Map<String, HelperState> helpers;

  /// 환생 트리 레벨
  final Map<String, int> prestigeLevels;
  final int rebirthCount;

  final int layer;
  final bool autoSell;
  final bool autoSellUnlocked;
  final int totalSwings;
  final Set<String> discoveredOres;
  final int lastSavedAt;

  const GameState({
    required this.oreInventory,
    required this.coin,
    required this.totalCoinEarned,
    required this.stardust,
    required this.gem,
    required this.mineRank,
    required this.essenceStage,
    required this.pickaxe,
    required this.producers,
    required this.tapUpgrades,
    required this.helpers,
    required this.prestigeLevels,
    required this.rebirthCount,
    required this.layer,
    required this.autoSell,
    required this.autoSellUnlocked,
    required this.totalSwings,
    required this.discoveredOres,
    required this.lastSavedAt,
  });

  static GameState initial() {
    return const GameState(
      oreInventory: {},
      coin: 0,
      totalCoinEarned: 0,
      stardust: 0,
      gem: 5,
      mineRank: 1,
      essenceStage: 0,
      pickaxe: PickaxeStats(),
      producers: {},
      tapUpgrades: {},
      helpers: {},
      prestigeLevels: {},
      rebirthCount: 0,
      layer: 1,
      autoSell: false,
      autoSellUnlocked: false,
      totalSwings: 0,
      discoveredOres: {'rough_stone'},
      lastSavedAt: 0,
    );
  }

  /// 환생 시 사용 — 영구 자원/트리/도감만 유지하고 나머지 리셋.
  GameState rebirthReset({
    required int newRebirthCount,
    required int addedStardust,
  }) {
    return GameState(
      oreInventory: const {},
      coin: 0,
      totalCoinEarned: 0,
      stardust: stardust + addedStardust,
      gem: gem,
      mineRank: 1,
      essenceStage: 0,
      pickaxe: const PickaxeStats(),
      producers: const {},
      tapUpgrades: const {},
      // 조수는 영입 상태만 유지, 레벨은 1로
      helpers: {
        for (final h in helpers.values)
          if (h.recruited)
            h.id: HelperState(id: h.id, recruited: true, level: 1),
      },
      prestigeLevels: prestigeLevels,
      rebirthCount: newRebirthCount,
      layer: 1,
      autoSell: autoSell && autoSellUnlocked,
      autoSellUnlocked: autoSellUnlocked,
      totalSwings: totalSwings,
      discoveredOres: discoveredOres,
      lastSavedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  GameState copyWith({
    Map<String, double>? oreInventory,
    double? coin,
    double? totalCoinEarned,
    int? stardust,
    int? gem,
    int? mineRank,
    int? essenceStage,
    PickaxeStats? pickaxe,
    Map<String, ProducerState>? producers,
    Map<String, int>? tapUpgrades,
    Map<String, HelperState>? helpers,
    Map<String, int>? prestigeLevels,
    int? rebirthCount,
    int? layer,
    bool? autoSell,
    bool? autoSellUnlocked,
    int? totalSwings,
    Set<String>? discoveredOres,
    int? lastSavedAt,
  }) {
    return GameState(
      oreInventory: oreInventory ?? this.oreInventory,
      coin: coin ?? this.coin,
      totalCoinEarned: totalCoinEarned ?? this.totalCoinEarned,
      stardust: stardust ?? this.stardust,
      gem: gem ?? this.gem,
      mineRank: mineRank ?? this.mineRank,
      essenceStage: essenceStage ?? this.essenceStage,
      pickaxe: pickaxe ?? this.pickaxe,
      producers: producers ?? this.producers,
      tapUpgrades: tapUpgrades ?? this.tapUpgrades,
      helpers: helpers ?? this.helpers,
      prestigeLevels: prestigeLevels ?? this.prestigeLevels,
      rebirthCount: rebirthCount ?? this.rebirthCount,
      layer: layer ?? this.layer,
      autoSell: autoSell ?? this.autoSell,
      autoSellUnlocked: autoSellUnlocked ?? this.autoSellUnlocked,
      totalSwings: totalSwings ?? this.totalSwings,
      discoveredOres: discoveredOres ?? this.discoveredOres,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'oreInventory': oreInventory,
        'coin': coin,
        'totalCoinEarned': totalCoinEarned,
        'stardust': stardust,
        'gem': gem,
        'mineRank': mineRank,
        'essenceStage': essenceStage,
        'pickaxe': pickaxe.toJson(),
        'producers': producers.map((k, v) => MapEntry(k, v.toJson())),
        'tapUpgrades': tapUpgrades,
        'helpers': helpers.map((k, v) => MapEntry(k, v.toJson())),
        'prestigeLevels': prestigeLevels,
        'rebirthCount': rebirthCount,
        'layer': layer,
        'autoSell': autoSell,
        'autoSellUnlocked': autoSellUnlocked,
        'totalSwings': totalSwings,
        'discoveredOres': discoveredOres.toList(),
        'lastSavedAt': lastSavedAt,
      };

  factory GameState.fromJson(Map<String, dynamic> j) => GameState(
        oreInventory: (j['oreInventory'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
            const {},
        coin: (j['coin'] as num).toDouble(),
        totalCoinEarned:
            (j['totalCoinEarned'] as num?)?.toDouble() ?? 0,
        stardust: j['stardust'] as int? ?? 0,
        gem: j['gem'] as int? ?? 0,
        mineRank: j['mineRank'] as int? ?? 1,
        essenceStage: j['essenceStage'] as int? ?? 0,
        pickaxe: j['pickaxe'] is Map<String, dynamic>
            ? PickaxeStats.fromJson(j['pickaxe'] as Map<String, dynamic>)
            : const PickaxeStats(),
        producers: (j['producers'] as Map<String, dynamic>? ?? const {})
            .map((k, v) => MapEntry(
                k, ProducerState.fromJson(v as Map<String, dynamic>))),
        tapUpgrades:
            (j['tapUpgrades'] as Map<String, dynamic>? ?? const {})
                .map((k, v) => MapEntry(k, v as int)),
        helpers: (j['helpers'] as Map<String, dynamic>? ?? const {}).map(
          (k, v) => MapEntry(
              k, HelperState.fromJson(v as Map<String, dynamic>)),
        ),
        prestigeLevels:
            (j['prestigeLevels'] as Map<String, dynamic>? ?? const {})
                .map((k, v) => MapEntry(k, v as int)),
        rebirthCount: j['rebirthCount'] as int? ?? 0,
        layer: j['layer'] as int? ?? 1,
        autoSell: j['autoSell'] as bool? ?? false,
        autoSellUnlocked: j['autoSellUnlocked'] as bool? ??
            (j['autoSell'] as bool? ?? false),
        totalSwings: j['totalSwings'] as int? ?? 0,
        discoveredOres:
            ((j['discoveredOres'] as List?)?.cast<String>().toSet()) ??
                <String>{'rough_stone'},
        lastSavedAt: j['lastSavedAt'] as int? ?? 0,
      );

  String encode() => jsonEncode(toJson());
  static GameState decode(String s) =>
      GameState.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
