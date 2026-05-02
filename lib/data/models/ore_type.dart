import 'package:flutter/material.dart';
import 'tier.dart';

/// 광석 정의 — 광맥에서 캐지는 자원의 한 종류.
///
/// 광부는 한 번에 한 가지 광석만 캐며, 광맥 등급(`mineRank`)에 따라
/// 무엇을 캐는지 결정된다. 광석은 `coinValue`로 즉시 환전된다.
class OreDef {
  final String id;
  final String name;
  final String emoji;
  final Tier tier;
  final Color color;

  /// 광석 1개당 코인 가치
  final double coinValue;

  /// 도감용 백스토리
  final String description;

  const OreDef({
    required this.id,
    required this.name,
    required this.emoji,
    required this.tier,
    required this.color,
    required this.coinValue,
    required this.description,
  });
}
