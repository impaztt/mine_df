import 'dart:math' as math;

import '../models/country.dart';

/// 국가별 광산 지분 거래소.
///
/// 각 국가는 광맥 등급 5단계씩 매입(광석 즉시 매도) + 자체 주식 거래.
/// intrinsicPrice는 1주 기본가, totalShares는 UI 정보용 발행량.
const List<CountryDef> kCountries = [
  CountryDef(
    id: 'kr',
    name: '대한민국',
    flag: '🇰🇷',
    specialty: '광부 가문의 본거지. 안정적인 기본 광석류 거래.',
    minRank: 1,
    maxRank: 5,
    intrinsicPrice: 1500,
    totalShares: 10000000,
    tickVolatility: 0.010,
    meanReversion: 0.006,
    cycleMinutes: 4,
    maxPriceMultiplier: 3.0,
    minPriceMultiplier: 0.4,
  ),
  CountryDef(
    id: 'jp',
    name: '일본',
    flag: '🇯🇵',
    specialty: '수정과 자수정의 가공 명장. 정교한 시장.',
    minRank: 6,
    maxRank: 10,
    intrinsicPrice: 25000,
    totalShares: 10000000,
    tickVolatility: 0.013,
    meanReversion: 0.005,
    cycleMinutes: 7,
    maxPriceMultiplier: 4.0,
    minPriceMultiplier: 0.35,
  ),
  CountryDef(
    id: 'cn',
    name: '중국',
    flag: '🇨🇳',
    specialty: '에메랄드와 다이아몬드를 대량 거래.',
    minRank: 11,
    maxRank: 15,
    intrinsicPrice: 800000,
    totalShares: 10000000,
    tickVolatility: 0.016,
    meanReversion: 0.004,
    cycleMinutes: 12,
    maxPriceMultiplier: 5.0,
    minPriceMultiplier: 0.30,
  ),
  CountryDef(
    id: 'in',
    name: '인도',
    flag: '🇮🇳',
    specialty: '얼음 광산을 거래하는 신비의 시장.',
    minRank: 16,
    maxRank: 20,
    intrinsicPrice: 35000000,
    totalShares: 10000000,
    tickVolatility: 0.018,
    meanReversion: 0.003,
    cycleMinutes: 18,
    maxPriceMultiplier: 6.0,
    minPriceMultiplier: 0.25,
  ),
  CountryDef(
    id: 'ru',
    name: '러시아',
    flag: '🇷🇺',
    specialty: '그림자석과 영혼옥의 신화급 거래.',
    minRank: 21,
    maxRank: 25,
    intrinsicPrice: 2.5e9,
    totalShares: 10000000,
    tickVolatility: 0.020,
    meanReversion: 0.0025,
    cycleMinutes: 25,
    maxPriceMultiplier: 8.0,
    minPriceMultiplier: 0.20,
  ),
  CountryDef(
    id: 'space',
    name: '우주연합',
    flag: '🌌',
    specialty: '천상의 광물을 거래하는 차원 너머의 시장.',
    minRank: 26,
    maxRank: 30,
    intrinsicPrice: 1.5e11,
    totalShares: 10000000,
    tickVolatility: 0.025,
    meanReversion: 0.002,
    cycleMinutes: 40,
    maxPriceMultiplier: 12.0,
    minPriceMultiplier: 0.15,
  ),
];

CountryDef countryById(String id) =>
    kCountries.firstWhere((c) => c.id == id);

CountryDef? countryForRank(int rank) {
  for (final c in kCountries) {
    if (rank >= c.minRank && rank <= c.maxRank) return c;
  }
  return null;
}

/// 거래 수수료 (매수/매도 양쪽에 적용)
const double kStockTradeFee = 0.02;

/// 가격 히스토리 보관 길이 (초)
const int kPriceHistoryLength = 60;

/// 매 초 한 번 호출 — 다음 1주 가격을 결정.
///
/// 모델: 평균회귀 랜덤워크 + sin 사이클
///   delta = sin사이클 + tickVolatility × randn − meanReversion × (price/base − 1)
///   newPrice = clamp(price × (1 + delta), base × min, base × max)
double nextPriceTick({
  required CountryDef def,
  required double currentPrice,
  required int cycleStartedAt,
  required int nowMs,
  required math.Random rng,
}) {
  if (currentPrice <= 0) return def.intrinsicPrice;

  // 1) sin 사이클 (느린 트렌드, ±1% 진폭)
  final cycleMs = def.cycleMinutes * 60 * 1000;
  final phase =
      cycleMs <= 0 ? 0.0 : ((nowMs - cycleStartedAt) % cycleMs) / cycleMs;
  final cycle = 0.010 * math.sin(phase * math.pi * 2);

  // 2) 가우시안 노이즈 — Box-Muller
  final u1 = math.max(rng.nextDouble(), 1e-9);
  final u2 = rng.nextDouble();
  final randn =
      math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
  final shock = def.tickVolatility * randn;

  // 3) 평균 회귀 — 가격이 base에서 벗어나면 끌려옴
  final deviation = currentPrice / def.intrinsicPrice - 1.0;
  final pull = -def.meanReversion * deviation;

  final delta = cycle + shock + pull;
  double next = currentPrice * (1 + delta);

  // 4) 상하한 clamp
  final minP = def.intrinsicPrice * def.minPriceMultiplier;
  final maxP = def.intrinsicPrice * def.maxPriceMultiplier;
  if (next < minP) next = minP;
  if (next > maxP) next = maxP;
  return next;
}
