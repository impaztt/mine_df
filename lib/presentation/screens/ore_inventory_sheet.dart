import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../core/utils/big_number.dart';
import '../../data/balance/ore_data.dart';
import '../../data/models/ore_type.dart';
import '../providers/game_provider.dart';

/// 보유 광석 인벤토리 — 광석별 보유 수량 + 가치 + 개별/일괄 환전.
class OreInventorySheet extends ConsumerWidget {
  const OreInventorySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final state = game.state;

    // 인벤토리에서 보유량 > 0 인 항목만, 가치 큰 순으로 정렬
    final entries = state.oreInventory.entries
        .where((e) => e.value > 0)
        .map((e) {
      final ore = kOres.firstWhere(
        (o) => o.id == e.key,
        orElse: () => kOres.first,
      );
      return _Entry(ore: ore, count: e.value);
    }).toList()
      ..sort((a, b) =>
          (b.count * b.ore.coinValue).compareTo(a.count * a.ore.coinValue));

    final totalValue =
        entries.fold<double>(0, (s, e) => s + e.count * e.ore.coinValue);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const _Handle(),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined,
                        color: AppColors.crystalTeal),
                    const SizedBox(width: 8),
                    const Text(
                      '광석 인벤토리',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${entries.length}종',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.dividerColor),
              Expanded(
                child: entries.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            '아직 모은 광석이 없어요.\n곡괭이질로 광석을 모아보세요!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              height: 1.6,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: controller,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: entries.length,
                        itemBuilder: (context, i) {
                          final e = entries[i];
                          return _OreRow(
                            ore: e.ore,
                            count: e.count,
                            onSell: () {
                              game.sellOre(e.ore.id);
                            },
                          );
                        },
                      ),
              ),
              if (entries.isNotEmpty)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  decoration: const BoxDecoration(
                    color: AppColors.cardBackgroundLight,
                    border: Border(
                      top: BorderSide(color: AppColors.dividerColor),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '합계 가치',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '${BigNumberFormat.format(totalValue)} 코인',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.gold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          game.sellAllInventory();
                        },
                        icon: const Icon(Icons.monetization_on_outlined,
                            size: 16),
                        label: const Text('모두 팔기'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Entry {
  final OreDef ore;
  final double count;
  _Entry({required this.ore, required this.count});
}

class _OreRow extends StatelessWidget {
  const _OreRow({
    required this.ore,
    required this.count,
    required this.onSell,
  });

  final OreDef ore;
  final double count;
  final VoidCallback onSell;

  @override
  Widget build(BuildContext context) {
    final value = count * ore.coinValue;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ore.color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ore.color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(ore.emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ore.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${BigNumberFormat.format(count)}개 × '
                  '${BigNumberFormat.format(ore.coinValue)} = '
                  '${BigNumberFormat.format(count * ore.coinValue)} 코인',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                BigNumberFormat.format(value),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.gold,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: 24,
                child: ElevatedButton(
                  onPressed: onSell,
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 0),
                    backgroundColor: AppColors.minerDusk,
                  ),
                  child: const Text(
                    '팔기',
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.dividerColor,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
