import 'package:flutter/material.dart';

/// 채굴 시설 정의 (정적 데이터)
class FacilityDef {
  final String id;
  final String name;
  final IconData icon;
  final int unlockDay;

  /// Lv1 기준 채굴량 (광물/초)
  final double baseRate;

  /// Lv1 구매 비용 (코인)
  final double baseCost;

  const FacilityDef({
    required this.id,
    required this.name,
    required this.icon,
    required this.unlockDay,
    required this.baseRate,
    required this.baseCost,
  });
}

/// 사용자가 보유한 시설 상태
class FacilityState {
  final String id;
  final int level;

  const FacilityState({required this.id, required this.level});

  FacilityState copyWith({int? level}) =>
      FacilityState(id: id, level: level ?? this.level);

  Map<String, dynamic> toJson() => {'id': id, 'level': level};

  factory FacilityState.fromJson(Map<String, dynamic> j) =>
      FacilityState(id: j['id'] as String, level: j['level'] as int);
}
