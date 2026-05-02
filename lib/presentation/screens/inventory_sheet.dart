import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../core/utils/big_number.dart';
import '../../data/balance/ore_data.dart';
import '../../data/models/ore_type.dart';
import '../providers/game_provider.dart';

/// 통합 인벤토리 시트 — 코인 + 모든 보유 광석.
///
/// 광석은 광맥 등급을 올려도 인벤토리에서 사라지지 않는다.
/// (오직 [팔기] 또는 [모두팔기]로만 코인으로 변환됨)
class InventorySheet extends ConsumerWidget {
  const InventorySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final state = game.state;

    // 광석 등급 순 정렬 (낮은 → 높은)
    final entries = state.oreInventory.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) {
        final ra = kOres.indexWhere((o) => o.id == a.key);
        final rb = kOres.indexWhere((o) => o.id == b.key);
        return ra.compareTo(rb);
      });

    final totalOreValue =
        entries.fold<double>(0, (s, e) {
      final ore = kOres.firstWhere(
        (o) => o.id == e.key,
        orElse: () => kOres.first,
      );
      return s + e.value * ore.coinValue;
    });
    final sellBonus = game.currentSellBonus;
    final totalAfterBonus = totalOreValue * (1 + sellBonus);

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      maxChildSize: 0.95,
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        color: AppColors.crystalTeal),
                    SizedBox(width: 8),
                    Text(
                      '인벤토리',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.dividerColor),
              // === 코인 큰 표시 ===
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on_outlined,
                          color: AppColors.gold, size: 32),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '코인',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              BigNumberFormat.format(state.coin),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.gold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // === 광석 섹션 헤더 ===
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Row(
                  children: [
                    const Text(
                      '보유 광석',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      entries.isEmpty ? '없음' : '${entries.length}종',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (entries.isNotEmpty)
                      Text(
                        '팔면 ${BigNumberFormat.format(totalAfterBonus)} 코인',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.gold,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
              ),
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
                            horizontal: 16, vertical: 4),
                        itemCount: entries.length,
                        itemBuilder: (context, i) {
                          final e = entries[i];
                          final ore = kOres.firstWhere(
                            (o) => o.id == e.key,
                            orElse: () => kOres.first,
                          );
                          return _OreRow(
                            ore: ore,
                            count: e.value,
                            sellBonus: sellBonus,
                            onSell: () => game.sellOre(ore.id),
                          );
                        },
                      ),
              ),
              if (entries.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => game.sellAllInventory(),
                      icon: const Icon(Icons.monetization_on_outlined,
                          size: 18),
                      label: Text(
                        '모두 팔기 (+${BigNumberFormat.format(totalAfterBonus)} 코인)',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _OreRow extends StatelessWidget {
  const _OreRow({
    required this.ore,
    required this.count,
    required this.sellBonus,
    required this.onSell,
  });

  final OreDef ore;
  final double count;
  final double sellBonus;
  final VoidCallback onSell;

  @override
  Widget build(BuildContext context) {
    final raw = count * ore.coinValue;
    final value = raw * (1 + sellBonus);
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
                  '${BigNumberFormat.format(raw)}',
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
                height: 26,
                child: ElevatedButton(
                  onPressed: onSell,
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12),
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
