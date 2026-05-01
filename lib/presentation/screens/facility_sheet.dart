import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../core/utils/big_number.dart';
import '../../data/balance/facility_data.dart';
import '../providers/game_provider.dart';

class FacilitySheet extends ConsumerWidget {
  const FacilitySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final state = game.state;

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
                      '채굴 시설',
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
                child: ListView.builder(
                  controller: controller,
                  itemCount: kFacilities.length,
                  itemBuilder: (context, i) {
                    final def = kFacilities[i];
                    final cur = state.facilities[def.id];
                    final level = cur?.level ?? 0;
                    final unlocked = state.day >= def.unlockDay;
                    final cost = facilityUpgradeCost(def, level);
                    final rate = facilityRate(def, level);
                    final nextRate = facilityRate(def, level + 1);
                    final canBuy = unlocked && state.coin >= cost;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardBackgroundLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: unlocked
                                ? AppColors.dividerColor
                                : AppColors.dividerColor
                                    .withValues(alpha: 0.4),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.minerDusk
                                      .withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  def.icon,
                                  color: unlocked
                                      ? AppColors.gold
                                      : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          def.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        if (level > 0)
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.gold
                                                  .withValues(alpha: 0.18),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'Lv.$level',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.gold,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      unlocked
                                          ? '${BigNumberFormat.format(rate)}/s → ${BigNumberFormat.format(nextRate)}/s'
                                          : 'DAY ${def.unlockDay} 부터 해금',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: canBuy
                                    ? () {
                                        final r =
                                            game.buyOrUpgradeFacility(
                                                def.id);
                                        if (!r.ok && r.message != null) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                            content: Text(r.message!),
                                            duration:
                                                const Duration(seconds: 1),
                                          ));
                                        }
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: canBuy
                                      ? AppColors.minerDusk
                                      : AppColors.dividerColor,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      level == 0 ? '구매' : '강화',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 1),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.monetization_on_outlined,
                                          size: 11,
                                          color: AppColors.gold,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          BigNumberFormat.format(cost),
                                          style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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
