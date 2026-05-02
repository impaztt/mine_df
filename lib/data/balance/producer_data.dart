import 'package:flutter/material.dart';

import '../models/producer.dart';

/// 자동 채굴 광부 13종.
const List<ProducerDef> kProducers = [
  ProducerDef(
    id: 'apprentice',
    name: '견습 광부',
    emoji: '🧒',
    icon: Icons.child_care,
    accent: Color(0xFFFFB74D),
    baseCost: 50,
    baseOrePerSec: 1,
  ),
  ProducerDef(
    id: 'veteran',
    name: '노련한 광부',
    emoji: '⛏️',
    icon: Icons.handyman,
    accent: Color(0xFFAED581),
    baseCost: 500,
    baseOrePerSec: 8,
  ),
  ProducerDef(
    id: 'foreman',
    name: '갱도장',
    emoji: '👷',
    icon: Icons.engineering,
    accent: Color(0xFF64B5F6),
    baseCost: 5000,
    baseOrePerSec: 60,
  ),
  ProducerDef(
    id: 'mole_crew',
    name: '두더지 일꾼',
    emoji: '🐹',
    icon: Icons.pets,
    accent: Color(0xFFBA68C8),
    baseCost: 50000,
    baseOrePerSec: 400,
  ),
  ProducerDef(
    id: 'mountain_miner',
    name: '산악 광부',
    emoji: '🏔️',
    icon: Icons.terrain,
    accent: Color(0xFFFFD54F),
    baseCost: 500000,
    baseOrePerSec: 3000,
  ),
  ProducerDef(
    id: 'engineer',
    name: '기술자',
    emoji: '🔧',
    icon: Icons.build,
    accent: Color(0xFFE57373),
    baseCost: 5000000,
    baseOrePerSec: 22000,
  ),
  ProducerDef(
    id: 'mining_robot',
    name: '채굴 로봇',
    emoji: '🤖',
    icon: Icons.precision_manufacturing,
    accent: Color(0xFFFFEB3B),
    baseCost: 50000000,
    baseOrePerSec: 150000,
  ),
  ProducerDef(
    id: 'mine_mage',
    name: '광산 마법사',
    emoji: '🧙',
    icon: Icons.auto_fix_high,
    accent: Color(0xFFFFA726),
    baseCost: 500000000,
    baseOrePerSec: 1000000,
  ),
  ProducerDef(
    id: 'vein_dragon',
    name: '광맥 용',
    emoji: '🐉',
    icon: Icons.flight,
    accent: Color(0xFF8D6E63),
    baseCost: 5000000000,
    baseOrePerSec: 7000000,
  ),
  ProducerDef(
    id: 'starlight_miner',
    name: '별빛 광부',
    emoji: '🌟',
    icon: Icons.auto_awesome,
    accent: Color(0xFF7E57C2),
    baseCost: 50000000000,
    baseOrePerSec: 50000000,
  ),
  ProducerDef(
    id: 'time_miner',
    name: '시간의 광부',
    emoji: '⏳',
    icon: Icons.hourglass_bottom,
    accent: Color(0xFF26A69A),
    baseCost: 500000000000,
    baseOrePerSec: 350000000,
  ),
  ProducerDef(
    id: 'cosmic_miner',
    name: '우주 광부',
    emoji: '🌌',
    icon: Icons.public,
    accent: Color(0xFF5C6BC0),
    baseCost: 5000000000000,
    baseOrePerSec: 2500000000,
  ),
  ProducerDef(
    id: 'origin_miner',
    name: '근원의 광부',
    emoji: '👁️',
    icon: Icons.visibility,
    accent: Color(0xFF7986CB),
    baseCost: 50000000000000,
    baseOrePerSec: 8000000000,
  ),
];

class ProducerBalance {
  ProducerBalance._();

  /// 매 레벨 비용 ×1.13 (검클리커 동일)
  static const double costGrowth = 1.13;

  /// 매 레벨 광석/초 ×1.07
  static const double opsGrowth = 1.07;

  /// 마일스톤 보너스 — 도달 시 광석/초 ×2
  static const List<int> milestoneLevels = [25, 50, 100, 250, 500];

  /// Lv0 광부의 광석/초 = 0 (영입 안 됨)
  /// Lv1 = baseOrePerSec × milestoneMultiplier
  /// LvN (N>=1) = baseOrePerSec × opsGrowth^(N-1) × 마일스톤 누적 ×
  static double orePerSec(ProducerDef def, int level) {
    if (level <= 0) return 0;
    double rate = def.baseOrePerSec;
    for (int i = 1; i < level; i++) {
      rate *= opsGrowth;
    }
    int milestoneCount = 0;
    for (final m in milestoneLevels) {
      if (level >= m) milestoneCount++;
    }
    for (int i = 0; i < milestoneCount; i++) {
      rate *= 2;
    }
    return rate;
  }

  /// 다음 레벨 영입/강화 비용
  static double upgradeCost(ProducerDef def, int currentLevel) {
    return def.baseCost * _pow(costGrowth, currentLevel);
  }
}

double _pow(double b, int e) {
  double r = 1;
  for (int i = 0; i < e; i++) {
    r *= b;
  }
  return r;
}

ProducerDef producerById(String id) =>
    kProducers.firstWhere((p) => p.id == id);
