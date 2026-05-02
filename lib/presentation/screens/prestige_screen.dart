import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../core/utils/big_number.dart';
import '../../data/balance/prestige_data.dart';
import '../providers/game_provider.dart';
import '../widgets/upgrade_card.dart';

/// 환생 화면 — 별의 의식 + 5개 영구 트리.
class PrestigeScreen extends ConsumerWidget {
  const PrestigeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final state = game.state;
    final canRebirth = game.canRebirthNow;
    final reward = game.previewStardustReward();

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        // 환생 헤드라인 (별의 결정 표시 + 환생 버튼)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF3A2860),
                Color(0xFF1A1B3A),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.6),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: AppColors.gold, size: 22),
                  const SizedBox(width: 6),
                  Text(
                    '${state.stardust}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '별의 결정',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '환생 ${state.rebirthCount}회',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      canRebirth
                          ? '지금 환생하면 +$reward 별의 결정'
                          : '환생 조건: 광맥 등급 10+ 또는 누적 코인 1B+',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.starlightCream,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '현재 광맥: ${state.mineRank}등급 · '
                      '누적 코인: ${BigNumberFormat.format(state.totalCoinEarned)}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: canRebirth
                          ? () => _confirmRebirth(context, game, reward)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canRebirth
                            ? AppColors.gold
                            : AppColors.dividerColor,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 44),
                      ),
                      child: Text(
                        canRebirth
                            ? '환생하기 (+$reward ✨)'
                            : '환생 불가',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            '영구 강화 트리',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.starlightCream),
          ),
        ),
        ...kPrestigeNodes.map((def) {
          final lv = state.prestigeLevels[def.id] ?? 0;
          final atMax = lv >= def.maxLevel;
          final cost = atMax ? 0 : prestigeNodeCost(def, lv);
          final canBuy = !atMax && state.stardust >= cost.ceil();
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: UpgradeCard(
              title: def.name,
              icon: def.icon,
              iconColor: def.accent,
              subtitle: def.description,
              hint: atMax
                  ? '최대 레벨'
                  : '비용 ×${def.growthRate.toStringAsFixed(2)} (캡 Lv.${def.maxLevel})',
              levelBadge: atMax ? 'MAX' : 'Lv.$lv',
              buttonLabel: atMax ? '최대' : '강화',
              buttonTimes: 1,
              cost: atMax ? null : cost.toDouble(),
              enabled: canBuy,
              onTap: () {
                final r = game.upgradePrestigeNode(def.id);
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
        }),
      ],
    );
  }

  void _confirmRebirth(
      BuildContext context, GameProvider game, int reward) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('환생하시겠습니까?'),
        content: Text(
          '현재 진행도(코인/광부/탭강화/광맥등급/정수강화)가 모두 초기화됩니다.\n\n'
          '+$reward 별의 결정을 받습니다.\n'
          '도감/조수 영입/영구 트리는 유지됩니다.',
          style:
              const TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              game.performRebirth();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
            child: const Text('환생', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}
