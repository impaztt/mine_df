import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../core/utils/big_number.dart';
import '../../data/balance/producer_data.dart';
import '../../domain/idle_calculator.dart';
import '../providers/game_provider.dart';
import '../widgets/bulk_mode_bar.dart';
import '../widgets/upgrade_card.dart';

/// 광부(Producer) 시트 — 자동 채굴 13종.
class ProducerSheet extends ConsumerWidget {
  const ProducerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final state = game.state;
    final totalAuto = IdleCalculator.oresPerSecond(state);

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
              const SheetHandle(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.engineering, color: AppColors.gold),
                    SizedBox(width: 8),
                    Text(
                      '광부 (자동 채굴)',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const BulkModeBar(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackgroundLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt,
                          color: AppColors.gold, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        '전체 자동 채굴',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${BigNumberFormat.format(totalAuto)} 광석/초',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.gold,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  itemCount: kProducers.length,
                  itemBuilder: (context, i) {
                    final def = kProducers[i];
                    final level = state.producers[def.id]?.level ?? 0;
                    final plan = game.previewBulk(
                      currentLevel: level,
                      cap: null,
                      costFn: (lv) =>
                          ProducerBalance.upgradeCost(def, lv),
                    );
                    final ops = ProducerBalance.orePerSec(def, level);
                    final nextOps = level == 0
                        ? def.baseOrePerSec
                        : ProducerBalance.orePerSec(def, level + 1);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: UpgradeCard(
                        title: def.name,
                        icon: def.icon,
                        iconColor: def.accent,
                        emoji: def.emoji,
                        subtitle: level == 0
                            ? '미영입 (Lv1: ${BigNumberFormat.format(def.baseOrePerSec)} 광석/초)'
                            : '${BigNumberFormat.format(ops)} 광석/초 → ${BigNumberFormat.format(nextOps)}',
                        hint: '레벨업 시 ×1.07. '
                            '25/50/100/250/500 레벨 마일스톤마다 ×2.',
                        levelBadge: level == 0 ? '미영입' : 'Lv.$level',
                        buttonLabel: level == 0 ? '영입' : '강화',
                        buttonTimes: plan.times,
                        cost: plan.times > 0 ? plan.cost : null,
                        enabled: plan.times > 0,
                        onTap: () {
                          final r = game.upgradeProducer(def.id);
                          if (!r.ok && r.message != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(r.message!),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
