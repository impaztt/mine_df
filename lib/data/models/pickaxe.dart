/// 곡괭이 / 채굴 강화 스탯의 모음.
///
/// 곡괭이 시트의 8개 강화 항목 중 광맥 등급(`mineRank`)을 제외한
/// 나머지 7개가 여기 모두 들어간다.
class PickaxeStats {
  /// 곡괭이질 한 번에 캐는 광석 수
  final int damageLevel;

  /// 곡괭이질 간격 (속도)
  final int speedLevel;

  /// 크리티컬 확률 강화
  final int critChanceLevel;

  /// 크리티컬 위력 강화 (크리 시 데미지 배수)
  final int critPowerLevel;

  /// 광석 제련 — 환전 시 코인 가치 +%
  final int smeltLevel;

  /// 연쇄 채굴 — 곡괭이질 한 번 후 확률적으로 즉시 한 번 더
  final int chainMineLevel;

  /// 별의 운 — 광석 신규 발견 시 추가 보석 보상
  final int luckLevel;

  const PickaxeStats({
    this.damageLevel = 1,
    this.speedLevel = 1,
    this.critChanceLevel = 0,
    this.critPowerLevel = 0,
    this.smeltLevel = 0,
    this.chainMineLevel = 0,
    this.luckLevel = 0,
  });

  PickaxeStats copyWith({
    int? damageLevel,
    int? speedLevel,
    int? critChanceLevel,
    int? critPowerLevel,
    int? smeltLevel,
    int? chainMineLevel,
    int? luckLevel,
  }) =>
      PickaxeStats(
        damageLevel: damageLevel ?? this.damageLevel,
        speedLevel: speedLevel ?? this.speedLevel,
        critChanceLevel: critChanceLevel ?? this.critChanceLevel,
        critPowerLevel: critPowerLevel ?? this.critPowerLevel,
        smeltLevel: smeltLevel ?? this.smeltLevel,
        chainMineLevel: chainMineLevel ?? this.chainMineLevel,
        luckLevel: luckLevel ?? this.luckLevel,
      );

  Map<String, dynamic> toJson() => {
        'damageLevel': damageLevel,
        'speedLevel': speedLevel,
        'critChanceLevel': critChanceLevel,
        'critPowerLevel': critPowerLevel,
        'smeltLevel': smeltLevel,
        'chainMineLevel': chainMineLevel,
        'luckLevel': luckLevel,
      };

  factory PickaxeStats.fromJson(Map<String, dynamic> j) => PickaxeStats(
        damageLevel: j['damageLevel'] as int? ?? 1,
        speedLevel: j['speedLevel'] as int? ?? 1,
        critChanceLevel: j['critChanceLevel'] as int? ?? 0,
        critPowerLevel: j['critPowerLevel'] as int? ?? 0,
        smeltLevel: j['smeltLevel'] as int? ?? 0,
        chainMineLevel: j['chainMineLevel'] as int? ?? 0,
        luckLevel: j['luckLevel'] as int? ?? 0,
      );
}
