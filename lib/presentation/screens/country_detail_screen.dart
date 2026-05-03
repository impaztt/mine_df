import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../core/utils/big_number.dart';
import '../../data/balance/country_data.dart';
import '../../data/models/country.dart';
import '../providers/game_provider.dart';

/// 국가 상세 화면 — 가격 차트 + 매수/매도 + 광석 즉시 매도.
class CountryDetailScreen extends ConsumerStatefulWidget {
  const CountryDetailScreen({super.key, required this.countryId});
  final String countryId;

  @override
  ConsumerState<CountryDetailScreen> createState() =>
      _CountryDetailScreenState();
}

class _CountryDetailScreenState
    extends ConsumerState<CountryDetailScreen> {
  int _orderShares = 1;

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider);
    final state = game.state;
    final c = countryById(widget.countryId);
    final market = state.markets[widget.countryId];
    if (market == null) {
      return const Scaffold(body: Center(child: Text('시세 미초기화')));
    }

    return Scaffold(
      backgroundColor: AppColors.deepShaft,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        title: Row(
          children: [
            Text(c.flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              c.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: [
            _PriceCard(country: c, market: market),
            const SizedBox(height: 12),
            _Sparkline(market: market, intrinsic: c.intrinsicPrice),
            const SizedBox(height: 12),
            _HoldingsCard(country: c, market: market),
            const SizedBox(height: 12),
            _OrderCard(
              country: c,
              market: market,
              shares: _orderShares,
              onSharesChanged: (v) => setState(() => _orderShares = v),
              maxBuy: game.maxBuyableShares(widget.countryId),
              coin: state.coin,
              onBuy: () {
                final r = game.buyShares(widget.countryId, _orderShares);
                _showResult(context, r, isBuy: true);
              },
              onSell: () {
                final r = game.sellShares(widget.countryId, _orderShares);
                _showResult(context, r, isBuy: false);
              },
            ),
            const SizedBox(height: 12),
            _OreSpotSell(country: c, market: market, game: game),
          ],
        ),
      ),
    );
  }

  void _showResult(BuildContext context, ActionResult r,
      {required bool isBuy}) {
    if (!r.ok && r.message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(r.message!),
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }
    if (r.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isBuy
                ? '매수 ${r.times}주 (-${BigNumberFormat.format(r.cost)} 코인)'
                : '매도 ${r.times}주 (+${BigNumberFormat.format(r.cost)} 코인)',
          ),
          duration: const Duration(seconds: 1),
          backgroundColor:
              isBuy ? AppColors.crystalTeal : const Color(0xFFFF6B5C),
        ),
      );
    }
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.country, required this.market});
  final CountryDef country;
  final CountryState market;

  @override
  Widget build(BuildContext context) {
    final mult = market.priceMultiplier(country.intrinsicPrice);
    final color = _priceColor(mult);
    final hist = market.priceHistory;
    final prev = hist.length >= 2 ? hist[hist.length - 2] : market.price;
    final delta = market.price - prev;
    final pct = prev > 0 ? (delta / prev * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.monetization_on_outlined,
                  color: AppColors.gold, size: 20),
              const SizedBox(width: 6),
              Text(
                BigNumberFormat.format(market.price),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      delta >= 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: color,
                      size: 13,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${delta >= 0 ? "+" : ""}${pct.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '기준가 ${BigNumberFormat.format(country.intrinsicPrice)} · 시세 ×${mult.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            country.specialty,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// 가격 OHLC 봉 1개 (10초 단위로 묶음)
class _Candle {
  final double open;
  final double high;
  final double low;
  final double close;
  const _Candle(this.open, this.high, this.low, this.close);
}

/// 1초 가격 히스토리를 [kCandleSeconds]초 단위로 묶어 OHLC 캔들 리스트로 변환.
/// 가장 최근 부분이 [kCandleSeconds]초가 안 차면 진행 중 봉으로 포함.
List<_Candle> _buildCandles(List<double> history) {
  if (history.isEmpty) return const [];
  final candles = <_Candle>[];
  for (int start = 0; start < history.length; start += kCandleSeconds) {
    final end = (start + kCandleSeconds).clamp(0, history.length);
    if (end <= start) break;
    double o = history[start];
    double h = o, l = o, c = o;
    for (int i = start; i < end; i++) {
      final v = history[i];
      if (v > h) h = v;
      if (v < l) l = v;
      c = v;
    }
    candles.add(_Candle(o, h, l, c));
  }
  return candles;
}

class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.market, required this.intrinsic});
  final CountryState market;
  final double intrinsic;

  @override
  Widget build(BuildContext context) {
    final candles = _buildCandles(market.priceHistory);
    return Container(
      height: 160,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '10초 봉',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '· ${candles.length}봉 (최대 10분)',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: candles.isEmpty
                ? const Center(
                    child: Text(
                      '가격 데이터 수집 중…',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : CustomPaint(
                    size: Size.infinite,
                    painter: _CandlePainter(
                      candles: candles,
                      intrinsic: intrinsic,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CandlePainter extends CustomPainter {
  _CandlePainter({required this.candles, required this.intrinsic});
  final List<_Candle> candles;
  final double intrinsic;

  static const Color _upColor = Color(0xFFFF6B5C); // 한국식 빨강 = 상승
  static final Color _downColor = AppColors.crystalTeal;

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    // 가격 범위 계산 — 모든 봉의 high/low + 기준가 포함
    double minV = candles.first.low;
    double maxV = candles.first.high;
    for (final c in candles) {
      if (c.low < minV) minV = c.low;
      if (c.high > maxV) maxV = c.high;
    }
    if (intrinsic > maxV) maxV = intrinsic;
    if (intrinsic < minV) minV = intrinsic;
    // 위아래 5% 패딩
    final pad = (maxV - minV) * 0.05;
    minV -= pad;
    maxV += pad;
    final range = (maxV - minV).abs() < 1e-9 ? 1.0 : (maxV - minV);

    double yFor(double v) =>
        size.height - ((v - minV) / range) * size.height;

    // 봉 폭 (간격 포함)
    final slot = size.width / candles.length;
    final bodyW = (slot * 0.7).clamp(2.0, 14.0);

    // 기준가 점선
    final basePaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    final baseY = yFor(intrinsic);
    for (double x = 0; x < size.width; x += 6) {
      canvas.drawLine(
        Offset(x, baseY),
        Offset(x + 3, baseY),
        basePaint,
      );
    }

    // 봉 그리기
    for (int i = 0; i < candles.length; i++) {
      final c = candles[i];
      final isUp = c.close >= c.open;
      final color = isUp ? _upColor : _downColor;
      final cx = slot * (i + 0.5);

      // 꼬리 (high ↔ low)
      canvas.drawLine(
        Offset(cx, yFor(c.high)),
        Offset(cx, yFor(c.low)),
        Paint()
          ..color = color
          ..strokeWidth = 1.4,
      );

      // 몸통 (open ↔ close)
      final yOpen = yFor(c.open);
      final yClose = yFor(c.close);
      final top = yOpen < yClose ? yOpen : yClose;
      final bottom = yOpen < yClose ? yClose : yOpen;
      final bodyRect = Rect.fromLTRB(
        cx - bodyW / 2,
        top,
        cx + bodyW / 2,
        // 몸통이 너무 얇으면 최소 1px 보장
        (bottom - top) < 1 ? top + 1 : bottom,
      );
      canvas.drawRect(bodyRect, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _CandlePainter old) =>
      old.candles != candles;
}

class _HoldingsCard extends StatelessWidget {
  const _HoldingsCard({required this.country, required this.market});
  final CountryDef country;
  final CountryState market;

  @override
  Widget build(BuildContext context) {
    final value = market.shares * market.price;
    final pnl = market.unrealizedPnL();
    final pnlPct = market.shares > 0 && market.avgCost > 0
        ? (market.price / market.avgCost - 1) * 100
        : 0.0;
    final pnlColor =
        pnl >= 0 ? const Color(0xFFFF6B5C) : AppColors.crystalTeal;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '나의 보유',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          if (market.shares == 0)
            const Text(
              '아직 보유한 주식이 없습니다',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            )
          else ...[
            Row(
              children: [
                _Cell(
                  label: '보유 주식',
                  value: '${BigNumberFormat.format(market.shares.toDouble())}주',
                ),
                _Cell(
                  label: '평균가',
                  value: BigNumberFormat.format(market.avgCost),
                ),
                _Cell(
                  label: '평가액',
                  value: BigNumberFormat.format(value),
                  color: AppColors.gold,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: pnlColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    pnl >= 0
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    color: pnlColor,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '평가 손익 ${pnl >= 0 ? "+" : ""}${BigNumberFormat.format(pnl)} '
                    '(${pnlPct >= 0 ? "+" : ""}${pnlPct.toStringAsFixed(2)}%)',
                    style: TextStyle(
                      fontSize: 12,
                      color: pnlColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.label,
    required this.value,
    this.color = AppColors.starlightCream,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.country,
    required this.market,
    required this.shares,
    required this.onSharesChanged,
    required this.maxBuy,
    required this.coin,
    required this.onBuy,
    required this.onSell,
  });

  final CountryDef country;
  final CountryState market;
  final int shares;
  final ValueChanged<int> onSharesChanged;
  final int maxBuy;
  final double coin;
  final VoidCallback onBuy;
  final VoidCallback onSell;

  @override
  Widget build(BuildContext context) {
    final unitBuy = market.price * (1 + 0.02);
    final unitSell = market.price * (1 - 0.02);
    final canBuy = shares > 0 && coin >= shares * unitBuy;
    final canSell = shares > 0 && market.shares >= shares;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '매수 / 매도 (수수료 2%)',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          // 수량 표시
          Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.dividerColor),
            ),
            child: Text(
              '${BigNumberFormat.format(shares.toDouble())} 주',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 6),
          // 슬라이더 — 1 ~ max(MAX매수, 보유주식, 1)
          _SharesSlider(
            value: shares,
            maxBuy: maxBuy,
            owned: market.shares,
            onChanged: onSharesChanged,
          ),
          const SizedBox(height: 4),
          // ± 빠른 조정 버튼
          Row(
            children: [
              _qtyButton('-100',
                  () => onSharesChanged((shares - 100).clamp(1, 1 << 30))),
              const SizedBox(width: 4),
              _qtyButton('-10',
                  () => onSharesChanged((shares - 10).clamp(1, 1 << 30))),
              const SizedBox(width: 4),
              _qtyButton(
                  '-1', () => onSharesChanged((shares - 1).clamp(1, 1 << 30))),
              const SizedBox(width: 4),
              _qtyButton('+1', () => onSharesChanged(shares + 1)),
              const SizedBox(width: 4),
              _qtyButton('+10', () => onSharesChanged(shares + 10)),
              const SizedBox(width: 4),
              _qtyButton('+100', () => onSharesChanged(shares + 100)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _qtyButton(
                'MAX 매수',
                () {
                  if (maxBuy > 0) onSharesChanged(maxBuy);
                },
                color: AppColors.crystalTeal,
                expanded: true,
              ),
              const SizedBox(width: 6),
              _qtyButton(
                '전량 매도',
                () {
                  if (market.shares > 0) onSharesChanged(market.shares);
                },
                color: const Color(0xFFFF6B5C),
                expanded: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 매수/매도 버튼
          Row(
            children: [
              Expanded(
                child: _bigButton(
                  label: '매수',
                  subLabel:
                      '${BigNumberFormat.format(shares * unitBuy)} 코인',
                  color: AppColors.crystalTeal,
                  enabled: canBuy,
                  onTap: onBuy,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _bigButton(
                  label: '매도',
                  subLabel:
                      '${BigNumberFormat.format(shares * unitSell)} 코인',
                  color: const Color(0xFFFF6B5C),
                  enabled: canSell,
                  onTap: onSell,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyButton(String label, VoidCallback onTap,
      {Color color = AppColors.dividerColor, bool expanded = false}) {
    final btn = InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color == AppColors.dividerColor
              ? AppColors.cardBackground
              : color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color == AppColors.dividerColor
                ? AppColors.dividerColor
                : color,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: color == AppColors.dividerColor
                ? AppColors.textPrimary
                : color,
          ),
        ),
      ),
    );
    return expanded ? Expanded(child: btn) : btn;
  }

  Widget _bigButton({
    required String label,
    required String subLabel,
    required Color color,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: enabled ? color : AppColors.dividerColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onTap : null,
        child: Container(
          height: 50,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: enabled ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subLabel,
                style: TextStyle(
                  fontSize: 10,
                  color: enabled
                      ? Colors.white.withValues(alpha: 0.85)
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OreSpotSell extends StatelessWidget {
  const _OreSpotSell({
    required this.country,
    required this.market,
    required this.game,
  });
  final CountryDef country;
  final CountryState market;
  final GameProvider game;

  @override
  Widget build(BuildContext context) {
    final kinds = game.countryEligibleOreKinds(country.id);
    final revenue = game.previewOreSellRevenue(country.id);
    final canSell = kinds > 0;
    final mult = market.priceMultiplier(country.intrinsicPrice);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined,
                  size: 16, color: AppColors.gold),
              const SizedBox(width: 6),
              const Text(
                '광석 즉시 매도',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                '광맥 ${country.minRank}~${country.maxRank}등급',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            canSell
                ? '$kinds종 광석을 시세 ×${mult.toStringAsFixed(2)}로 매도'
                : '해당 등급의 보유 광석이 없습니다',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: canSell
                ? () {
                    final r = game.sellAllOreToCountry(country.id);
                    if (!r.ok && r.message != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(r.message!),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    } else if (r.ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '광석 매도 +${BigNumberFormat.format(r.cost)} 코인',
                          ),
                          duration: const Duration(seconds: 1),
                          backgroundColor: AppColors.gold,
                        ),
                      );
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  canSell ? AppColors.gold : AppColors.dividerColor,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 40),
            ),
            child: Text(
              canSell
                  ? '광석 일괄 매도 (+${BigNumberFormat.format(revenue)})'
                  : '매도할 광석 없음',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _priceColor(double mult) {
  if (mult >= 1.30) return const Color(0xFFFF6B5C);
  if (mult >= 1.10) return const Color(0xFFFFD86E);
  if (mult >= 0.90) return AppColors.crystalTeal;
  if (mult >= 0.70) return AppColors.textSecondary;
  return const Color(0xFF6E5C8C);
}

/// 매수/매도 수량을 좌우로 부드럽게 조절하는 슬라이더.
///
/// 범위는 1 ~ max(MAX매수, 보유주식, 1). 매수도 매도도 같은 슬라이더로
/// 조절 가능하므로 두 액션의 더 큰 값을 상한으로 잡는다.
class _SharesSlider extends StatelessWidget {
  const _SharesSlider({
    required this.value,
    required this.maxBuy,
    required this.owned,
    required this.onChanged,
  });

  final int value;
  final int maxBuy;
  final int owned;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final upper = [maxBuy, owned, 1]
        .reduce((a, b) => a > b ? a : b);
    final clamped = value.clamp(1, upper);
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 4,
        activeTrackColor: AppColors.gold,
        inactiveTrackColor: AppColors.dividerColor,
        thumbColor: AppColors.gold,
        overlayColor: AppColors.gold.withValues(alpha: 0.18),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
      ),
      child: Slider(
        value: clamped.toDouble(),
        min: 1,
        max: upper.toDouble(),
        divisions: upper > 1 ? (upper - 1).clamp(1, 10000) : null,
        onChanged: upper > 1
            ? (v) => onChanged(v.round().clamp(1, upper))
            : null,
      ),
    );
  }
}
