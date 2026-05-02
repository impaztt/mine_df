import '../models/helper.dart';
import '../models/tier.dart';

/// 채굴 보조 조수 — 영입 비용은 다음 광맥 등급 가격대에 맞춰 조정.
///
/// 디자인:
/// - 조수 영입은 광맥 강화와 비슷한 "마일스톤" 이벤트로 의도
/// - 효과는 너무 강하지 않게 — 같은 비용을 곡괭이에 쓰는 것과 비교해 선택지가 됨
/// - 강화 비용 곡선은 ×1.25 (곡괭이 데미지와 동일한 가파름)
const List<HelperDef> kHelpers = [
  HelperDef(
    id: 'mole_ddangkong',
    name: '두더지 땅콩',
    emoji: '🐹',
    tier: Tier.common,
    description: '곡괭이 데미지 +(레벨×6)%. 광부의 든든한 첫 친구.',
    baseDamageMul: 0.06,
    baseFireRateBonus: 0.0,
    recruitCost: 200,
    upgradeCost: 80,
  ),
  HelperDef(
    id: 'rabbit_dali',
    name: '흰토끼 달이',
    emoji: '🐰',
    tier: Tier.common,
    description: '광석 환전 +(레벨×4)%. 보름달 밤엔 능력이 두 배.',
    baseDamageMul: 0.0,
    baseFireRateBonus: 0.0,
    recruitCost: 1500,
    upgradeCost: 600,
  ),
  HelperDef(
    id: 'magpie_chichi',
    name: '까치 치치',
    emoji: '🐦',
    tier: Tier.rare,
    description: '크리티컬 확률 +(레벨×0.8)%, 크리티컬 시 ×3.',
    baseDamageMul: 0.0,
    baseFireRateBonus: 0.0,
    recruitCost: 15000,
    upgradeCost: 6000,
  ),
  HelperDef(
    id: 'toad_bokshil',
    name: '두꺼비 복실',
    emoji: '🐸',
    tier: Tier.rare,
    description: '곡괭이 속도 +(레벨×2.5)%. 비 오는 날엔 능력이 두 배.',
    baseDamageMul: 0.0,
    baseFireRateBonus: 0.025,
    recruitCost: 80000,
    upgradeCost: 30000,
  ),
  HelperDef(
    id: 'tiger_beom',
    name: '호랑이 범',
    emoji: '🐯',
    tier: Tier.epic,
    description: '8초마다 강력한 일격(×10 데미지). 산속의 왕자.',
    baseDamageMul: 0.0,
    baseFireRateBonus: 0.0,
    recruitCost: 600000,
    upgradeCost: 250000,
  ),
  HelperDef(
    id: 'gumiho_yawol',
    name: '구미호 야월',
    emoji: '🦊',
    tier: Tier.epic,
    description: '(레벨×1.2)% 확률로 한 번에 ×2 광석. 신비로운 미소.',
    baseDamageMul: 0.0,
    baseFireRateBonus: 0.0,
    recruitCost: 4000000,
    upgradeCost: 1500000,
  ),
];

/// 데미지 보너스 (곡괭이 데미지 ×에 더해지는 비율)
double helperDamageMul(HelperDef def, int level) {
  if (level <= 0) return 0;
  return def.baseDamageMul * level;
}

/// 속도 보너스 (곡괭이 속도 ×에 더해지는 비율)
double helperFireBonus(HelperDef def, int level) {
  if (level <= 0) return 0;
  return def.baseFireRateBonus * level;
}

/// 조수 강화 비용 — 매 레벨 ×1.25
double helperUpgradeCost(HelperDef def, int level) {
  return def.upgradeCost * _pow(1.25, level);
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
