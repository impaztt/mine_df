/// 광물 시세 거래소 — 국가 정의.
///
/// 각 국가는 특정 광석 등급 범위를 매수한다. 시세 배율은 시간에 따라
/// 변동하며, 시세가 좋을 때 그 국가에 광석을 팔면 추가 코인을 받는다.
class CountryDef {
  final String id;
  final String name;
  final String flag;
  final String specialty;

  /// 매수 가능한 광석 등급 범위 (mineRank 기준, inclusive).
  final int minRank;
  final int maxRank;

  /// 평균 시세 배율의 진폭 (예: 0.4면 시세가 0.6~1.4 사이에서 변동)
  final double volatility;

  /// 한 사이클 길이 (분) — 이 시간 동안 한 번 oscillation
  final int cycleMinutes;

  const CountryDef({
    required this.id,
    required this.name,
    required this.flag,
    required this.specialty,
    required this.minRank,
    required this.maxRank,
    required this.volatility,
    required this.cycleMinutes,
  });
}

/// 국가의 동적 상태 — 현재 시세 배율 + 마지막 갱신 시각.
class CountryState {
  final String id;

  /// 현재 시세 배율 (1.0 = 정상가)
  final double priceMultiplier;

  /// 마지막 갱신 시각 (epoch ms)
  final int lastUpdatedAt;

  /// 사이클 시작 시각 — 시세 oscillation 위상 계산용
  final int cycleStartedAt;

  /// 누적 거래 횟수 (도감/통계용)
  final int totalTrades;

  /// 누적 거래량 (코인 기준)
  final double totalRevenue;

  const CountryState({
    required this.id,
    this.priceMultiplier = 1.0,
    this.lastUpdatedAt = 0,
    this.cycleStartedAt = 0,
    this.totalTrades = 0,
    this.totalRevenue = 0,
  });

  CountryState copyWith({
    double? priceMultiplier,
    int? lastUpdatedAt,
    int? cycleStartedAt,
    int? totalTrades,
    double? totalRevenue,
  }) =>
      CountryState(
        id: id,
        priceMultiplier: priceMultiplier ?? this.priceMultiplier,
        lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
        cycleStartedAt: cycleStartedAt ?? this.cycleStartedAt,
        totalTrades: totalTrades ?? this.totalTrades,
        totalRevenue: totalRevenue ?? this.totalRevenue,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'priceMultiplier': priceMultiplier,
        'lastUpdatedAt': lastUpdatedAt,
        'cycleStartedAt': cycleStartedAt,
        'totalTrades': totalTrades,
        'totalRevenue': totalRevenue,
      };

  factory CountryState.fromJson(Map<String, dynamic> j) => CountryState(
        id: j['id'] as String,
        priceMultiplier:
            (j['priceMultiplier'] as num?)?.toDouble() ?? 1.0,
        lastUpdatedAt: j['lastUpdatedAt'] as int? ?? 0,
        cycleStartedAt: j['cycleStartedAt'] as int? ?? 0,
        totalTrades: j['totalTrades'] as int? ?? 0,
        totalRevenue: (j['totalRevenue'] as num?)?.toDouble() ?? 0,
      );
}
