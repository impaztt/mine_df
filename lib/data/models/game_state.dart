import 'dart:convert';

import 'helper.dart';
import 'pickaxe.dart';

/// 게임 전체 상태 — 직렬화 가능 (JSON / SharedPreferences)
class GameState {
  /// 광석 인벤토리 (수집 모드일 때 누적). 자동 환전 모드에서는 항상 0.
  final Map<String, double> oreInventory;

  /// 누적 코인
  final double coin;

  /// 환생 화폐
  final int stardust;

  /// 보석 (프리미엄)
  final int gem;

  /// 현재 광맥 등급 (1 = 거친 돌, 2 = 구리 …)
  final int mineRank;

  /// 곡괭이 스탯
  final PickaxeStats pickaxe;

  /// 조수 보유 / 레벨
  final Map<String, HelperState> helpers;

  /// 현재 깊이 층 (1~6)
  final int layer;

  /// 자동 환전 (true = 캐자마자 코인으로 변환)
  final bool autoSell;

  /// 자동 환전 잠금 해제 여부 (보석으로 구매하면 true). false면 수동만 가능.
  final bool autoSellUnlocked;

  /// 광부 누적 채굴 회수 (도감/업적용)
  final int totalSwings;

  /// 도감 — 캐본 적 있는 광석 ID 집합
  final Set<String> discoveredOres;

  /// 마지막 저장 시각 (epoch ms) — 오프라인 보상 계산용
  final int lastSavedAt;

  const GameState({
    required this.oreInventory,
    required this.coin,
    required this.stardust,
    required this.gem,
    required this.mineRank,
    required this.pickaxe,
    required this.helpers,
    required this.layer,
    required this.autoSell,
    required this.autoSellUnlocked,
    required this.totalSwings,
    required this.discoveredOres,
    required this.lastSavedAt,
  });

  static GameState initial() {
    return GameState(
      oreInventory: const {},
      coin: 0,
      stardust: 0,
      gem: 5,
      mineRank: 1,
      pickaxe: const PickaxeStats(),
      helpers: const {},
      layer: 1,
      autoSell: false,
      autoSellUnlocked: false,
      totalSwings: 0,
      discoveredOres: const {'rough_stone'},
      lastSavedAt: 0,
    );
  }

  GameState copyWith({
    Map<String, double>? oreInventory,
    double? coin,
    int? stardust,
    int? gem,
    int? mineRank,
    PickaxeStats? pickaxe,
    Map<String, HelperState>? helpers,
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
      stardust: stardust ?? this.stardust,
      gem: gem ?? this.gem,
      mineRank: mineRank ?? this.mineRank,
      pickaxe: pickaxe ?? this.pickaxe,
      helpers: helpers ?? this.helpers,
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
        'stardust': stardust,
        'gem': gem,
        'mineRank': mineRank,
        'pickaxe': pickaxe.toJson(),
        'helpers': helpers.map((k, v) => MapEntry(k, v.toJson())),
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
        stardust: j['stardust'] as int? ?? 0,
        gem: j['gem'] as int? ?? 0,
        mineRank: j['mineRank'] as int? ?? 1,
        pickaxe: j['pickaxe'] is Map<String, dynamic>
            ? PickaxeStats.fromJson(j['pickaxe'] as Map<String, dynamic>)
            : const PickaxeStats(),
        helpers: (j['helpers'] as Map<String, dynamic>? ?? const {}).map(
          (k, v) => MapEntry(
              k, HelperState.fromJson(v as Map<String, dynamic>)),
        ),
        layer: j['layer'] as int? ?? 1,
        autoSell: j['autoSell'] as bool? ?? false,
        // 기존 사용자가 자동환전을 켜본 적 있다면 잠금 해제된 상태로 마이그레이션
        autoSellUnlocked: j['autoSellUnlocked'] as bool? ??
            (j['autoSell'] as bool? ?? false),
        totalSwings: j['totalSwings'] as int? ?? 0,
        discoveredOres: ((j['discoveredOres'] as List?)
                    ?.cast<String>()
                    .toSet()) ??
            <String>{'rough_stone'},
        lastSavedAt: j['lastSavedAt'] as int? ?? 0,
      );

  String encode() => jsonEncode(toJson());
  static GameState decode(String s) =>
      GameState.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
