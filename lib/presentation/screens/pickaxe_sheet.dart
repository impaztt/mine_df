import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../core/utils/big_number.dart';
import '../../data/balance/ore_data.dart';
import '../../data/balance/pickaxe_data.dart';
import '../providers/game_provider.dart';
import '../widgets/bulk_mode_bar.dart';

/// 곡괭이 / 광맥 강화 시트 — 8개 강화 카드.
class PickaxeSheet extends ConsumerWidget {
  const PickaxeSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final state = game.state;
    final pickaxe = state.pickaxe;

    final ore = oreByRank(state.mineRank);
    final nextOre = state.mineRank < maxMineRank
        ? oreByRank(state.mineRank + 1)
        : null;

    final mineCost = mineUpgradeCost(state.mineRank);
    final swingPerSec = 1 / game.currentSwingInterval;
    final orePerSwing = game.currentOrePerSwing;
    final coinPerSwing =
        orePerSwing * ore.coinValue * (1 + game.currentSellBonus);
    final coinPerSec = coinPerSwing * swingPerSec;

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
              const BulkModeBar(),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 채굴 정보 요약 — 1번에 몇 개, 1개당 얼마, 초당 등
                    _SummaryCard(
                      oreEmoji: ore.emoji,
                      oreName: ore.name,
                      oreValue: ore.coinValue,
                      orePerSwing: orePerSwing,
                      coinPerSwing: coinPerSwing,
                      swingInterval: game.currentSwingInterval,
                      coinPerSec: coinPerSec,
                    ),
                    const SizedBox(height: 12),

                    // === 1. 광맥 등급 (단발) ===
                    _UpgradeCard(
                      title: '광맥 등급',
                      icon: Icons.diamond_outlined,
                      iconColor: ore.color,
                      level: state.mineRank,
                      capLabel: '${state.mineRank}/$maxMineRank',
                      sub: '현재: ${ore.name} '
                          '(1개 = ${BigNumberFormat.format(ore.coinValue)} 코인)',
                      hint: nextOre == null
                          ? '최고 등급에 도달했습니다.'
                          : '다음: ${nextOre.name} '
                              '(1개 = ${BigNumberFormat.format(nextOre.coinValue)} 코인)',
                      times: 1,
                      cost: nextOre == null ? null : mineCost,
                      enabled: nextOre != null && state.coin >= mineCost,
                      buttonLabel: '광맥 강화',
                      onTap: () => _runResult(
                          context, () => game.upgradeMineRank()),
                    ),
                    const SizedBox(height: 10),

                    // === 2. 곡괭이 데미지 ===
                    _BulkUpgradeCard(
                      title: '곡괭이 데미지',
                      icon: Icons.flash_on,
                      iconColor: AppColors.gold,
                      level: pickaxe.damageLevel,
                      capLabel: null,
                      sub:
                          '곡괭이질 1번에 광석 ${PickaxeBalance.orePerSwing(pickaxe)}개',
                      hint: '강화하면 한 번에 캐는 광석이 늘어납니다.',
                      currentLevel: pickaxe.damageLevel,
                      cap: null,
                      costFn: PickaxeBalance.damageUpgradeCost,
                      onUpgrade: (n) => _runResult(
                          context, () => game.upgradePickaxeDamage(n)),
                    ),
                    const SizedBox(height: 10),

                    // === 3. 곡괭이 속도 ===
                    _BulkUpgradeCard(
                      title: '곡괭이 속도',
                      icon: Icons.speed,
                      iconColor: AppColors.crystalTeal,
                      level: pickaxe.speedLevel,
                      capLabel: null,
                      sub:
                          '곡괭이질 간격 ${PickaxeBalance.swingInterval(pickaxe).toStringAsFixed(2)}초',
                      hint: '강화하면 더 빠르게 채굴합니다.',
                      currentLevel: pickaxe.speedLevel,
                      cap: null,
                      costFn: PickaxeBalance.speedUpgradeCost,
                      onUpgrade: (n) => _runResult(
                          context, () => game.upgradePickaxeSpeed(n)),
                    ),
                    const SizedBox(height: 10),

