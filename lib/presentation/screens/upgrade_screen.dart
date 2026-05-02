import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../core/utils/big_number.dart';
import '../../data/balance/pickaxe_data.dart';
import '../../data/balance/producer_data.dart';
import '../../data/balance/tap_upgrade_data.dart';
import '../providers/game_provider.dart';
import '../widgets/bulk_mode_bar.dart';
import '../widgets/upgrade_card.dart';

/// 강화 화면 — sw_clicker의 upgrade_screen 매핑.
/// 3 서브탭: 터치 (탭 강화) / 동료 (광부) / 곡괭이 (메인 곡괭이 7스탯)
class UpgradeScreen extends ConsumerWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          _Header(),
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
                Tab(height: 36, text: '동료'),
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

// ===== 터치 탭 =====

class _TapTab extends ConsumerWidget {
  const _TapTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final state = game.state;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: kTapUpgrades.length,
      itemBuilder: (_, i) {
        final def = kTapUpgrades[i];
        final lv = state.tapUpgrades[def.id] ?? 0;
        final plan = game.previewBulk(
          currentLevel: lv,
          cap: null,
          costFn: (l) => TapUpgradeBalance.upgradeCost(def, l),
        );
        final addedNow = BigNumberFormat.format(lv * def.tapOrePerLevel);
        final addedNext =
            BigNumberFormat.format((lv + 1) * def.tapOrePerLevel);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: UpgradeCard(
            title: def.name,
            icon: def.icon,
            iconColor: def.accent,
            subtitle:
                '${def.description} (현재 +$addedNow → +$addedNext)',
            hint: '레벨업 비용 ×1.10',
            levelBadge: 'Lv.$lv',
            buttonLabel: '강화',
            buttonTimes: plan.times,
            cost: plan.times > 0 ? plan.cost : null,
            enabled: plan.times > 0,
            onTap: () => _snack(context, game.upgradeTap(def.id)),
          ),
        );
      },
    );
  }
}

// ===== 동료 탭 (광부 13종) =====

class _CompanionTab extends ConsumerWidget {
  const _CompanionTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final state = game.state;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: kProducers.length,
      itemBuilder: (_, i) {
        final def = kProducers[i];
        final lv = state.producers[def.id]?.level ?? 0;
        final plan = game.previewBulk(
          currentLevel: lv,
          cap: null,
          costFn: (l) => ProducerBalance.upgradeCost(def, l),
        );
        final ops = ProducerBalance.orePerSec(def, lv);
        final nextOps = lv == 0
            ? def.baseOrePerSec
            : ProducerBalance.orePerSec(def, lv + 1);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: UpgradeCard(
            title: def.name,
            icon: def.icon,
            iconColor: def.accent,
            emoji: def.emoji,
            subtitle: lv == 0
                ? '미영입 (Lv1: ${BigNumberFormat.format(def.baseOrePerSec)} 광석/초)'
                : '${BigNumberFormat.format(ops)} → ${BigNumberFormat.format(nextOps)} 광석/초',
            hint: '25/50/100/250/500 레벨 마일스톤마다 ×2',
            levelBadge: lv == 0 ? '미영입' : 'Lv.$lv',
            buttonLabel: lv == 0 ? '영입' : '강화',
            buttonTimes: plan.times,
            cost: plan.times > 0 ? plan.cost : null,
            enabled: plan.times > 0,
            onTap: () => _snack(context, game.upgradeProducer(def.id)),
          ),
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
        _row(
          context,
          game: game,
          title: '곡괭이 데미지',
          icon: Icons.flash_on,
          color: AppColors.gold,
          level: pickaxe.damageLevel,
          cap: null,
          costFn: PickaxeBalance.damageUpgradeCost,
          subtitle: '곡괭이질 1번에 광석 ${PickaxeBalance.orePerSwing(pickaxe)}개',
          hint: '강화하면 한 번에 캐는 광석이 늘어납니다.',
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
          subtitle:
              '간격 ${PickaxeBalance.swingInterval(pickaxe).toStringAsFixed(2)}초',
          hint: '강화하면 더 빠르게 채굴합니다.',
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
          subtitle:
              '현재 확률 ${game.currentCritChance.toStringAsFixed(1)}%',
          hint: '레벨당 +0.5%, 최대 +25%까지',
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
          subtitle:
              '크리티컬 시 ×${game.currentCritMultiplier.toStringAsFixed(1)}',
          hint: '레벨당 +0.2배, 최대 ×8까지',
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
          subtitle:
              '환전 보너스 +${(game.currentSellBonus * 100).toStringAsFixed(0)}%',
          hint: '광석을 팔 때 받는 코인이 늘어납니다',
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
          subtitle:
              '확률 ${PickaxeBalance.chainMineProb(pickaxe.chainMineLevel).toStringAsFixed(1)}%',
          hint: '탭 후 확률적으로 즉시 한 번 더 휘두릅니다',
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
          subtitle:
              '신규 발견 시 보석 +${3 + PickaxeBalance.luckGemBonus(pickaxe.luckLevel)}',
          hint: '광석 신규 발견 시 받는 보석이 늘어납니다',
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
    required String subtitle,
    required String hint,
    required ActionResult Function() onUpgrade,
  }) {
    final atCap = cap != null && level >= cap;
    final plan = game.previewBulk(
      currentLevel: level,
      cap: cap,
      costFn: costFn,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: UpgradeCard(
        title: title,
        icon: icon,
        iconColor: color,
        subtitle: subtitle,
        hint: atCap ? '최대 레벨에 도달했습니다.' : hint,
        levelBadge: cap == null ? 'Lv.$level' : '$level/$cap',
        buttonLabel: atCap ? '최대' : '강화',
        buttonTimes: plan.times,
        cost: atCap ? null : (plan.times > 0 ? plan.cost : null),
        enabled: !atCap && plan.times > 0,
        onTap: () => _snack(context, onUpgrade()),
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
