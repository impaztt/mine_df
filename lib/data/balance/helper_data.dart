import '../models/helper.dart';
import '../models/tier.dart';

/// M1 프로토타입 조수 — 추후 30+ 종으로 확장 (기획서 4.4)
const List<HelperDef> kHelpers = [
  HelperDef(
    id: 'mole_ddangkong',
    name: '두더지 땅콩',
    emoji: '🐹',
    tier: Tier.common,
    description: '지하에서 출현하는 적을 우선 처치. 레벨업 시 공격력 증가.',
    baseDamageMul: 0.20,
    baseFireRateBonus: 0.10,
    recruitCost: 50,
    upgradeCost: 30,
  ),
  HelperDef(
    id: 'rabbit_dali',
    name: '흰토끼 달이',
    emoji: '🐰',
    tier: Tier.common,
    description: '뛰어다니며 광물을 자동 회수. 코인 획득 +20%.',
    baseDamageMul: 0.15,
    baseFireRateBonus: 0.20,
    recruitCost: 250,
    upgradeCost: 150,
  ),
  HelperDef(
    id: 'magpie_chichi',
    name: '까치 치치',
    emoji: '🐦',
    tier: Tier.rare,
    description: '공중 적 우선 처치 (1.5배 데미지). 운 좋은 날엔 코인 추가.',
    baseDamageMul: 0.40,
    baseFireRateBonus: 0.25,
    recruitCost: 2500,
    upgradeCost: 1200,
  ),
  HelperDef(
    id: 'tiger_beom',
    name: '호랑이 범',
    emoji: '🐯',
    tier: Tier.epic,
    description: '일정 시간마다 돌진하여 직선상 모든 적을 격퇴. 보스전 +30%.',
    baseDamageMul: 1.00,
    baseFireRateBonus: 0.40,
    recruitCost: 50000,
    upgradeCost: 25000,
  ),
];

double helperDamageMul(HelperDef def, int level) {
  if (level <= 0) return 0;
  return def.baseDamageMul * (1 + (level - 1) * 0.12);
}

double helperFireBonus(HelperDef def, int level) {
  if (level <= 0) return 0;
  return def.baseFireRateBonus * (1 + (level - 1) * 0.08);
}

double helperUpgradeCost(HelperDef def, int level) {
  return def.upgradeCost * _pow(1.18, level);
}

double _pow(double b, int e) {
  double r = 1;
  for (int i = 0; i < e; i++) {
    r *= b;
  }
  return r;
}

HelperDef helperById(String id) =>
    kHelpers.firstWhere((h) => h.id == id);
