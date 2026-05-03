import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../core/utils/big_number.dart';
import '../../data/balance/ore_data.dart';
import '../../data/balance/pickaxe_data.dart';
import '../../data/balance/producer_data.dart';
import '../../data/balance/tap_upgrade_data.dart';
import '../providers/game_provider.dart';
import '../widgets/bulk_mode_bar.dart';
import '../widgets/upgrade_card.dart';

/// 강화 화면 — 3 서브탭: 터치 / 동료 / 곡괭이.
class UpgradeScreen extends ConsumerWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          _Header(),
          const _MineRankCard(),
          const BulkModeBar(),
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
                color: AppColors.gold,
                borderRadius: BorderRadius.all(Radius.circular(7)),
              ),
              labelStyle:
                  TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              unselectedLabelStyle:
                  TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              tabs: [
                Tab(height: 36, text: '터치'),
                Tab(height: 36, text: '광부'),
                Tab(height: 36, text: '곡괭이'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _TapTab(),
                _CompanionTab(),
                _PickaxeTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
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
            label: '탭당',
            value: '${BigNumberFormat.format(game.currentTapOre)}개',
            color: AppColors.crystalTeal,
            icon: Icons.touch_app,
          ),
          const SizedBox(width: 12),
          _stat(
            label: '초당',
            value: '${BigNumberFormat.format(game.currentOrePerSec)}개',
            color: AppColors.tierEpic,
            icon: Icons.speed,
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

/// 광맥 등급 강화 카드 — 강화 화면 어디서든 보이는 핵심 진행 카드.
///
/// 단발 강화 (한 번에 한 등급), 비용 = `mineUpgradeCost(rank)`.
/// 강화 시 다음 광석으로 캐는 광석이 즉시 변경된다.
class _MineRankCard extends ConsumerWidget {
  const _MineRankCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final state = game.state;
    final ore = oreByRank(state.mineRank);
    final atMax = state.mineRank >= maxMineRank;
    final nextOre = atMax ? null : oreByRank(state.mineRank + 1);
    final cost = atMax ? null : mineUpgradeCost(state.mineRank);
    final canBuy = !atMax && cost != null && state.coin >= cost;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ore.color.withValues(alpha: 0.18),
            (nextOre?.color ?? ore.color).withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (atMax ? ore.color : ore.color)
              .withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // 좌: 현재 광석 이모지 (큼직)
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ore.color.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(ore.emoji, style: const TextStyle(fontSize: 32)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      '광맥 등급',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: ore.color.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${state.mineRank}/$maxMineRank',
                        style: TextStyle(
                          fontSize: 10,
                          color: ore.color,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  atMax
                      ? '${ore.name} (최고 등급)'
                      : '${ore.name} → ${nextOre!.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on_outlined,
                          size: 11, color: AppColors.gold),
                      const SizedBox(width: 3),
                      Text(
                        atMax
                            ? '1개당 ${BigNumberFormat.format(ore.coinValue)}'
                            : '1개당 ${BigNumberFormat.format(ore.coinValue)} → ${BigNumberFormat.format(nextOre!.coinValue)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.gold,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 우: 강화 버튼
          _MineRankButton(
            cost: cost,
            atMax: atMax,
            canBuy: canBuy,
            onTap: () => _snack(context, game.upgradeMineRank()),
          ),
        ],
      ),
    );
  }
}

class _MineRankButton extends StatelessWidget {
  const _MineRankButton({
    required this.cost,
    required this.atMax,
    required this.canBuy,
    required this.onTap,
  });

