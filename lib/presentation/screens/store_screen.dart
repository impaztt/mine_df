import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../core/utils/big_number.dart';
import '../../data/balance/essence_data.dart';
import '../../data/balance/helper_data.dart';
import '../../data/balance/ore_data.dart';
import '../providers/game_provider.dart';
import '../widgets/upgrade_card.dart';
import 'market_view.dart';

/// 상점 화면 — 3 서브탭.
///   광석 도감 / 조수 / 광맥 정수.
class StoreScreen extends ConsumerWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const _StoreHeader(),
          Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.cardBackgroundLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.dividerColor),
            ),
            child: const TabBar(
              labelColor: Colors.black,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: AppColors.crystalTeal,
                borderRadius: BorderRadius.all(Radius.circular(7)),
              ),
              labelStyle:
                  TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
              unselectedLabelStyle:
                  TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              tabs: [
                Tab(height: 36, text: '거래소'),
                Tab(height: 36, text: '도감'),
                Tab(height: 36, text: '조수'),
                Tab(height: 36, text: '정수'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                MarketView(),
                _OreCodexTab(),
                _HelperTab(),
                _EssenceTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreHeader extends ConsumerWidget {
  const _StoreHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.crystalTeal.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          _stat(
            label: '코인',
            value: BigNumberFormat.format(game.state.coin),
            color: AppColors.gold,
            icon: Icons.monetization_on_outlined,
          ),
          const SizedBox(width: 12),
          _stat(
            label: '보석',
            value: '${game.state.gem}',
            color: AppColors.crystalTeal,
            icon: Icons.diamond_outlined,
          ),
          const SizedBox(width: 12),
          _stat(
            label: '도감',
            value: '${game.state.discoveredOres.length}/${kOres.length}',
            color: AppColors.tierEpic,
            icon: Icons.menu_book_outlined,
          ),
        ],
      ),
    );
  }

  Widget _stat({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 12),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ===== 광석 도감 =====

class _OreCodexTab extends ConsumerWidget {
  const _OreCodexTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final state = game.state;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: kOres.length,
      itemBuilder: (_, i) {
        final ore = kOres[i];
        final discovered = state.discoveredOres.contains(ore.id);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardBackgroundLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: ore.color.withValues(alpha: discovered ? 0.5 : 0.18),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ore.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ColorFiltered(
                  colorFilter: discovered
                      ? const ColorFilter.mode(
                          Colors.transparent, BlendMode.dst)
                      : const ColorFilter.matrix([
                          0, 0, 0, 0, 30, //
                          0, 0, 0, 0, 30,
                          0, 0, 0, 0, 30,
                          0, 0, 0, 1, 0,
                        ]),
                  child: Text(
                    ore.emoji,
                    style: const TextStyle(fontSize: 30),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            discovered ? ore.name : '???',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: ore.tier.color.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ore.tier.label,
                            style: TextStyle(
                              fontSize: 10,
                              color: ore.tier.color,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      discovered
                          ? '${ore.description}\n1개당 ${BigNumberFormat.format(ore.coinValue)} 코인'
                          : '광맥을 강화해 발견하세요',
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
        );
      },
    );
  }
}

// ===== 조수 =====

class _HelperTab extends ConsumerWidget {
  const _HelperTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final state = game.state;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: kHelpers.length,
      itemBuilder: (_, i) {
        final def = kHelpers[i];
        final cur = state.helpers[def.id];
        final recruited = cur?.recruited ?? false;
        final level = cur?.level ?? 0;

        if (!recruited) {
          // 영입은 단발 — buyCount=1
          final canBuy = state.coin >= def.recruitCost;
          return UpgradeCard(
            title: def.name,
            icon: Icons.pets,
            iconColor: def.tier.color,
            emoji: def.emoji,
            subtitle: def.description,
            gainPill: '영입 → Lv.1',
            levelBadge: '미영입',
            buyCount: 1,
            totalCost: def.recruitCost,
            affordable: canBuy,
            onTap: () =>
                _snack(context, game.recruitOrUpgradeHelper(def.id)),
          );
        }

        final price = game.priceForMode(
          currentLevel: level,
          cap: null,
          costFn: (lv) => helperUpgradeCost(def, lv),
        );
        return UpgradeCard(
          title: def.name,
          icon: Icons.pets,
          iconColor: def.tier.color,
          emoji: def.emoji,
          subtitle: def.description,
          gainPill: '+1 → Lv.${level + 1}',
          levelBadge: 'Lv.$level',
          buyCount: price.buyCount,
          totalCost: price.totalCost,
          affordable: price.affordable,
          onTap: () =>
              _snack(context, game.recruitOrUpgradeHelper(def.id)),
        );
      },
    );
  }
}

// ===== 광맥 정수 =====

class _EssenceTab extends ConsumerStatefulWidget {
  const _EssenceTab();

  @override
  ConsumerState<_EssenceTab> createState() => _EssenceTabState();
}

class _EssenceTabState extends ConsumerState<_EssenceTab> {
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
    final canAfford = !atMax &&
        cost != null &&
        state.coin >= cost.coinCost &&
        state.gem >=
            (_useProtection ? kEssenceProtectionGemCost : 0) +
                _boost.gemCost;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.crystalTeal.withValues(alpha: 0.18),
                AppColors.tierEpic.withValues(alpha: 0.18),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.crystalTeal.withValues(alpha: 0.5),
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
            onChanged: (v) => setState(() => _useProtection = v),
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
            : (r.downgraded ? const Color(0xFFFF6B5C) : AppColors.gold),
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
          _row('비용', '${BigNumberFormat.format(cost.coinCost)} 코인',
              AppColors.gold),
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
              child: Text(
                '보호권 사용 (실패해도 강등 없음)',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w800),
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
