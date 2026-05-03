import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../core/utils/big_number.dart';
import '../../data/balance/ore_data.dart';
import '../../data/balance/producer_data.dart';
import '../../data/models/game_state.dart';
import '../../data/models/ore_type.dart';
import '../game/starlit_mine_game.dart';
import '../providers/game_provider.dart';
import '../widgets/offline_reward_dialog.dart';
import '../widgets/ore_gem_icon.dart';
import 'inventory_sheet.dart';

/// 홈 화면 — 광산. 게임 영역 + 통합 인벤토리 카드.
/// 화면을 탭하면 광석을 즉시 채굴한다.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  StarlitMineGame? _game;
  int _lastLayer = 1;
  int _lastMineRank = 1;
  int _lastHelperHash = 0;
  bool _initShown = false;
  MineHit? _lastShownHit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    final game = ref.read(gameProvider);
    if (!game.initialized) {
      await game.initialize();
    }
    if (!mounted) return;

    if (!_initShown && game.pendingOfflineCoin > 0) {
      _initShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await OfflineRewardDialog.show(context, game.pendingOfflineCoin);
        game.pendingOfflineCoin = 0;
      });
    }

    _game = StarlitMineGame(providerRef: () => ref.read(gameProvider));
    _lastLayer = game.state.layer;
    _lastMineRank = game.state.mineRank;
    _lastHelperHash = _hashHelpers();
    setState(() {});
  }

  int _hashHelpers() {
    final s = ref.read(gameProvider).state;
    int h = 0;
    for (final v in s.helpers.values) {
      h = h * 31 + v.id.hashCode;
      h = h * 31 + (v.recruited ? 1 : 0);
      h = h * 31 + v.level;
    }
    return h;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      ref.read(gameProvider).persist();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 상단 자원 칩
        Consumer(
          builder: (_, ref, _) {
            ref.watch(gameProvider);
            return _topBar();
          },
        ),
        // 게임 캔버스
        Expanded(
          child: Stack(
            children: [
              RepaintBoundary(child: _gameView()),
              Consumer(
                builder: (_, ref, _) {
                  final game = ref.watch(gameProvider);
                  _maybeSyncGame(game);
                  return Stack(
                    children: [
                      if (game.activeSpirit != null)
                        Positioned(
                          top: 16,
                          right: 16,
                          child: _SpiritBadge(
                            onTap: () => game.claimSpirit(),
                          ),
                        ),
                      // 광부 스트립 — 영입한 광부들을 좌측 하단에 표시
                      Positioned(
                        left: 8,
                        right: 8,
                        bottom: 8,
                        child: _MinerStrip(state: game.state),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        // 통합 인벤토리
        Consumer(
          builder: (_, ref, _) {
            final game = ref.watch(gameProvider);
            return _inventoryArea(game);
          },
        ),
      ],
    );
  }

  void _maybeSyncGame(GameProvider game) {
    if (_game == null) return;
    final state = game.state;
    if (state.layer != _lastLayer) {
      _lastLayer = state.layer;
      _game!.syncLayer(state.layer);
    }
    if (state.mineRank != _lastMineRank) {
      _lastMineRank = state.mineRank;
      _game!.syncMineRank(state.mineRank);
    }
    final hh = _hashHelpers();
    if (hh != _lastHelperHash) {
      _lastHelperHash = hh;
      _game!.syncHelpers();
    }
    final h = game.lastHit;
    if (h != null && !identical(h, _lastShownHit)) {
      _lastShownHit = h;
      _game!.notifyMineHit(h);
    }
  }

  Widget _gameView() {
    if (_game == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }
    return GameWidget(
      key: const ValueKey('starlit-mine-game'),
      game: _game!,
    );
  }

  Widget _topBar() {
    final game = ref.read(gameProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Row(
        children: [
          _smallChip(
            icon: Icons.diamond_outlined,
            value: game.state.gem.toDouble(),
            color: AppColors.crystalTeal,
          ),
          const SizedBox(width: 6),
          _smallChip(
            icon: Icons.star_outline,
            value: game.state.stardust.toDouble(),
            color: AppColors.gold,
          ),
          const Spacer(),
          // 레이어 / 광맥 등급 짧은 정보
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.cardBackground.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.dividerColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.layers,
                    size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${game.state.layer}층 · 광맥 ${game.state.mineRank}등급'
                  '${game.state.essenceStage > 0 ? ' (+${game.state.essenceStage})' : ''}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallChip({
    required IconData icon,
    required double value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            BigNumberFormat.format(value),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _inventoryArea(GameProvider game) {
    final state = game.state;
    final entries = state.oreInventory.entries
        .where((e) => e.value > 0)
        .toList();
    entries.sort((a, b) {
      final ra = kOres.indexWhere((o) => o.id == a.key);
      final rb = kOres.indexWhere((o) => o.id == b.key);
      return ra.compareTo(rb);
    });

    final coinPerSec = game.currentCoinPerSec;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          top: BorderSide(color: AppColors.dividerColor),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const InventorySheet(),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackgroundLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.4),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.monetization_on_outlined,
                    color: AppColors.gold,
                    size: 22,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    BigNumberFormat.format(state.coin),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (state.autoSell)
                    Text(
                      '+${BigNumberFormat.format(coinPerSec)}/s',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.gold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const Spacer(),
                  if (entries.isNotEmpty)
                    ElevatedButton(
                      onPressed: () => game.sellAllInventory(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        minimumSize: const Size(0, 0),
                      ),
                      child: const Text(
                        '모두팔기',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 64,
                child: entries.isEmpty
                    ? const Center(
                        child: Text(
                          '아직 캔 광석이 없어요. 광맥을 탭해보세요!',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: entries.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: 6),
                        itemBuilder: (context, i) {
                          final e = entries[i];
                          final ore = kOres.firstWhere(
                            (o) => o.id == e.key,
                            orElse: () => kOres.first,
                          );
                          return _OreInventoryChip(
                            ore: ore,
                            count: e.value,
                            sellBonus: game.currentSellBonus,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpiritBadge extends StatelessWidget {
  const _SpiritBadge({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: AppColors.gold, width: 2),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🧙', style: TextStyle(fontSize: 22)),
              SizedBox(width: 6),
              Text(
                '산신령',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 1, end: 1.06, duration: 700.ms),
    );
  }
}

/// 영입한 광부들을 가로 스크롤로 보여주는 게임 캔버스 위 오버레이.
/// 각 광부는 이모지 + 레벨 뱃지 + 곡괭이질 흔들림 애니메이션.
class _MinerStrip extends StatelessWidget {
  const _MinerStrip({required this.state});
  final GameState state;

  @override
  Widget build(BuildContext context) {
    final recruited = <_MinerEntry>[];
    for (final def in kProducers) {
      final lv = state.producers[def.id]?.level ?? 0;
      if (lv > 0) {
        recruited.add(_MinerEntry(emoji: def.emoji, level: lv));
      }
    }
    if (recruited.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardBackground.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.dividerColor),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.engineering,
                color: AppColors.textSecondary, size: 14),
            SizedBox(width: 6),
            Text(
              '광부를 영입하면 자동 채굴이 시작됩니다',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: recruited.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) => _MinerAvatar(entry: recruited[i], index: i),
      ),
    );
  }
}

class _MinerEntry {
  final String emoji;
  final int level;
  const _MinerEntry({required this.emoji, required this.level});
}

class _MinerAvatar extends StatelessWidget {
  const _MinerAvatar({required this.entry, required this.index});
  final _MinerEntry entry;
  final int index;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 곡괭이질 — 위아래로 살짝 흔들림 (광부마다 위상 어긋나게)
          Center(
            child: Text(
              entry.emoji,
              style: const TextStyle(fontSize: 24),
            )
                .animate(
                  onPlay: (c) => c.repeat(reverse: true),
                  delay: (index * 120).ms,
                )
                .moveY(
                  begin: 0,
                  end: -3,
                  duration: 500.ms,
                  curve: Curves.easeInOut,
                ),
          ),
          // 레벨 뱃지
          Positioned(
            right: 0,
            bottom: -2,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${entry.level}',
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OreInventoryChip extends StatelessWidget {
  const _OreInventoryChip({
    required this.ore,
    required this.count,
    required this.sellBonus,
  });
  final OreDef ore;
  final double count;
  final double sellBonus;

  @override
  Widget build(BuildContext context) {
    final coin = count * ore.coinValue * (1 + sellBonus);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: ore.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ore.color.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          OreGemIcon(ore: ore, size: 26),
          const SizedBox(width: 6),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ore.name,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '×${BigNumberFormat.format(count)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: ore.color,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.monetization_on_outlined,
                    size: 10,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    BigNumberFormat.format(coin),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