  final double? cost;
  final bool atMax;
  final bool canBuy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    if (atMax) {
      bg = AppColors.dividerColor;
      fg = AppColors.textSecondary;
    } else if (canBuy) {
      bg = AppColors.gold;
      fg = Colors.black;
    } else {
      bg = AppColors.dividerColor;
      fg = AppColors.textSecondary;
    }
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: (!atMax && canBuy) ? onTap : null,
        child: Container(
          width: 92,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                atMax ? '최고' : '광맥 강화',
                style: TextStyle(
                  color: fg,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              if (!atMax && cost != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.monetization_on_outlined,
                      color: canBuy ? fg : AppColors.gold,
                      size: 14,
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        BigNumberFormat.format(cost!),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: canBuy ? fg : AppColors.gold,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                )
              else
                const Text(
                  '-',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== 터치 탭 =====

class _TapTab extends ConsumerWidget {
  const _TapTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final state = game.state;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: kTapUpgrades.length + 1,
      itemBuilder: (_, idx) {
        if (idx == 0) {
          return const _RoleHint(
            icon: Icons.touch_app,
            color: AppColors.crystalTeal,
            text: '화면을 한 번 탭할 때 캐는 광석량을 영구히 늘립니다',
          );
        }
        final i = idx - 1;
        final def = kTapUpgrades[i];
        final lv = state.tapUpgrades[def.id] ?? 0;

        final addedNow = BigNumberFormat.format(lv * def.tapOrePerLevel);
        final addedNext =
            BigNumberFormat.format((lv + 1) * def.tapOrePerLevel);

        final price = game.priceForMode(
          currentLevel: lv,
          cap: null,
          costFn: (l) => TapUpgradeBalance.upgradeCost(def, l),
        );

        return UpgradeCard(
          title: def.name,
          icon: def.icon,
          iconColor: def.accent,
          subtitle: '${def.description} · 현재 +$addedNow',
          gainPill: '+1 → 탭당 +$addedNext',
          levelBadge: 'Lv.$lv',
          buyCount: price.buyCount,
          totalCost: price.totalCost,
          affordable: price.affordable,
          atMax: price.atCap,
          onTap: () => _snack(context, game.upgradeTap(def.id)),
        );
      },
    );
  }
}

// ===== 광부 탭 (13종 자동 채굴) =====

class _CompanionTab extends ConsumerWidget {
  const _CompanionTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final state = game.state;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: kProducers.length + 1,
      itemBuilder: (_, idx) {
        if (idx == 0) {
          return const _RoleHint(
            icon: Icons.engineering,
            color: AppColors.gold,
            text: '광부를 영입하면 1초마다 광석을 자동으로 캡니다 (수량형)',
          );
        }
        final i = idx - 1;
        final def = kProducers[i];
        final lv = state.producers[def.id]?.level ?? 0;

        final ops = ProducerBalance.orePerSec(def, lv);
        final nextOps = lv == 0
            ? def.baseOrePerSec
            : ProducerBalance.orePerSec(def, lv + 1);

        final price = game.priceForMode(
          currentLevel: lv,
          cap: null,
          costFn: (l) => ProducerBalance.upgradeCost(def, l),
        );

        return UpgradeCard(
          title: def.name,
          icon: def.icon,
          iconColor: def.accent,
          emoji: def.emoji,
          subtitle: lv == 0
              ? '미영입 · 영입하면 ${BigNumberFormat.format(def.baseOrePerSec)}/초'
              : '현재 ${BigNumberFormat.format(ops)} 광석/초',
          gainPill: lv == 0
              ? '영입 → ${BigNumberFormat.format(def.baseOrePerSec)}/초'
              : '+1 → ${BigNumberFormat.format(nextOps)}/초',
          levelBadge: lv == 0 ? '미영입' : 'Lv.$lv',
          buyCount: price.buyCount,
          totalCost: price.totalCost,
          affordable: price.affordable,
          onTap: () => _snack(context, game.upgradeProducer(def.id)),
        );
      },
    );
  }
}

// ===== 곡괭이 탭 (7스탯) =====

