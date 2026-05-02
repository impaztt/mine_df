import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../core/utils/big_number.dart';
import '../../data/balance/tap_upgrade_data.dart';
import '../providers/game_provider.dart';
import '../widgets/bulk_mode_bar.dart';
import '../widgets/upgrade_card.dart';

/// 탭 강화 11종 시트 — 영구 누적, 모두 합산되어 탭당 광석 결정.
class TapUpgradeSheet extends ConsumerWidget {
  const TapUpgradeSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final state = game.state;
    final tapOre = game.currentTapOre;

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
                    Icon(Icons.touch_app, color: AppColors.gold),
                    SizedBox(width: 8),
                    Text(
                      '탭 강화',
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
                      const Icon(Icons.flash_on,
                          color: AppColors.gold, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        '한 번 탭 시 광석',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${BigNumberFormat.format(tapOre)} 개',
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
                  itemCount: kTapUpgrades.length,
                  itemBuilder: (context, i) {
                    final def = kTapUpgrades[i];
                    final level = state.tapUpgrades[def.id] ?? 0;
                    final plan = game.previewBulk(
                      currentLevel: level,
                      cap: null,
                      costFn: (lv) =>
                          TapUpgradeBalance.upgradeCost(def, lv),
                    );
                    final addedNow =
                        BigNumberFormat.format(level * def.tapOrePerLevel);
                    final addedNext = BigNumberFormat.format(
                        (level + 1) * def.tapOrePerLevel);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: UpgradeCard(
                        title: def.name,
                        icon: def.icon,
                        iconColor: def.accent,
                        subtitle:
                            '${def.description} (현재 +$addedNow → +$addedNext)',
                        hint: '레벨업 시 비용 ×1.10.',
                        levelBadge: 'Lv.$level',
                        buttonLabel: '강화',
                        buttonTimes: plan.times,
                        cost: plan.times > 0 ? plan.cost : null,
                        enabled: plan.times > 0,
                        onTap: () {
                          final r = game.upgradeTap(def.id);
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
