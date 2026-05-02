import '../models/helper.dart';
import '../models/tier.dart';

/// 채굴 보조 조수 — 능력은 채굴/환전/크리티컬/대량채굴 등으로 변경됨.
const List<HelperDef> kHelpers = [
  HelperDef(
    id: 'mole_ddangkong',
    name: '두더지 땅콩',
    emoji: '🐹',
    tier: Tier.common,
    description: '곡괭이 데미지 +(레벨×8)%. 광부의 든든한 첫 친구.',
    baseDamageMul: 0.08,
    baseFireRateBonus: 0.0,
    recruitCost: 50,
    upgradeCost: 30,
  ),
  HelperDef(
    id: 'rabbit_dali',
    name: '흰토끼 달이',
    emoji: '🐰',
    tier: Tier.common,
    description: '광석 환전 +(레벨×6)%. 보름달 밤엔 능력이 두 배.',
    baseDamageMul: 0.06,
    baseFireRateBonus: 0.0,
    recruitCost: 250,
    upgradeCost: 150,
  ),
  HelperDef(
    id: 'magpie_chichi',
    name: '까치 치치',
    emoji: '🐦',
    tier: Tier.rare,
    description: '크리티컬 확률 +(레벨×1)%, 크리티컬 시 ×3. 운 좋은 까치.',
    baseDamageMul: 0.01,
    baseFireRateBonus: 0.0,
    recruitCost: 2500,
    upgradeCost: 1200,
  ),
  HelperDef(
    id: 'toad_bokshil',
    name: '두꺼비 복실',
    emoji: '🐸',
    tier: Tier.rare,
    description: '곡괭이 속도 +(레벨×3)%. 비 오는 날엔 능력이 두 배.',
    baseDamageMul: 0.0,
    baseFireRateBonus: 0.03,
    recruitCost: 8000,
    upgradeCost: 4000,
  ),
  HelperDef(
    id: 'tiger_beom',
    name: '호랑이 범',
    emoji: '🐯',
    tier: Tier.epic,
    description: '8초마다 강력한 일격(×10 데미지). 산속의 왕자.',
    baseDamageMul: 0.10,
    baseFireRateBonus: 0.0,
    recruitCost: 50000,
    upgradeCost: 25000,
  ),
  HelperDef(
    id: 'gumiho_yawol',
    name: '구미호 야월',
    emoji: '🦊',
    tier: Tier.epic,
    description: '(레벨×1.5)% 확률로 한 번에 ×2 광석. 신비로운 미소.',
    baseDamageMul: 0.015,
    baseFireRateBonus: 0.0,
    recruitCost: 250000,
    upgradeCost: 120000,
  ),
];

double helperDamageMul(HelperDef def, int level) {
  if (level <= 0) return 0;
  return def.baseDamageMul * level;
}

double helperFireBonus(HelperDef def, int level) {
  if (level <= 0) return 0;
  return def.baseFireRateBonus * level;
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
