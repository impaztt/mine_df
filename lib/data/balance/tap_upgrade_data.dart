import 'package:flutter/material.dart';

import '../models/tap_upgrade.dart';

/// 탭 강화 11종 — 영구 누적, 모두 합산되어 탭당 광석 결정.
///
/// baseCost 일괄 ×32 인상. 첫 강화(튼튼한 손목)도 800 코인부터 시작.
const List<TapUpgradeDef> kTapUpgrades = [
  TapUpgradeDef(
    id: 'sturdy_wrist',
    name: '튼튼한 손목',
    description: '탭당 광석 +1',
    icon: Icons.fitness_center,
    accent: Color(0xFF90CAF9),
    baseCost: 270,
    tapOrePerLevel: 1,
  ),
  TapUpgradeDef(
    id: 'sturdy_glove',
    name: '단단한 장갑',
    description: '탭당 광석 +5',
    icon: Icons.back_hand,
    accent: Color(0xFFCE93D8),
    baseCost: 2700,
    tapOrePerLevel: 5,
  ),
  TapUpgradeDef(
    id: 'starlight_pickaxe',
    name: '별빛 곡괭이',
    description: '탭당 광석 +25',
    icon: Icons.auto_fix_high,
    accent: Color(0xFFFFD54F),
    baseCost: 27000,
    tapOrePerLevel: 25,
  ),
  TapUpgradeDef(
    id: 'miner_secret',
    name: '광부의 비전',
    description: '탭당 광석 +100',
    icon: Icons.menu_book,
    accent: Color(0xFFFFAB91),
    baseCost: 270000,
    tapOrePerLevel: 100,
  ),
  TapUpgradeDef(
    id: 'spirit_blessing',
    name: '산신령의 가호',
    description: '탭당 광석 +500',
    icon: Icons.self_improvement,
    accent: Color(0xFFEF5350),
    baseCost: 2700000,
    tapOrePerLevel: 500,
  ),
  TapUpgradeDef(
    id: 'big_dipper_touch',
    name: '칠성의 손길',
    description: '탭당 광석 +2.5K',
    icon: Icons.auto_awesome,
    accent: Color(0xFFB39DDB),
    baseCost: 27000000,
    tapOrePerLevel: 2500,
  ),
  TapUpgradeDef(
    id: 'dokkaebi_eye',
    name: '도깨비의 눈',
    description: '탭당 광석 +12.5K',
    icon: Icons.visibility,
    accent: Color(0xFF9575CD),
    baseCost: 270000000,
    tapOrePerLevel: 12500,
  ),
  TapUpgradeDef(
    id: 'star_seal',
    name: '별의 인장',
    description: '탭당 광석 +62.5K',
    icon: Icons.star_rate,
    accent: Color(0xFFFFCC80),
    baseCost: 2700000000,
    tapOrePerLevel: 62500,
  ),
  TapUpgradeDef(
    id: 'fate_vein',
    name: '운명의 광맥',
    description: '탭당 광석 +312.5K',
    icon: Icons.timeline,
    accent: Color(0xFFFF8A65),
    baseCost: 27000000000,
    tapOrePerLevel: 312500,
  ),
  TapUpgradeDef(
    id: 'origin_node',
    name: '근원의 마디',
    description: '탭당 광석 +1.56M',
    icon: Icons.bolt,
    accent: Color(0xFFFFB74D),
    baseCost: 270000000000,
    tapOrePerLevel: 1562500,
  ),
  TapUpgradeDef(
    id: 'eternal_miner',
    name: '영겁의 광부',
    description: '탭당 광석 +7.81M',
    icon: Icons.all_inclusive,
    accent: Color(0xFFEF9A9A),
    baseCost: 2700000000000,
    tapOrePerLevel: 7812500,
  ),
];

class TapUpgradeBalance {
  TapUpgradeBalance._();

  /// 비용 곡선 — 매 레벨 ×1.16 (이전 ×1.10 — 가파르게)
  static const double costGrowth = 1.16;

  static double upgradeCost(TapUpgradeDef def, int currentLevel) {
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

TapUpgradeDef tapUpgradeById(String id) =>
    kTapUpgrades.firstWhere((u) => u.id == id);