class _PickaxeTab extends ConsumerWidget {
  const _PickaxeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final pickaxe = game.state.pickaxe;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      children: [
        const _RoleHint(
          icon: Icons.handyman,
          color: AppColors.gold,
          text: '곡괭이의 7가지 스탯 — 자동/탭 채굴 모두에 적용됩니다',
        ),
        _row(
          context,
          game: game,
          title: '곡괭이 데미지',
          icon: Icons.flash_on,
          color: AppColors.gold,
          level: pickaxe.damageLevel,
          cap: null,
          costFn: PickaxeBalance.damageUpgradeCost,
          subtitleNow:
              '곡괭이질 1번에 광석 ${PickaxeBalance.orePerSwing(pickaxe)}개',
          gainNext:
              '+1 → ${PickaxeBalance.orePerSwing(pickaxe.copyWith(damageLevel: pickaxe.damageLevel + 1))}개',
          onUpgrade: () => game.upgradePickaxeDamage(),
        ),
        _row(
          context,
          game: game,
          title: '곡괭이 속도',
          icon: Icons.speed,
          color: AppColors.crystalTeal,
          level: pickaxe.speedLevel,
          cap: null,
          costFn: PickaxeBalance.speedUpgradeCost,
          subtitleNow:
              '간격 ${PickaxeBalance.swingInterval(pickaxe).toStringAsFixed(2)}초',
          gainNext:
              '+1 → ${PickaxeBalance.swingInterval(pickaxe.copyWith(speedLevel: pickaxe.speedLevel + 1)).toStringAsFixed(2)}초',
          onUpgrade: () => game.upgradePickaxeSpeed(),
        ),
        _row(
          context,
          game: game,
          title: '크리티컬 확률',
          icon: Icons.bolt,
          color: AppColors.rubyPink,
          level: pickaxe.critChanceLevel,
          cap: PickaxeBalance.critChanceCap,
          costFn: PickaxeBalance.critChanceUpgradeCost,
          subtitleNow:
              '확률 ${game.currentCritChance.toStringAsFixed(1)}%',
          gainNext:
              '+1 → ${(game.currentCritChance + 0.5).toStringAsFixed(1)}%',
          onUpgrade: () => game.upgradeCritChance(),
        ),
        _row(
          context,
          game: game,
          title: '크리티컬 위력',
          icon: Icons.local_fire_department_outlined,
          color: const Color(0xFFFF6B5C),
          level: pickaxe.critPowerLevel,
          cap: PickaxeBalance.critPowerCap,
          costFn: PickaxeBalance.critPowerUpgradeCost,
          subtitleNow:
              '크리 시 ×${game.currentCritMultiplier.toStringAsFixed(1)}',
          gainNext:
              '+1 → ×${(game.currentCritMultiplier + 0.2).toStringAsFixed(1)}',
          onUpgrade: () => game.upgradeCritPower(),
        ),
        _row(
          context,
          game: game,
          title: '광석 제련',
          icon: Icons.local_mall_outlined,
          color: AppColors.gold,
          level: pickaxe.smeltLevel,
          cap: PickaxeBalance.smeltCap,
          costFn: PickaxeBalance.smeltUpgradeCost,
          subtitleNow:
              '환전 +${(game.currentSellBonus * 100).toStringAsFixed(0)}%',
          gainNext:
              '+1 → +${(game.currentSellBonus * 100 + 1).toStringAsFixed(0)}%',
          onUpgrade: () => game.upgradeSmelt(),
        ),
        _row(
          context,
          game: game,
          title: '연쇄 채굴',
          icon: Icons.repeat,
          color: AppColors.tierEpic,
          level: pickaxe.chainMineLevel,
          cap: PickaxeBalance.chainMineCap,
          costFn: PickaxeBalance.chainMineUpgradeCost,
          subtitleNow:
              '확률 ${PickaxeBalance.chainMineProb(pickaxe.chainMineLevel).toStringAsFixed(1)}%',
          gainNext:
              '+1 → ${PickaxeBalance.chainMineProb(pickaxe.chainMineLevel + 1).toStringAsFixed(1)}%',
          onUpgrade: () => game.upgradeChainMine(),
        ),
        _row(
          context,
          game: game,
          title: '별의 운',
          icon: Icons.auto_awesome,
          color: AppColors.starlightCream,
          level: pickaxe.luckLevel,
          cap: PickaxeBalance.luckCap,
          costFn: PickaxeBalance.luckUpgradeCost,
          subtitleNow:
              '신규 발견 보석 +${3 + PickaxeBalance.luckGemBonus(pickaxe.luckLevel)}',
          gainNext:
              '+1 → +${3 + PickaxeBalance.luckGemBonus(pickaxe.luckLevel + 1)}',
          onUpgrade: () => game.upgradeLuck(),
        ),
      ],
    );
  }

  Widget _row(
    BuildContext context, {
    required GameProvider game,
    required String title,
    required IconData icon,
    required Color color,
    required int level,
    required int? cap,
    required double Function(int level) costFn,
    required String subtitleNow,
    required String gainNext,
    required ActionResult Function() onUpgrade,
  }) {
    final price = game.priceForMode(
      currentLevel: level,
      cap: cap,
      costFn: costFn,
    );
    return UpgradeCard(
      title: title,
      icon: icon,
      iconColor: color,
      subtitle: subtitleNow,
      gainPill: price.atCap ? '최대' : gainNext,
      levelBadge: cap == null ? 'Lv.$level' : '$level/$cap',
      atMax: price.atCap,
      buyCount: price.buyCount,
      totalCost: price.atCap ? null : price.totalCost,
      affordable: price.affordable,
      onTap: () => _snack(context, onUpgrade()),
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

/// 서브탭 상단의 한 줄 역할 안내.
class _RoleHint extends StatelessWidget {
  const _RoleHint({
    required this.icon,
    required this.color,
    required this.text,
  });
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w800,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
