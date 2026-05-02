import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../core/utils/big_number.dart';
import '../../data/balance/country_data.dart';
import '../../data/models/country.dart';
import '../providers/game_provider.dart';

/// 광물 시세 거래소 — 6개국가 시세 카드 + 일괄 판매.
///
/// 각 국가는 광맥 등급 5단계씩 매입한다. 시세 배율은 매 분 갱신되며,
/// 좋은 타이밍에 인벤토리를 던져 추가 코인을 챙기는 메타 게임.
class MarketView extends ConsumerWidget {
  const MarketView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final state = game.state;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2A2540), Color(0xFF1A1B3A)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.crystalTeal.withValues(alpha: 0.4),
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.public, color: AppColors.crystalTeal),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '국가별 광물 시세 거래소\n시세가 좋은 국가에 광석을 팔면 추가 코인!',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.starlightCream,
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final c in kCountries) ...[
          _CountryCard(country: c, game: game, state: state),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _CountryCard extends StatelessWidget {
  const _CountryCard({
    required this.country,
    required this.game,
    required this.state,
  });
  final CountryDef country;
  final GameProvider game;
  final dynamic state;

  @override
  Widget build(BuildContext context) {
    final market = state.markets[country.id] as CountryState?;
    final mult = market?.priceMultiplier ?? 1.0;
    final eligibleKinds = game.countryEligibleKinds(country.id);
    final revenue = game.previewCountryRevenue(country.id);
    final canSell = eligibleKinds > 0;

    final priceColor = _priceColor(mult);
    final priceLabel = _priceLabel(mult);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: priceColor.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1행: 국기 + 이름 + 시세 배지
          Row(
            children: [
              Text(country.flag, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      country.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '광맥 ${country.minRank}~${country.maxRank}등급 매입',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: priceColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: priceColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_priceIcon(mult), color: priceColor, size: 13),
                    const SizedBox(width: 3),
                    Text(
                      '×${mult.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: priceColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 2행: 시세 라벨 + 거래소 설명
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  priceLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: priceColor,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    country.specialty,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 3행: 매도 가능 정보 + 버튼
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      canSell
                          ? '판매 가능: $eligibleKinds종'
                          : '판매할 광석 없음',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (canSell)
                      Row(
                        children: [
                          const Icon(
                            Icons.monetization_on_outlined,
                            size: 14,
                            color: AppColors.gold,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            BigNumberFormat.format(revenue),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.gold,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: canSell
                    ? () {
                        final r = game.sellAllToCountry(country.id);
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
                                '${country.flag} ${country.name}에 판매 완료 '
                                '(+${BigNumberFormat.format(r.cost)} 코인)',
                              ),
                              duration: const Duration(seconds: 2),
                              backgroundColor: priceColor,
                            ),
                          );
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      canSell ? priceColor : AppColors.dividerColor,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(110, 40),
                ),
                child: const Text(
                  '판매',
                  style:
                      TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _priceColor(double mult) {
    if (mult >= 1.30) return const Color(0xFFFF6B5C); // 핫
    if (mult >= 1.10) return const Color(0xFFFFD86E); // 좋음
    if (mult >= 0.90) return AppColors.crystalTeal; // 보통
    if (mult >= 0.70) return AppColors.textSecondary; // 약세
    return const Color(0xFF6E5C8C); // 폭락
  }

  String _priceLabel(double mult) {
    if (mult >= 1.30) return '🔥 폭등';
    if (mult >= 1.10) return '📈 강세';
    if (mult >= 0.90) return '➖ 보통';
    if (mult >= 0.70) return '📉 약세';
    return '❄️ 폭락';
  }

  IconData _priceIcon(double mult) {
    if (mult >= 1.10) return Icons.trending_up;
    if (mult <= 0.90) return Icons.trending_down;
    return Icons.trending_flat;
  }
}
