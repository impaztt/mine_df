import 'package:flutter/material.dart';
import '../models/ore_type.dart';
import '../models/tier.dart';

/// 광석 등급 트리 (총 30종, T1 → T30).
///
/// `mineRank` 1 = 거친 돌, 2 = 구리 ... 30 = 별의 핵.
/// 광부는 한 번에 한 가지 광석만 캐고, 광맥(`mineRank`)을
/// 강화하면 다음 등급 광석으로 바뀐다.
const List<OreDef> kOres = [
  // ===== 1층: 입구 =====
  OreDef(
    id: 'rough_stone',
    name: '거친 돌',
    emoji: '🪨',
    tier: Tier.common,
    color: Color(0xFFB0A48C),
    coinValue: 1,
    description: '광산 어디서나 발견되는 평범한 돌. 그래도 광부의 첫 친구.',
  ),
  OreDef(
    id: 'copper',
    name: '구리 광석',
    emoji: '🟫',
    tier: Tier.common,
    color: Color(0xFFB87333),
    coinValue: 5,
    description: '따뜻한 빛깔의 광석. 광산 입구에서 흔히 발견된다.',
  ),
  OreDef(
    id: 'iron',
    name: '철 광석',
    emoji: '⬛',
    tier: Tier.common,
    color: Color(0xFF6B6E76),
    coinValue: 25,
    description: '튼튼한 광부 도구의 재료.',
  ),
  OreDef(
    id: 'silver',
    name: '은 광석',
    emoji: '⚪',
    tier: Tier.common,
    color: Color(0xFFC0C0C0),
    coinValue: 120,
    description: '달빛처럼 차가운 광택을 지닌 은.',
  ),
  OreDef(
    id: 'gold',
    name: '금 광석',
    emoji: '🟡',
    tier: Tier.rare,
    color: Color(0xFFFFC847),
    coinValue: 600,
    description: '광부 가문의 자랑. 부드럽지만 무게가 묵직하다.',
  ),

  // ===== 2층: 수정 동굴 =====
  OreDef(
    id: 'crystal',
    name: '수정',
    emoji: '🔷',
    tier: Tier.rare,
    color: Color(0xFF5DC5C5),
    coinValue: 3000,
    description: '반투명하게 빛나는 수정. 두드릴 때 맑은 소리가 난다.',
  ),
  OreDef(
    id: 'amethyst',
    name: '자수정',
    emoji: '💜',
    tier: Tier.rare,
    color: Color(0xFF9966CC),
    coinValue: 15000,
    description: '보랏빛 신비를 품은 보석.',
  ),
  OreDef(
    id: 'topaz',
    name: '황옥',
    emoji: '🟧',
    tier: Tier.rare,
    color: Color(0xFFFFC080),
    coinValue: 75000,
    description: '저녁노을을 그대로 굳혀둔 듯한 빛깔.',
  ),
  OreDef(
    id: 'sapphire',
    name: '사파이어',
    emoji: '💙',
    tier: Tier.epic,
    color: Color(0xFF0F52BA),
    coinValue: 380000,
    description: '깊은 푸른 빛. 별의 가루가 내려앉았다고 전해진다.',
  ),
  OreDef(
    id: 'ruby',
    name: '루비',
    emoji: '❤️',
    tier: Tier.epic,
    color: Color(0xFFE0115F),
    coinValue: 1900000,
    description: '꺼지지 않는 작은 불씨를 품은 광석.',
  ),

  // ===== 3층: 용암 광맥 =====
  OreDef(
    id: 'emerald',
    name: '에메랄드',
    emoji: '💚',
    tier: Tier.epic,
    color: Color(0xFF50C878),
    coinValue: 9500000,
    description: '깊은 숲의 정령이 숨겨둔 보석.',
  ),
  OreDef(
    id: 'diamond',
    name: '다이아몬드',
    emoji: '💎',
    tier: Tier.epic,
    color: Color(0xFFE8F4FF),
    coinValue: 47500000,
    description: '광부 가문 7대의 자부심. 가장 단단하고 가장 맑다.',
  ),
  OreDef(
    id: 'obsidian',
    name: '흑요석',
    emoji: '🖤',
    tier: Tier.legendary,
    color: Color(0xFF1B1B2A),
    coinValue: 240000000,
    description: '용암이 굳어 만들어진 어둠의 결정.',
  ),
  OreDef(
    id: 'aquamarine',
    name: '아쿠아마린',
    emoji: '🩵',
    tier: Tier.legendary,
    color: Color(0xFF7FFFD4),
    coinValue: 1200000000,
    description: '바다의 기억을 머금은 결정.',
  ),
  OreDef(
    id: 'opal',
    name: '오팔',
    emoji: '🌈',
    tier: Tier.legendary,
    color: Color(0xFFFF99CC),
    coinValue: 6000000000,
    description: '한 광석 안에 모든 색이 떠다닌다.',
  ),

  // ===== 4층: 얼음 광산 =====
  OreDef(
    id: 'ice_shard',
    name: '얼음 결정',
    emoji: '🧊',
    tier: Tier.legendary,
    color: Color(0xFFB8E0FF),
    coinValue: 30000000000,
    description: '천 년 묵은 얼음 광맥에서만 나온다.',
  ),
  OreDef(
    id: 'frostfire',
    name: '서리불꽃석',
    emoji: '❄️',
    tier: Tier.legendary,
    color: Color(0xFFA0E8FF),
    coinValue: 150000000000,
    description: '차가운데 안쪽에서 푸른 불이 일렁인다.',
  ),
  OreDef(
    id: 'moonstone',
    name: '월장석',
    emoji: '🌙',
    tier: Tier.legendary,
    color: Color(0xFFEEEAFC),
    coinValue: 750000000000,
    description: '달 조각이 떨어져 광맥에 박혔다는 전설의 광석.',
  ),
  OreDef(
    id: 'starlight',
    name: '별빛 결정',
    emoji: '✨',
    tier: Tier.legendary,
    color: Color(0xFFFFF4D6),
    coinValue: 3.75e12,
    description: '별이 떨어진 자리에서 자란 결정.',
  ),

  // ===== 5층: 그림자 영역 =====
  OreDef(
    id: 'shadowstone',
    name: '그림자석',
    emoji: '🌑',
    tier: Tier.mythic,
    color: Color(0xFF6E5C8C),
    coinValue: 1.9e13,
    description: '빛을 빨아들이는 어두운 광석. 만지면 차가움이 손끝에 오래 남는다.',
  ),
  OreDef(
    id: 'spirit_jade',
    name: '영혼옥',
    emoji: '🟢',
    tier: Tier.mythic,
    color: Color(0xFF7FE5A0),
    coinValue: 9.5e13,
    description: '산신령이 남긴 영험한 광석.',
  ),
  OreDef(
    id: 'dokkaebi_eye',
    name: '도깨비 눈',
    emoji: '👁️',
    tier: Tier.mythic,
    color: Color(0xFFC03BFF),
    coinValue: 4.7e14,
    description: '한밤중에 스스로 깜빡인다고 한다.',
  ),
  OreDef(
    id: 'phoenix_ember',
    name: '봉황의 불씨',
    emoji: '🔥',
    tier: Tier.mythic,
    color: Color(0xFFFF6B3B),
    coinValue: 2.4e15,
    description: '천 년에 한 번만 나타나는 광석.',
  ),
  OreDef(
    id: 'dragon_scale',
    name: '용비늘',
    emoji: '🐉',
    tier: Tier.mythic,
    color: Color(0xFF50FFB0),
    coinValue: 1.2e16,
    description: '잠든 용의 비늘이 떨어져 광맥이 되었다는 이야기.',
  ),

  // ===== 6층: 별의 핵 (환생 후) =====
  OreDef(
    id: 'celestial_dust',
    name: '천상의 가루',
    emoji: '🌠',
    tier: Tier.mythic,
    color: Color(0xFFFFC8FF),
    coinValue: 6.0e16,
    description: '별이 떨어진 자리의 마지막 가루.',
  ),
  OreDef(
    id: 'time_quartz',
    name: '시간 수정',
    emoji: '⏳',
    tier: Tier.mythic,
    color: Color(0xFF80E0FF),
    coinValue: 3.0e17,
    description: '결정 안에서 시간이 천천히 흐른다.',
  ),
  OreDef(
    id: 'dream_pearl',
    name: '꿈의 진주',
    emoji: '🤍',
    tier: Tier.mythic,
    color: Color(0xFFFFE9F2),
    coinValue: 1.5e18,
    description: '잠든 광부의 꿈이 모여 만들어진 진주.',
  ),
  OreDef(
    id: 'soul_crystal',
    name: '영혼 수정',
    emoji: '💠',
    tier: Tier.mythic,
    color: Color(0xFF80FFFF),
    coinValue: 7.5e18,
    description: '광부 가문 7대의 마음이 응축된 결정.',
  ),
  OreDef(
    id: 'cosmic_ore',
    name: '우주의 광석',
    emoji: '🌌',
    tier: Tier.mythic,
    color: Color(0xFFA0A0FF),
    coinValue: 3.75e19,
    description: '광산 가장 깊은 곳, 우주가 박혀 있다.',
  ),
  OreDef(
    id: 'star_core',
    name: '별의 핵',
    emoji: '⭐',
    tier: Tier.mythic,
    color: Color(0xFFFFF4D6),
    coinValue: 2.0e20,
    description: '별이 처음 떨어진 자리. 광부 가문의 가장 큰 비밀.',
  ),
];

/// `rank`(1-based)에 해당하는 광석. 범위를 벗어나면 마지막 광석 반환.
OreDef oreByRank(int rank) {
  final idx = (rank - 1).clamp(0, kOres.length - 1);
  return kOres[idx];
}

/// 광맥 등급 업그레이드 비용 — 다음 등급 광석을 약 250개 모은 가치.
///
/// 다음 광석 1개 가치는 보통 현재 광석의 4.5배쯤이라, 이 비용은
/// "다음 광석을 250개 캐서 팔아야 가능"한 수준. 여기에 곡괭이 데미지
/// 강화도 함께 필요하므로 광맥 강화는 큰 도약 이벤트로 작용한다.
double mineUpgradeCost(int currentRank) {
  if (currentRank >= kOres.length) return double.infinity;
  final nextValue = oreByRank(currentRank + 1).coinValue;
  return nextValue * 250;
}

/// 최대 광맥 등급
int get maxMineRank => kOres.length;
