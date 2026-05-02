import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/prestige.dart';

/// 환생 영구 트리 — 별의 결정으로 강화하는 5개 노드.
const List<PrestigeNodeDef> kPrestigeNodes = [
  PrestigeNodeDef(
    id: 'star_seal',
    name: '별의 각인',
    description: '전체 채굴량을 영구 강화합니다 (+2%/Lv).',
    icon: Icons.auto_awesome,
    accent: Color(0xFF00695C),
    baseCost: 5,
    growthRate: 1.12,
    maxLevel: 9999,
    globalBonusPerLevel: 0.02,
  ),
  PrestigeNodeDef(
    id: 'pickaxe_legacy',
    name: '곡괭이의 유산',
    description: '탭 광석을 영구 강화합니다 (+12%/Lv).',
    icon: Icons.touch_app,
    accent: Color(0xFFFF7043),
    baseCost: 12,
    growthRate: 1.45,
    maxLevel: 40,
    tapBonusPerLevel: 0.12,
  ),
  PrestigeNodeDef(
    id: 'miner_legacy',
    name: '광부의 유산',
    description: '자동 광석을 영구 강화합니다 (+12%/Lv).',
    icon: Icons.bolt,
    accent: Color(0xFF26A69A),
    baseCost: 12,
    growthRate: 1.45,
    maxLevel: 40,
    autoBonusPerLevel: 0.12,
  ),
  PrestigeNodeDef(
    id: 'big_dipper_core',
    name: '칠성의 핵',
    description: '탭과 자동 모두 영구 강화합니다 (+8%/Lv).',
    icon: Icons.brightness_7,
    accent: Color(0xFFFFB300),
    baseCost: 40,
    growthRate: 1.70,
    maxLevel: 25,
    tapBonusPerLevel: 0.08,
    autoBonusPerLevel: 0.08,
  ),
  PrestigeNodeDef(
    id: 'soul_exchange',
    name: '영혼의 환전',
    description: '환생 시 받는 별의 결정을 늘립니다 (+15%/Lv).',
    icon: Icons.currency_exchange,
    accent: Color(0xFF7C4DFF),
    baseCost: 20,
    growthRate: 1.60,
    maxLevel: 30,
    stardustGainBonusPerLevel: 0.15,
  ),
];

PrestigeNodeDef prestigeNodeById(String id) =>
    kPrestigeNodes.firstWhere((n) => n.id == id);

double prestigeNodeCost(PrestigeNodeDef def, int currentLevel) {
  return def.baseCost * math.pow(def.growthRate, currentLevel).toDouble();
}

/// 환생 가능 여부 — 광맥 등급 10 이상 + 누적 코인 1B
bool canRebirth(int mineRank, double totalCoinEarned) {
  return mineRank >= 10 || totalCoinEarned >= 1e9;
}

/// 환생 시 받는 별의 결정 (보너스 적용 전)
double baseStardustReward(double totalCoinEarned) {
  if (totalCoinEarned <= 0) return 0;
  return math.pow(totalCoinEarned, 0.4) / 1000.0;
}

/// 트리 합산 함수들
double prestigeTapBonus(Map<String, int> levels) {
  double total = 0;
  for (final def in kPrestigeNodes) {
    final lv = levels[def.id] ?? 0;
    total += def.tapBonusPerLevel * lv;
  }
  return total;
}

double prestigeAutoBonus(Map<String, int> levels) {
  double total = 0;
  for (final def in kPrestigeNodes) {
    final lv = levels[def.id] ?? 0;
    total += def.autoBonusPerLevel * lv;
  }
  return total;
}

double prestigeGlobalBonus(Map<String, int> levels) {
  double total = 0;
  for (final def in kPrestigeNodes) {
    final lv = levels[def.id] ?? 0;
    total += def.globalBonusPerLevel * lv;
  }
  return total;
}

double prestigeStardustGainBonus(Map<String, int> levels) {
  double total = 0;
  for (final def in kPrestigeNodes) {
    final lv = levels[def.id] ?? 0;
    total += def.stardustGainBonusPerLevel * lv;
  }
  return total;
}