                    // === 4. 크리티컬 확률 ===
                    _BulkUpgradeCard(
                      title: '크리티컬 확률',
                      icon: Icons.bolt,
                      iconColor: AppColors.rubyPink,
                      level: pickaxe.critChanceLevel,
                      capLabel:
                          '${pickaxe.critChanceLevel}/${PickaxeBalance.critChanceCap}',
                      sub:
                          '현재 확률 ${game.currentCritChance.toStringAsFixed(1)}%',
                      hint: '레벨당 +0.5%, 최대 +25%까지.',
                      currentLevel: pickaxe.critChanceLevel,
                      cap: PickaxeBalance.critChanceCap,
                      costFn: PickaxeBalance.critChanceUpgradeCost,
                      onUpgrade: (n) => _runResult(
                          context, () => game.upgradeCritChance(n)),
                    ),
                    const SizedBox(height: 10),

                    // === 5. 크리티컬 위력 ===
                    _BulkUpgradeCard(
                      title: '크리티컬 위력',
                      icon: Icons.local_fire_department_outlined,
                      iconColor: const Color(0xFFFF6B5C),
                      level: pickaxe.critPowerLevel,
                      capLabel:
                          '${pickaxe.critPowerLevel}/${PickaxeBalance.critPowerCap}',
                      sub:
                          '크리티컬 시 ×${game.currentCritMultiplier.toStringAsFixed(1)} 데미지',
                      hint: '레벨당 +0.2배, 최대 ×8까지.',
                      currentLevel: pickaxe.critPowerLevel,
                      cap: PickaxeBalance.critPowerCap,
                      costFn: PickaxeBalance.critPowerUpgradeCost,
                      onUpgrade: (n) => _runResult(
                          context, () => game.upgradeCritPower(n)),
                    ),
                    const SizedBox(height: 10),

                    // === 6. 광석 제련 ===
                    _BulkUpgradeCard(
                      title: '광석 제련',
                      icon: Icons.local_mall_outlined,
                      iconColor: AppColors.gold,
                      level: pickaxe.smeltLevel,
                      capLabel:
                          '${pickaxe.smeltLevel}/${PickaxeBalance.smeltCap}',
                      sub:
                          '환전 보너스 +${(game.currentSellBonus * 100).toStringAsFixed(0)}%',
                      hint: '광석을 팔 때 받는 코인이 늘어납니다.',
                      currentLevel: pickaxe.smeltLevel,
                      cap: PickaxeBalance.smeltCap,
                      costFn: PickaxeBalance.smeltUpgradeCost,
                      onUpgrade: (n) => _runResult(
                          context, () => game.upgradeSmelt(n)),
                    ),
                    const SizedBox(height: 10),

                    // === 7. 연쇄 채굴 ===
                    _BulkUpgradeCard(
                      title: '연쇄 채굴',
                      icon: Icons.repeat,
                      iconColor: AppColors.tierEpic,
                      level: pickaxe.chainMineLevel,
                      capLabel:
                          '${pickaxe.chainMineLevel}/${PickaxeBalance.chainMineCap}',
                      sub:
                          '확률 ${PickaxeBalance.chainMineProb(pickaxe.chainMineLevel).toStringAsFixed(1)}%',
                      hint: '곡괭이질 후 확률적으로 즉시 한 번 더 휘두릅니다.',
                      currentLevel: pickaxe.chainMineLevel,
                      cap: PickaxeBalance.chainMineCap,
                      costFn: PickaxeBalance.chainMineUpgradeCost,
                      onUpgrade: (n) => _runResult(
                          context, () => game.upgradeChainMine(n)),
                    ),
                    const SizedBox(height: 10),

