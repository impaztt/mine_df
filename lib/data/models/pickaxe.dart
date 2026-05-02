/// 곡괭이의 변경 가능한 스탯
class PickaxeStats {
  /// 곡괭이 데미지 레벨 (1 = 곡괭이질 1번에 광석 1개)
  final int damageLevel;

  /// 곡괭이 속도 레벨 (높을수록 더 자주 채굴)
  final int speedLevel;

  const PickaxeStats({
    this.damageLevel = 1,
    this.speedLevel = 1,
  });

  PickaxeStats copyWith({int? damageLevel, int? speedLevel}) =>
      PickaxeStats(
        damageLevel: damageLevel ?? this.damageLevel,
        speedLevel: speedLevel ?? this.speedLevel,
      );

  Map<String, dynamic> toJson() => {
        'damageLevel': damageLevel,
        'speedLevel': speedLevel,
      };

  factory PickaxeStats.fromJson(Map<String, dynamic> j) => PickaxeStats(
        damageLevel: j['damageLevel'] as int? ?? 1,
        speedLevel: j['speedLevel'] as int? ?? 1,
      );
}
