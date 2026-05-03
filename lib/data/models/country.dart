/// 국가별 광산 지분 거래소 — 정의 (정적 데이터).
///
/// 각 국가는 광맥 등급 5단계씩 매입 + 자체 주식이 거래된다.
/// 1주 가격은 매 1초마다 변동하며, 보유 주식 가치 = 주식 수 × 현재가.
class CountryDef {
  final String id;
  final String name;
  final String flag;
  final String specialty;

  /// 매수 가능한 광석 등급 범위 (광석 즉시 매도용)
  final int minRank;
  final int maxRank;

  /// 광맥 등급 평균 가치를 계산해서 1주 가격을 결정하는 데 쓰는 기준값
  final double intrinsicPrice;

  /// 발행 주식 총수 — UI에 보여주기만 하는 정보성
  final int totalShares;

  /// 1초당 변동성 (σ%, 예: 0.012 = 1.2%)
  final double tickVolatility;

  /// 시세가 base에 끌려가는 강도 (0.005 = 매 초 0.5% 회귀)
  final double meanReversion;

  /// 큰 사이클 (분 단위) — 메인 oscillation
  final int cycleMinutes;

  /// 시세가 intrinsicPrice의 몇 배까지 갈 수 있는가
  final double maxPriceMultiplier;

  /// 하한 — intrinsicPrice의 몇 배까지 떨어질 수 있는가
  final double minPriceMultiplier;

  const CountryDef({
    required this.id,
    required this.name,
    required this.flag,
    required this.specialty,
    required this.minRank,
    required this.maxRank,
    required this.intrinsicPrice,
    required this.totalShares,
    required this.tickVolatility,
    required this.meanReversion,
    required this.cycleMinutes,
    required this.maxPriceMultiplier,
    required this.minPriceMultiplier,
  });
}

/// 국가의 동적 상태 — 현재 1주 가격 + 보유 주식 + 가격 히스토리.
class CountryState {
  final String id;

  /// 현재 1주 가격
  final double price;

  /// 사용자가 보유 중인 주식 수
  final int shares;

  /// 보유 주식의 평균 매입가 (손익 계산용)
  final double avgCost;

  /// 가격 히스토리 — 최근 60틱(=60초) 1주 가격, 신규가 끝
  final List<double> priceHistory;

  /// 마지막 가격 갱신 시각 (epoch ms)
  final int lastTickAt;

  /// 사이클 시작 시각 — sin 위상 계산용
  final int cycleStartedAt;

  /// 통계
  final int totalTrades;
  final double totalRealizedProfit;

  const CountryState({
    required this.id,
    required this.price,
    this.shares = 0,
    this.avgCost = 0,
    this.priceHistory = const [],
    this.lastTickAt = 0,
    this.cycleStartedAt = 0,
    this.totalTrades = 0,
    this.totalRealizedProfit = 0,
  });

  /// 시세 배율 = price / intrinsicPrice
  double priceMultiplier(double intrinsicPrice) =>
      intrinsicPrice <= 0 ? 1.0 : price / intrinsicPrice;

  /// 평가 손익 (보유 주식 × (현재가 - 평균가))
  double unrealizedPnL() =>
      shares <= 0 ? 0 : shares * (price - avgCost);

  CountryState copyWith({
    double? price,
    int? shares,
    double? avgCost,
    List<double>? priceHistory,
    int? lastTickAt,
    int? cycleStartedAt,
    int? totalTrades,
    double? totalRealizedProfit,
  }) =>
      CountryState(
        id: id,
        price: price ?? this.price,
        shares: shares ?? this.shares,
        avgCost: avgCost ?? this.avgCost,
        priceHistory: priceHistory ?? this.priceHistory,
        lastTickAt: lastTickAt ?? this.lastTickAt,
        cycleStartedAt: cycleStartedAt ?? this.cycleStartedAt,
        totalTrades: totalTrades ?? this.totalTrades,
        totalRealizedProfit:
            totalRealizedProfit ?? this.totalRealizedProfit,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'price': price,
        'shares': shares,
        'avgCost': avgCost,
        'priceHistory': priceHistory,
        'lastTickAt': lastTickAt,
        'cycleStartedAt': cycleStartedAt,
        'totalTrades': totalTrades,
        'totalRealizedProfit': totalRealizedProfit,
      };

  factory CountryState.fromJson(Map<String, dynamic> j) => CountryState(
        id: j['id'] as String,
        price: (j['price'] as num?)?.toDouble() ?? 0,
        shares: (j['shares'] as num?)?.toInt() ?? 0,
        avgCost: (j['avgCost'] as num?)?.toDouble() ?? 0,
        priceHistory: ((j['priceHistory'] as List?) ?? const [])
            .map((e) => (e as num).toDouble())
            .toList(),
        lastTickAt: j['lastTickAt'] as int? ?? 0,
        cycleStartedAt: j['cycleStartedAt'] as int? ?? 0,
        totalTrades: (j['totalTrades'] as num?)?.toInt() ?? 0,
        totalRealizedProfit:
            (j['totalRealizedProfit'] as num?)?.toDouble() ?? 0,
      );
}