                    // === 8. 별의 운 ===
                    _BulkUpgradeCard(
                      title: '별의 운',
                      icon: Icons.auto_awesome,
                      iconColor: AppColors.starlightCream,
                      level: pickaxe.luckLevel,
                      capLabel:
                          '${pickaxe.luckLevel}/${PickaxeBalance.luckCap}',
                      sub:
                          '신규 광석 발견 시 보석 +${3 + PickaxeBalance.luckGemBonus(pickaxe.luckLevel)}',
                      hint: '광석을 새로 발견하면 받는 보석이 늘어납니다.',
                      currentLevel: pickaxe.luckLevel,
                      cap: PickaxeBalance.luckCap,
                      costFn: PickaxeBalance.luckUpgradeCost,
                      onUpgrade: (n) => _runResult(
                          context, () => game.upgradeLuck(n)),
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

  void _runResult(BuildContext context, ActionResult Function() fn) {
    final r = fn();
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

/// 채굴 정보 요약 — "1번에 N개 × M코인 = T코인 / 초당 X코인"
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.oreEmoji,
    required this.oreName,
    required this.oreValue,
    required this.orePerSwing,
    required this.coinPerSwing,
    required this.swingInterval,
    required this.coinPerSec,
  });

  final String oreEmoji;
  final String oreName;
  final double oreValue;
  final int orePerSwing;
  final double coinPerSwing;
  final double swingInterval;
  final double coinPerSec;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(oreEmoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                oreName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: '곡괭이질 1회',
            value:
                '$orePerSwing개 × ${BigNumberFormat.format(oreValue)} = ${BigNumberFormat.format(coinPerSwing)} 코인',
          ),
          _SummaryRow(
            label: '곡괭이 속도',
            value:
                '${swingInterval.toStringAsFixed(2)}초 마다 (초당 ${(1 / swingInterval).toStringAsFixed(1)}회)',
          ),
          _SummaryRow(
            label: '초당 코인',
            value: '${BigNumberFormat.format(coinPerSec)} 코인/초',
            highlight: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: highlight
                    ? AppColors.gold
                    : AppColors.starlightCream,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 광맥 등급 같은 단발 카드
class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.level,
    required this.capLabel,
    required this.sub,
    required this.hint,
    required this.times,
    required this.cost,
    required this.enabled,
    required this.buttonLabel,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final int level;
  final String? capLabel;
  final String sub;
  final String hint;
  final int times;
  final double? cost;
  final bool enabled;
  final String buttonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      icon: icon,
      iconColor: iconColor,
      title: title,
      level: level,
      capLabel: capLabel,
      sub: sub,
      hint: hint,
      buttonLabel: buttonLabel,
      buttonTimes: times,
      cost: cost,
      enabled: enabled,
      onTap: onTap,
    );
  }
}

/// 일괄 구매 가능한 강화 카드
class _BulkUpgradeCard extends ConsumerWidget {
  const _BulkUpgradeCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.level,
    required this.capLabel,
    required this.sub,
    required this.hint,
    required this.currentLevel,
    required this.cap,
    required this.costFn,
    required this.onUpgrade,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final int level;
  final String? capLabel;
  final String sub;
  final String hint;
  final int currentLevel;
  final int? cap;
  final double Function(int level) costFn;
  final void Function(int times) onUpgrade;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final plan = game.previewBulk(
      currentLevel: currentLevel,
      cap: cap,
      costFn: costFn,
    );
    final atCap = cap != null && currentLevel >= cap!;
    final enabled = !atCap && plan.times > 0;

    return _CardShell(
      icon: icon,
      iconColor: iconColor,
      title: title,
      level: level,
      capLabel: capLabel,
      sub: sub,
      hint: atCap ? '최대 레벨에 도달했습니다.' : hint,
      buttonLabel: atCap ? '최대' : '강화',
      buttonTimes: plan.times,
      cost: atCap ? null : plan.cost,
      enabled: enabled,
      onTap: () => onUpgrade(0), // 0 = bulk mode 사용
    );
  }
}

/// 카드 공통 쉘
class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.level,
    required this.capLabel,
    required this.sub,
    required this.hint,
    required this.buttonLabel,
    required this.buttonTimes,
    required this.cost,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final int level;
  final String? capLabel;
  final String sub;
  final String hint;
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
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
                              fontWeight: FontWeight.w800, fontSize: 14),
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
                            capLabel ?? 'Lv.$level',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.gold,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
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
          const SizedBox(height: 8),
          Text(
            hint,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: enabled ? onTap : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  enabled ? iconColor : AppColors.dividerColor,
              minimumSize: const Size(double.infinity, 38),
              padding: const EdgeInsets.symmetric(horizontal: 12),
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
                  const Icon(Icons.monetization_on_outlined,
                      size: 13, color: Colors.white),
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
