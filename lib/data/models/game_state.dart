import 'dart:convert';

import 'facility.dart';
import 'helper.dart';

/// 게임 전체 상태 — 직렬화 가능 (JSON / SharedPreferences)
class GameState {
  /// 누적 광물 (현재 보유)
  final double ore;

  /// 누적 코인
  final double coin;

  /// 환생 화폐
  final int stardust;

  /// 보석 (프리미엄)
  final int gem;

  /// 현재 DAY (1부터 시작)
  final int day;

  /// 현재 DAY에서 처치한 일반 적 수 (보스 제외)
  final int dayKills;

  /// 보스 페이즈 진입 여부
  final bool bossPhase;

  /// 광산 체력 (5 = 만피)
  final int mineHp;

  /// 시설 보유 / 레벨
  final Map<String, FacilityState> facilities;

  /// 조수 보유 / 레벨
  final Map<String, HelperState> helpers;

  /// 현재 장착 광물 ID
  final String equippedOreId;

  /// 현재 깊이 층 (1~5)
  final int layer;

  /// 마지막 저장 시각 (epoch ms) — 오프라인 보상 계산용
  final int lastSavedAt;

  const GameState({
    required this.ore,
    required this.coin,
    required this.stardust,
    required this.gem,
    required this.day,
    required this.dayKills,
    required this.bossPhase,
    required this.mineHp,
    required this.facilities,
    required this.helpers,
    required this.equippedOreId,
    required this.layer,
    required this.lastSavedAt,
  });

  static GameState initial() {
    return GameState(
      ore: 0,
      coin: 30,
      stardust: 0,
      gem: 50,
      day: 1,
      dayKills: 0,
      bossPhase: false,
      mineHp: 5,
      // 손곡괭이는 기본 1레벨로 시작 (튜토리얼)
      facilities: const {
        'hand_pickaxe': FacilityState(id: 'hand_pickaxe', level: 1),
      },
      helpers: const {},
      equippedOreId: 'rough_stone',
      layer: 1,
      lastSavedAt: 0,
    );
  }

  GameState copyWith({
    double? ore,
    double? coin,
    int? stardust,
    int? gem,
    int? day,
    int? dayKills,
    bool? bossPhase,
    int? mineHp,
    Map<String, FacilityState>? facilities,
    Map<String, HelperState>? helpers,
    String? equippedOreId,
    int? layer,
    int? lastSavedAt,
  }) {
    return GameState(
      ore: ore ?? this.ore,
      coin: coin ?? this.coin,
      stardust: stardust ?? this.stardust,
      gem: gem ?? this.gem,
      day: day ?? this.day,
      dayKills: dayKills ?? this.dayKills,
      bossPhase: bossPhase ?? this.bossPhase,
      mineHp: mineHp ?? this.mineHp,
      facilities: facilities ?? this.facilities,
      helpers: helpers ?? this.helpers,
      equippedOreId: equippedOreId ?? this.equippedOreId,
      layer: layer ?? this.layer,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'ore': ore,
        'coin': coin,
        'stardust': stardust,
        'gem': gem,
        'day': day,
        'dayKills': dayKills,
        'bossPhase': bossPhase,
        'mineHp': mineHp,
        'facilities':
            facilities.map((k, v) => MapEntry(k, v.toJson())),
        'helpers': helpers.map((k, v) => MapEntry(k, v.toJson())),
        'equippedOreId': equippedOreId,
        'layer': layer,
        'lastSavedAt': lastSavedAt,
      };

  factory GameState.fromJson(Map<String, dynamic> j) => GameState(
        ore: (j['ore'] as num).toDouble(),
        coin: (j['coin'] as num).toDouble(),
        stardust: j['stardust'] as int? ?? 0,
        gem: j['gem'] as int? ?? 0,
        day: j['day'] as int,
        dayKills: j['dayKills'] as int? ?? 0,
        bossPhase: j['bossPhase'] as bool? ?? false,
        mineHp: j['mineHp'] as int? ?? 5,
        facilities: (j['facilities'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(
              k, FacilityState.fromJson(v as Map<String, dynamic>)),
        ),
        helpers: (j['helpers'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(
              k, HelperState.fromJson(v as Map<String, dynamic>)),
        ),
        equippedOreId: j['equippedOreId'] as String? ?? 'rough_stone',
        layer: j['layer'] as int? ?? 1,
        lastSavedAt: j['lastSavedAt'] as int? ?? 0,
      );

  String encode() => jsonEncode(toJson());
  static GameState decode(String s) =>
      GameState.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
