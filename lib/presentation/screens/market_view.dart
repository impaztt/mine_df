import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../core/utils/big_number.dart';
import '../../data/balance/country_data.dart';
import '../../data/models/country.dart';
import '../providers/game_provider.dart';
import 'country_detail_screen.dart';

/// 광산 지분 거래소 — 6개국가 카드 리스트.
/// 카드 탭 → 상세 화면 (매수/매도 + 차트).
class MarketView extends ConsumerWidget {
  const MarketView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final state = game.state;

    // 총 보유 평가액
    double totalValue = 0;
    double totalPnL = 0;
    for (final m in state.markets.values) {
      totalValue += m.shares * m.price;
      totalPnL += m.unrealizedPnL();
    }
    final pnlColor =
        totalPnL >= 0 ? const Color(0xFFFF6B5C) : AppColors.crystalTeal;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        // 포트폴리오 요약
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2A2540), Color(0xFF1A1B3A)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.crystalTeal.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.public, color: AppColors.crystalTeal),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '광산 지분 거래소',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '평가액 ${BigNumberFormat.format(totalValue)} · '
                      '손익 ${totalPnL >= 0 ? "+" : ""}${BigNumberFormat.format(totalPnL)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: pnlColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text(
            '카드를 탭하면 매수/매도 화면으로 이동합니다',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        for (final c in kCountries) ...[
          _CountryRow(
            country: c,
            market: state.markets[c.id],
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      CountryDetailScreen(countryId: c.id),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _CountryRow extends StatelessWidget {
  const _CountryRow({
    required this.country,
    required this.market,
    required this.onTap,
  });
  final CountryDef country;
  final CountryState? market;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (market == null) {
      return const SizedBox.shrink();
    }
    final m = market!;
    final mult = m.priceMultiplier(country.intrinsicPrice);
    final color = _priceColor(mult);
    final hist = m.priceHistory;
    final prev = hist.length >= 2 ? hist[hist.length - 2] : m.price;
    final delta = m.price - prev;
    final pct = prev > 0 ? (delta / prev * 100) : 0.0;
    final value = m.shares * m.price;
    final pnl = m.unrealizedPnL();

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackgroundLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1행: 국기 + 이름 + 가격
            Row(
              children: [
                Text(country.flag, style: const TextStyle(fontSize: 30)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        country.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
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
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      BigNumberFormat.format(m.price),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.gold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
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
                            size: 11,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${delta >= 0 ? "+" : ""}${pct.toStringAsFixed(2)}%',
                            style: TextStyle(
                              fontSize: 10,
                              color: color,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 2행: 미니 스파크라인 + 보유 정보
            Row(
              children: [
                // 미니 스파크라인 (32px 높이)
                Expanded(
                  flex: 5,
                  child: SizedBox(
                    height: 32,
                    child: hist.length < 2
                        ? const SizedBox.shrink()
                        : CustomPaint(
                            painter: _MiniSparkPainter(
                              history: hist,
                              color: color,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                // 보유 / 손익
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        m.shares > 0
                            ? '보유 ${BigNumberFormat.format(m.shares.toDouble())}주'
                            : '미보유',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (m.shares > 0) ...[
                        Text(
                          '평가액 ${BigNumberFormat.format(value)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.starlightCream,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${pnl >= 0 ? "+" : ""}${BigNumberFormat.format(pnl)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: pnl >= 0
                                ? const Color(0xFFFF6B5C)
                                : AppColors.crystalTeal,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniSparkPainter extends CustomPainter {
  _MiniSparkPainter({required this.history, required this.color});
  final List<double> history;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (history.length < 2) return;
    double minV = history.first;
    double maxV = history.first;
    for (final v in history) {
      if (v < minV) minV = v;
      if (v > maxV) maxV = v;
    }
    final range = (maxV - minV).abs() < 1e-9 ? 1.0 : (maxV - minV);
    double xFor(int i) => (i / (history.length - 1)) * size.width;
    double yFor(double v) =>
        size.height - ((v - minV) / range) * size.height;

    final path = Path()..moveTo(xFor(0), yFor(history[0]));
    for (int i = 1; i < history.length; i++) {
      path.lineTo(xFor(i), yFor(history[i]));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniSparkPainter old) =>
      old.history != history;
}

Color _priceColor(double mult) {
  if (mult >= 1.30) return const Color(0xFFFF6B5C);
  if (mult >= 1.10) return const Color(0xFFFFD86E);
  if (mult >= 0.90) return AppColors.crystalTeal;
  if (mult >= 0.70) return AppColors.textSecondary;
  return const Color(0xFF6E5C8C);
}
