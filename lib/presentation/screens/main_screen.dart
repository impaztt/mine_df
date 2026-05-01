import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../core/constants/game_constants.dart';
import '../../core/utils/big_number.dart';
import '../../data/balance/ore_data.dart';
import '../game/starlit_mine_game.dart';
import '../providers/game_provider.dart';
import '../widgets/offline_reward_dialog.dart';
import '../widgets/resource_chip.dart';
import 'codex_sheet.dart';
import 'facility_sheet.dart';
import 'helper_sheet.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
    with WidgetsBindingObserver {
  StarlitMineGame? _game;
  int _lastLayer = 1;
  int _lastHelperHash = 0;
  bool _initShown = false;

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

    if (!_initShown && game.pendingOfflineOre > 0) {
      _initShown = true;
      // 첫 프레임 이후 다이얼로그
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await OfflineRewardDialog.show(context, game.pendingOfflineOre);
        game.pendingOfflineOre = 0;
      });
    }

    _game = StarlitMineGame(providerRef: () => ref.read(gameProvider));
    _lastLayer = game.state.layer;
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
    return Scaffold(
      backgroundColor: AppColors.deepShaft,
      body: SafeArea(
        child: Column(
          children: [
            // 상단바는 화폐만 보면 되므로 별도 Consumer로 격리
            Consumer(
              builder: (_, ref, __) {
                ref.watch(gameProvider);
                return _topBar(null);
              },
            ),
            Expanded(
              child: Stack(
                children: [
                  // GameWidget은 절대 부모 리빌드의 영향을 받지 않게 분리.
                  // _game 인스턴스는 안정적이므로 RepaintBoundary로 격리.
                  RepaintBoundary(child: _gameView()),
                  // 산신령 배지만 별도 Consumer
                  Consumer(
                    builder: (_, ref, __) {
                      final game = ref.watch(gameProvider);
                      // 광맥/조수 동기화는 여기서만 수행
                      _maybeSyncGame(game.state);
                      if (game.activeSpirit == null) {
                        return const SizedBox.shrink();
                      }
                      return Positioned(
                        top: 24,
                        right: 16,
                        child: _SpiritBadge(
                          onTap: () => game.claimSpirit(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // 하단바도 별도 Consumer
            Consumer(
              builder: (_, ref, __) {
                final game = ref.watch(gameProvider);
                return _bottomBar(game.state);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _maybeSyncGame(dynamic state) {
    if (_game == null) return;
    if (state.layer != _lastLayer) {
      _lastLayer = state.layer;
      _game!.syncLayer(state.layer);
    }
    final hh = _hashHelpers();
    if (hh != _lastHelperHash) {
      _lastHelperHash = hh;
      _game!.syncHelpers();
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

  Widget _topBar(dynamic state) {
    final game = ref.read(gameProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Row(
        children: [
          ResourceChip(
            icon: Icons.diamond_outlined,
            value: game.state.gem.toDouble(),
            color: AppColors.crystalTeal,
            compact: true,
          ),
          const SizedBox(width: 6),
          ResourceChip(
            icon: Icons.star_outline,
            value: game.state.stardust.toDouble(),
            color: AppColors.gold,
            compact: true,
          ),
          const Spacer(),
          IconButton(
            onPressed: _showSettings,
            icon: const Icon(Icons.settings, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(dynamic state) {
    final required = GameConstants.enemiesPerDay(state.day);
    final progress =
        (state.dayKills / required).clamp(0.0, 1.0).toDouble();
    final ore = oreForDay(state.day) ?? kOres.first;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          top: BorderSide(color: AppColors.dividerColor),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: Column(
          children: [
            Row(
              children: [
                _resourceTile(
                  Icons.terrain,
                  '광물',
                  BigNumberFormat.format(state.ore),
                  AppColors.crystalTeal,
                ),
                const SizedBox(width: 10),
                _resourceTile(
                  Icons.monetization_on_outlined,
                  '코인',
                  BigNumberFormat.format(state.coin),
                  AppColors.gold,
                ),
                const SizedBox(width: 10),
                _hpDisplay(state.mineHp),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  state.bossPhase ? 'DAY ${state.day} · 보스!' : 'DAY ${state.day}',
                  style: TextStyle(
                    color: state.bossPhase
                        ? const Color(0xFFFF6B5C)
                        : AppColors.starlightCream,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                )
                    .animate(target: state.bossPhase ? 1 : 0)
                    .shake(hz: 2, duration: 600.ms),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: state.bossPhase ? 1 : progress,
                      minHeight: 8,
                      backgroundColor: AppColors.cardBackgroundLight,
                      valueColor: AlwaysStoppedAnimation(
                        state.bossPhase
                            ? const Color(0xFFFF6B5C)
                            : AppColors.gold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  state.bossPhase
                      ? 'BOSS'
                      : '${state.dayKills}/$required',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.layers, size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${state.layer}층 · 발사: ${ore.name}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _bottomBtn(
                    icon: Icons.handyman,
                    label: '시설',
                    onTap: () => _open(const FacilitySheet()),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _bottomBtn(
                    icon: Icons.pets,
                    label: '조수',
                    onTap: () => _open(const HelperSheet()),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _bottomBtn(
                    icon: Icons.menu_book_outlined,
                    label: '도감',
                    onTap: () => _open(const CodexSheet()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _resourceTile(
      IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardBackgroundLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hpDisplay(int hp) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: List.generate(5, (i) {
          final filled = i < hp;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Icon(
              filled ? Icons.favorite : Icons.favorite_border,
              size: 14,
              color: filled
                  ? const Color(0xFFFF6B9D)
                  : AppColors.dividerColor,
            ),
          );
        }),
      ),
    );
  }

  Widget _bottomBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cardBackgroundLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.dividerColor),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.gold, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _open(Widget sheet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => sheet,
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('설정'),
        content: const Text(
          '별빛 광산 v0.1.0\n프로토타입 빌드입니다.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(gameProvider).hardReset();
              if (mounted) Navigator.of(context).pop();
            },
            child: const Text(
              '초기화 (디버그)',
              style: TextStyle(color: Color(0xFFFF6B6B)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
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
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.5),
                blurRadius: 12,
              ),
            ],
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
