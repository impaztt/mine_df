import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../core/utils/big_number.dart';
import '../../data/balance/essence_data.dart';
import '../providers/game_provider.dart';
import '../widgets/upgrade_card.dart';

/// 광맥 정수 강화 시트 — +0~+50 도전 콘텐츠.
class EssenceSheet extends ConsumerStatefulWidget {
  const EssenceSheet({super.key});

  @override
  ConsumerState<EssenceSheet> createState() => _EssenceSheetState();
}

class _EssenceSheetState extends ConsumerState<EssenceSheet> {
  EssenceBoost _boost = EssenceBoost.none;
  bool _useProtection = false;

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider);
    final state = game.state;
    final stage = state.essenceStage;
    final atMax = stage >= kEssenceMaxStage;
    final cost = atMax ? null : essenceCostFor(stage + 1);
    final stageMul = essenceStageMultiplier(stage);
    final nextMul = essenceStageMultiplier(stage + 1);

    final successRate = atMax
        ? 0.0
        : (cost!.successRate + _boost.successBonus).clamp(0.0, 1.0);
    final canAfford = cost != null &&
        state.coin >= cost.coinCost &&
        state.gem >=
            (_useProtection ? kEssenceProtectionGemCost : 0) +
                _boost.gemCost;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
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
                    Icon(Icons.diamond_outlined,
                        color: AppColors.crystalTeal),
                    SizedBox(width: 8),
                    Text(
                      '광맥 정수 강화',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 현재 단계
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.crystalTeal.withValues(alpha: 0.15),
                            AppColors.tierEpic.withValues(alpha: 0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              AppColors.crystalTeal.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '+$stage',
                            style: const TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              color: AppColors.crystalTeal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '전체 채굴량 ×${stageMul.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.starlightCream,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (!atMax) ...[
                            const SizedBox(height: 6),
                            Text(
                              '+${stage + 1} 도달 시 ×${nextMul.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (atMax)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            '✨ 정수 최대 단계에 도달했습니다',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      )
                    else ...[
                      _AttemptInfo(cost: cost!, successRate: successRate),
                      const SizedBox(height: 12),
                      _BoostSelector(
                        selected: _boost,
                        onChanged: (b) => setState(() => _boost = b),
                      ),
                      const SizedBox(height: 8),
                      _ProtectionToggle(
                        on: _useProtection,
                        onChanged: (v) =>
                            setState(() => _useProtection = v),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: canAfford
                            ? () {
                                final r = game.tryEssence(
                                  boost: _boost,
                                  useProtection: _useProtection,
                                );
                                _showAttemptResult(context, r);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canAfford
                              ? AppColors.crystalTeal
                              : AppColors.dividerColor,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: Text(
                          canAfford
                              ? '+${stage + 1} 도전 (${BigNumberFormat.format(cost.coinCost)} 코인)'
                              : '코인/보석 부족',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAttemptResult(BuildContext context, EssenceAttemptResult r) {
    final msg = r.success
        ? '✨ 강화 성공! +${r.newStage}'
        : (r.downgraded
            ? '💢 실패… +${r.newStage}로 강등'
            : '🛡️ 실패했지만 단계는 보호됨');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: r.success
            ? AppColors.crystalTeal
            : (r.downgraded
                ? const Color(0xFFFF6B5C)
                : AppColors.gold),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _AttemptInfo extends StatelessWidget {
  const _AttemptInfo({required this.cost, required this.successRate});
  final EssenceCost cost;
  final double successRate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _row('성공률', '${(successRate * 100).toStringAsFixed(1)}%',
              AppColors.gold),
          const SizedBox(height: 4),
          _row('비용',
              '${BigNumberFormat.format(cost.coinCost)} 코인', AppColors.gold),
          const SizedBox(height: 4),
          _row(
            '실패 시',
            cost.penaltyOnFail == 0
                ? '강등 없음'
                : '-${cost.penaltyOnFail} 단계',
            cost.penaltyOnFail == 0
                ? AppColors.crystalTeal
                : const Color(0xFFFF6B5C),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _BoostSelector extends StatelessWidget {
  const _BoostSelector({required this.selected, required this.onChanged});
  final EssenceBoost selected;
  final ValueChanged<EssenceBoost> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '부스트 (보석 소모, 성공률 추가)',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: EssenceBoost.values.map((b) {
              final on = selected == b;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => onChanged(b),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: on
                            ? AppColors.crystalTeal.withValues(alpha: 0.18)
                            : AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: on
                              ? AppColors.crystalTeal
                              : AppColors.dividerColor,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            b.label,
                            style: TextStyle(
                              fontSize: 10,
                              color: on
                                  ? AppColors.crystalTeal
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (b.gemCost > 0) ...[
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.diamond_outlined,
                                    size: 10,
                                    color: AppColors.crystalTeal),
                                const SizedBox(width: 2),
                                Text(
                                  '${b.gemCost}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.crystalTeal,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ProtectionToggle extends StatelessWidget {
  const _ProtectionToggle({required this.on, required this.onChanged});
  final bool on;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(!on),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: on
              ? AppColors.gold.withValues(alpha: 0.15)
              : AppColors.cardBackgroundLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: on ? AppColors.gold : AppColors.dividerColor,
          ),
        ),
        child: Row(
          children: [
            Icon(
              on ? Icons.shield : Icons.shield_outlined,
              color: on ? AppColors.gold : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '보호권 사용 (실패해도 강등 없음)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.diamond_outlined,
                size: 14, color: AppColors.crystalTeal),
            const SizedBox(width: 2),
            Text(
              '$kEssenceProtectionGemCost',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.crystalTeal,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
