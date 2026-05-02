import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../core/utils/big_number.dart';
import '../../data/balance/ore_data.dart';
import '../../data/balance/pickaxe_data.dart';
import '../providers/game_provider.dart';

/// 곡괭이 / 광맥 강화 시트
class PickaxeSheet extends ConsumerWidget {
  const PickaxeSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final state = game.state;
    final ore = oreByRank(state.mineRank);
    final nextOre = state.mineRank < maxMineRank
        ? oreByRank(state.mineRank + 1)
        : null;

    final dmgCost =
        PickaxeBalance.damageUpgradeCost(state.pickaxe.damageLevel);
    final spdCost =
        PickaxeBalance.speedUpgradeCost(state.pickaxe.speedLevel);
    final mineCost = mineUpgradeCost(state.mineRank);

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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.handyman, color: AppColors.gold),
                    SizedBox(width: 8),
                    Text(
                      '곡괭이 · 광맥',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.dividerColor),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // === 광맥 강화 (가장 핵심) ===
                    _UpgradeCard(
                      title: '광맥 등급',
                      sub: '현재: ${ore.name} (${BigNumberFormat.format(ore.coinValue)} 코인/개)',
                      hint: nextOre == null
                          ? '최고 등급에 도달했습니다.'
                          : '다음: ${nextOre.name} '
                              '(${BigNumberFormat.format(nextOre.coinValue)} 코인/개)',
                      level: state.mineRank,
                      cost: nextOre == null ? null : mineCost,
                      enabled:
                          nextOre != null && state.coin >= mineCost,
                      icon: Icons.diamond_outlined,
                      iconColor: ore.color,
                      buttonLabel: '광맥 강화',
                      onTap: () {
                        final r = game.upgradeMineRank();
                        _snack(context, r);
                      },
                    ),
                    const SizedBox(height: 12),

                    // === 곡괭이 데미지 ===
                    _UpgradeCard(
                      title: '곡괭이 데미지',
                      sub: '곡괭이질당 광석 ×${PickaxeBalance.orePerSwing(state.pickaxe)}',
                      hint:
                          '강화 시 한 번에 더 많은 광석을 캐냅니다.',
                      level: state.pickaxe.damageLevel,
                      cost: dmgCost,
                      enabled: state.coin >= dmgCost,
                      icon: Icons.flash_on,
                      iconColor: AppColors.gold,
                      buttonLabel: '강화',
                      onTap: () {
                        final r = game.upgradePickaxeDamage();
                        _snack(context, r);
                      },
                    ),
                    const SizedBox(height: 12),

                    // === 곡괭이 속도 ===
                    _UpgradeCard(
                      title: '곡괭이 속도',
                      sub:
                          '곡괭이질 간격 ${PickaxeBalance.swingInterval(state.pickaxe).toStringAsFixed(2)}초',
                      hint: '강화 시 더 빠르게 채굴합니다.',
                      level: state.pickaxe.speedLevel,
                      cost: spdCost,
                      enabled: state.coin >= spdCost,
                      icon: Icons.speed,
                      iconColor: AppColors.crystalTeal,
                      buttonLabel: '강화',
                      onTap: () {
                        final r = game.upgradePickaxeSpeed();
                        _snack(context, r);
                      },
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

  void _snack(BuildContext context, ActionResult r) {
    if (!r.ok && r.message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(r.message!),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
}

class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard({
    required this.title,
    required this.sub,
    required this.hint,
    required this.level,
    required this.cost,
    required this.enabled,
    required this.icon,
    required this.iconColor,
    required this.buttonLabel,
    required this.onTap,
  });

  final String title;
  final String sub;
  final String hint;
  final int level;
  final double? cost;
  final bool enabled;
  final IconData icon;
  final Color iconColor;
  final String buttonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: enabled
              ? iconColor.withValues(alpha: 0.6)
              : AppColors.dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Lv.$level',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.gold,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sub,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.starlightCream,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hint,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: enabled ? onTap : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        enabled ? iconColor : AppColors.dividerColor,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        buttonLabel,
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
