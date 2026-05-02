import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../core/utils/big_number.dart';
import '../../data/balance/helper_data.dart';
import '../../data/models/helper.dart';
import '../providers/game_provider.dart';
import '../widgets/bulk_mode_bar.dart';

class HelperSheet extends ConsumerWidget {
  const HelperSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final state = game.state;

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
                    Icon(Icons.pets, color: AppColors.tierEpic),
                    SizedBox(width: 8),
                    Text(
                      '조수',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const BulkModeBar(),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: kHelpers.length,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  itemBuilder: (context, i) {
                    final def = kHelpers[i];
                    final cur = state.helpers[def.id];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _HelperCard(
                        def: def,
                        cur: cur,
                        onAction: () {
                          final r = game.recruitOrUpgradeHelper(def.id);
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

class _HelperCard extends ConsumerWidget {
  const _HelperCard({
    required this.def,
    required this.cur,
    required this.onAction,
  });

  final HelperDef def;
  final HelperState? cur;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final recruited = cur?.recruited ?? false;
    final level = cur?.level ?? 0;

    // 영입 단계
    if (!recruited) {
      final cost = def.recruitCost;
      final canBuy = game.state.coin >= cost;
      return _Shell(
        def: def,
        title: def.name,
        levelLabel: '미영입',
        sub: def.description,
        buttonLabel: '영입',
        buttonTimes: 1,
        cost: cost,
        enabled: canBuy,
        onTap: onAction,
      );
    }

    // 강화 단계 — bulk
    final plan = game.previewBulk(
      currentLevel: level,
      cap: null,
      costFn: (lv) => helperUpgradeCost(def, lv),
    );

    return _Shell(
      def: def,
      title: def.name,
      levelLabel: 'Lv.$level',
      sub: def.description,
      buttonLabel: '강화',
      buttonTimes: plan.times,
      cost: plan.times > 0 ? plan.cost : null,
      enabled: plan.times > 0,
      onTap: onAction,
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({
    required this.def,
    required this.title,
    required this.levelLabel,
    required this.sub,
    required this.buttonLabel,
    required this.buttonTimes,
    required this.cost,
    required this.enabled,
    required this.onTap,
  });

  final HelperDef def;
  final String title;
  final String levelLabel;
  final String sub;
  final String buttonLabel;
  final int buttonTimes;
  final double? cost;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: def.tier.color.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: def.tier.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  def.emoji,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                def.tier.color.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            def.tier.label,
                            style: TextStyle(
                              fontSize: 10,
                              color: def.tier.color,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          levelLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.gold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sub,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: enabled ? onTap : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  enabled ? def.tier.color : AppColors.dividerColor,
              minimumSize: const Size(double.infinity, 38),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  buttonTimes > 0
                      ? '$buttonLabel ×$buttonTimes'
                      : buttonLabel,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800),
                ),
                if (cost != null) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.monetization_on_outlined,
                    size: 13,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    BigNumberFormat.format(cost!),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ],
              ],
            ),
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
