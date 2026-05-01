import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../models/ore_type.dart';
import '../models/tier.dart';

/// M1 프로토타입 광물 (발사체 색상 / 등급)
const List<OreDef> kOres = [
  OreDef(
    id: 'rough_stone',
    name: '거친 돌',
    emoji: '🪨',
    tier: Tier.common,
    color: Color(0xFFB0A48C),
    unlockDay: 1,
    description: '광산 어디서나 발견되는 평범한 돌. 그래도 광부의 첫 친구.',
    damageMul: 1.0,
  ),
  OreDef(
    id: 'copper',
    name: '구리 광석',
    emoji: '🟫',
    tier: Tier.common,
    color: Color(0xFFB87333),
    unlockDay: 5,
    description: '따뜻한 빛깔의 광석. 광산 입구에서 흔히 발견된다.',
    damageMul: 1.3,
  ),
  OreDef(
    id: 'silver',
    name: '은 광석',
    emoji: '⚪',
    tier: Tier.common,
    color: Color(0xFFC0C0C0),
    unlockDay: 15,
    description: '달빛처럼 차가운 광택을 지닌 은.',
    damageMul: 1.7,
  ),
  OreDef(
    id: 'gold',
    name: '금 광석',
    emoji: '🟡',
    tier: Tier.rare,
    color: AppColors.gold,
    unlockDay: 30,
    description: '광부 가문의 자랑. 부드럽지만 무게가 묵직하다.',
    damageMul: 2.4,
  ),
  OreDef(
    id: 'crystal',
    name: '수정',
    emoji: '🔷',
    tier: Tier.rare,
    color: AppColors.crystalTeal,
    unlockDay: 50,
    description: '반투명하게 빛나는 수정. 적중 시 작게 분열한다.',
    damageMul: 3.2,
  ),
  OreDef(
    id: 'sapphire',
    name: '사파이어',
    emoji: '💙',
    tier: Tier.epic,
    color: Color(0xFF0F52BA),
    unlockDay: 120,
    description: '깊은 푸른 빛. 충돌 시 작은 얼음 파편을 흩뿌린다.',
    damageMul: 5.0,
  ),
];

OreDef? oreForDay(int day) {
  OreDef? best;
  for (final ore in kOres) {
    if (ore.unlockDay <= day) {
      best = ore;
    }
  }
  return best;
}
