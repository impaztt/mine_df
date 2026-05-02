import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../core/utils/big_number.dart';
import '../../data/balance/helper_data.dart';
import '../../data/balance/ore_data.dart';
import '../providers/game_provider.dart';

class CodexSheet extends ConsumerStatefulWidget {
  const CodexSheet({super.key});

  @override
  ConsumerState<CodexSheet> createState() => _CodexSheetState();
}

class _CodexSheetState extends ConsumerState<CodexSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override
  Widget build(BuildContext context) {
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
              TabBar(
                controller: _tab,
                indicatorColor: AppColors.gold,
                labelColor: AppColors.gold,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: const [
                  Tab(text: '광석 도감'),
                  Tab(text: '조수'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    _OreList(state: state, controller: controller),
                    _HelperList(state: state, controller: controller),
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

class _OreList extends StatelessWidget {
  const _OreList({required this.state, required this.controller});
  final dynamic state;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.all(16),
      itemCount: kOres.length,
      itemBuilder: (context, i) {
        final ore = kOres[i];
        final discovered = state.discoveredOres.contains(ore.id);
        return _CodexCard(
          color: ore.color,
          tierLabel: ore.tier.label,
          tierColor: ore.tier.color,
          name: discovered ? ore.name : '???',
          subtitle: discovered
              ? '${ore.description}\n1개당 ${BigNumberFormat.format(ore.coinValue)} 코인'
              : '광맥을 더 강화해 발견하세요',
          emoji: ore.emoji,
          unlocked: discovered,
        );
      },
    );
  }
}

class _HelperList extends StatelessWidget {
  const _HelperList({required this.state, required this.controller});
  final dynamic state;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.all(16),
      itemCount: kHelpers.length,
      itemBuilder: (context, i) {
        final h = kHelpers[i];
        final cur = state.helpers[h.id];
        final recruited = cur?.recruited ?? false;
        return _CodexCard(
          color: h.color,
          tierLabel: h.tier.label,
          tierColor: h.tier.color,
          name: recruited ? '${h.name} (Lv.${cur.level})' : h.name,
          subtitle: h.description,
          emoji: h.emoji,
          unlocked: recruited,
        );
      },
    );
  }
}

class _CodexCard extends StatelessWidget {
  const _CodexCard({
    required this.color,
    required this.tierLabel,
    required this.tierColor,
    required this.name,
    required this.subtitle,
    required this.emoji,
    required this.unlocked,
  });

  final Color color;
  final String tierLabel;
  final Color tierColor;
  final String name;
  final String subtitle;
  final String emoji;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: ColorFiltered(
              colorFilter: unlocked
                  ? const ColorFilter.mode(
                      Colors.transparent, BlendMode.dst)
                  : const ColorFilter.matrix([
                      0, 0, 0, 0, 30, //
                      0, 0, 0, 0, 30,
                      0, 0, 0, 0, 30,
                      0, 0, 0, 1, 0,
                    ]),
              child: Text(
                emoji,
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
                        name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: tierColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tierLabel,
                        style: TextStyle(
                          fontSize: 10,
                          color: tierColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
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
