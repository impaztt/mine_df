import 'package:flutter/material.dart';

/// 자동 채굴 광부 (Producer) 정의 — 채굴 로봇/광산 마법사 등.
class ProducerDef {
  final String id;
  final String name;
  final String emoji;
  final IconData icon;
  final Color accent;

  /// 영입 비용 (Lv1 기준)
  final double baseCost;

  /// Lv1 광부 한 명의 광석/초
  final double baseOrePerSec;

  const ProducerDef({
    required this.id,
    required this.name,
    required this.emoji,
    required this.icon,
    required this.accent,
    required this.baseCost,
    required this.baseOrePerSec,
  });
}

class ProducerState {
  final String id;
  final int level;
  const ProducerState({required this.id, this.level = 0});

  ProducerState copyWith({int? level}) =>
      ProducerState(id: id, level: level ?? this.level);

  Map<String, dynamic> toJson() => {'id': id, 'level': level};

  factory ProducerState.fromJson(Map<String, dynamic> j) => ProducerState(
        id: j['id'] as String,
        level: j['level'] as int? ?? 0,
      );
}
