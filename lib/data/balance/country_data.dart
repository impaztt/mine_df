import 'dart:math' as math;

import '../models/country.dart';

/// 광물 시세 거래소 — 6개국가, 광맥 등급별로 매입.
///
/// 각 국가는 광맥 등급 5개씩 묶어 매입한다. 후반 국가일수록 변동성이
/// 크고 사이클이 길어 — 큰 한 방을 노리고 기다리는 메타가 나온다.
const List<CountryDef> kCountries = [
  CountryDef(
    id: 'kr',
    name: '대한민국',
    flag: '🇰🇷',
    specialty: '광부 가문의 본거지. 기본 광석류를 안정적으로 매입.',
    minRank: 1,
    maxRank: 5,
    volatility: 0.30, // 0.70 ~ 1.30
    cycleMinutes: 4,
  ),
  CountryDef(
    id: 'jp',
    name: '일본',
    flag: '🇯🇵',
    specialty: '수정과 자수정의 명장. 가공 기술이 뛰어나다.',
    minRank: 6,
    maxRank: 10,
    volatility: 0.40, // 0.60 ~ 1.40
    cycleMinutes: 7,
  ),
  CountryDef(
    id: 'cn',
    name: '중국',
    flag: '🇨🇳',
    specialty: '에메랄드와 다이아몬드를 대량 거래.',
    minRank: 11,
    maxRank: 15,
    volatility: 0.50, // 0.50 ~ 1.50
    cycleMinutes: 12,
  ),
  CountryDef(
    id: 'in',
    name: '인도',
    flag: '🇮🇳',
    specialty: '전설의 얼음 광산을 거래하는 신비의 시장.',
    minRank: 16,
    maxRank: 20,
    volatility: 0.55, // 0.45 ~ 1.55
    cycleMinutes: 18,
  ),
  CountryDef(
    id: 'ru',
    name: '러시아',
    flag: '🇷🇺',
    specialty: '그림자석과 영혼옥의 신화급 광물 거래.',
    minRank: 21,
    maxRank: 25,
    volatility: 0.60, // 0.40 ~ 1.60
    cycleMinutes: 25,
  ),
  CountryDef(
    id: 'space',
    name: '우주연합',
    flag: '🌌',
    specialty: '천상의 광물을 거래하는 차원 너머의 시장.',
    minRank: 26,
    maxRank: 30,
    volatility: 0.70, // 0.30 ~ 1.70
    cycleMinutes: 40,
  ),
];

CountryDef countryById(String id) =>
    kCountries.firstWhere((c) => c.id == id);

/// 광맥 등급으로부터 매수 국가 ID
CountryDef? countryForRank(int rank) {
  for (final c in kCountries) {
    if (rank >= c.minRank && rank <= c.maxRank) return c;
  }
  return null;
}

/// 시세 배율 계산 — sin 기반 oscillation + 약간의 노이즈.
///
/// 결과값은 `(1 - vol) ~ (1 + vol)` 범위.
/// 사이클 길이는 분 단위, 노이즈는 ±5% 진폭의 랜덤.
double computePriceMultiplier({
  required CountryDef def,
  required int cycleStartedAt,
  required int nowMs,
  required int seed,
}) {
  if (cycleStartedAt == 0) return 1.0;
  final cycleMs = def.cycleMinutes * 60 * 1000;
  final phase = ((nowMs - cycleStartedAt) % cycleMs) / cycleMs;

  // 메인 sin 파동
  final mainAmp = def.volatility * 0.85;
  final main = mainAmp * math.sin(phase * math.pi * 2);

  // 약한 보조 파동 (3주기, 진폭 0.15) — 뾰족한 변동을 만듦
  final sub = def.volatility * 0.15 *
      math.sin(phase * math.pi * 6 + (seed % 10));

  // 시드 기반 노이즈 (±5%) — 매 분 결정적이지만 사람 눈엔 랜덤처럼 보임
  final noiseRng = math.Random(seed ^ (nowMs ~/ 60000));
  final noise = (noiseRng.nextDouble() - 0.5) * 0.10;

  return (1.0 + main + sub + noise).clamp(1 - def.volatility, 1 + def.volatility);
}
