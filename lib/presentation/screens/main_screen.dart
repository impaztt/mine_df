import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../core/utils/big_number.dart';
import '../../data/balance/ore_data.dart';
import '../game/starlit_mine_game.dart';
import '../providers/game_provider.dart';
import '../widgets/offline_reward_dialog.dart';
import '../widgets/resource_chip.dart';
import 'codex_sheet.dart';
import 'helper_sheet.dart';
import 'ore_inventory_sheet.dart';
import 'pickaxe_sheet.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
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
    return Scaffold(
      backgroundColor: AppColors.deepShaft,
      body: SafeArea(
        child: Column(
          children: [
            Consumer(
              builder: (_, ref, _) {
                ref.watch(gameProvider);
                return _topBar();
              },
            ),
            Expanded(
              child: Stack(
                children: [
                  RepaintBoundary(child: _gameView()),
                  Consumer(
                    builder: (_, ref, _) {
                      final game = ref.watch(gameProvider);
                      _maybeSyncGame(game);
                      if (game.activeSpirit == null) {
                        return const SizedBox.shrink();
                      }
                      return Positioned(
                        top: 16,
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
            Consumer(
              builder: (_, ref, _) {
                final game = ref.watch(gameProvider);
                return _bottomBar(game);
              },
            ),
          ],
        ),
      ),
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
    // 채굴 hit 동기화 (별이 swing + chip 발사)
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

  Widget _bottomBar(GameProvider game) {
    final state = game.state;
    final ore = oreByRank(state.mineRank);
    final coinPerSec = (1 / game.currentSwingInterval) *
        game.currentOrePerSwing *
        ore.coinValue *
        (1 + game.currentSellBonus);

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
                  Icons.monetization_on_outlined,
                  '코인',
                  BigNumberFormat.format(state.coin),
                  AppColors.gold,
                  subtitle: state.autoSell
                      ? '+${BigNumberFormat.format(coinPerSec)}/s'
                      : null,
                ),
                const SizedBox(width: 10),
                _autoSellToggle(game, state),
              ],
            ),
            const SizedBox(height: 6),
            // 광석 인벤토리 카드 (탭 → 시트, 모두팔기 버튼)
            _inventoryCard(game),
            const SizedBox(height: 8),
            // 현재 광석 라벨
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.cardBackgroundLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: ore.color.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Text(ore.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ore.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '곡괭이 데미지 ×${game.currentOrePerSwing} · '
                          '간격 ${game.currentSwingInterval.toStringAsFixed(2)}s',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${state.layer}층',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _bottomBtn(
                    icon: Icons.handyman,
                    label: '곡괭이',
                    onTap: () => _open(const PickaxeSheet()),
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
    IconData icon,
    String label,
    String value,
    Color color, {
    String? subtitle,
  }) {
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
                  Row(
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.gold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
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

  Widget _autoSellToggle(GameProvider game, dynamic state) {
    final unlocked = state.autoSellUnlocked as bool;
    final autoSell = state.autoSell as bool;

    final IconData icon;
    final Color color;
    final String label;
    if (!unlocked) {
      icon = Icons.lock;
      color = AppColors.tierEpic;
      label = '잠금해제';
    } else if (autoSell) {
      icon = Icons.toggle_on;
      color = AppColors.gold;
      label = '자동환전';
    } else {
      icon = Icons.toggle_off;
      color = AppColors.textSecondary;
      label = '수집모드';
    }

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        if (!unlocked) {
          _showAutoSellUnlockDialog(game);
        } else {
          final r = game.toggleAutoSell();
          if (!r.ok && r.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(r.message!),
                duration: const Duration(seconds: 1),
              ),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: autoSell
              ? AppColors.gold.withValues(alpha: 0.18)
              : (unlocked
                  ? AppColors.cardBackgroundLight
                  : AppColors.tierEpic.withValues(alpha: 0.10)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAutoSellUnlockDialog(GameProvider game) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Row(
          children: [
            Icon(Icons.lock_open, color: AppColors.tierEpic),
            SizedBox(width: 8),
            Text('자동환전 잠금 해제'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '자동환전을 켜면 광석을 캐자마자 코인으로 바뀝니다. '
              '한 번 잠금을 해제하면 영구적으로 사용할 수 있어요.',
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.cardBackgroundLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.diamond_outlined,
                      color: AppColors.crystalTeal),
                  const SizedBox(width: 8),
                  const Text(
                    '비용',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  Text(
                    '보석 ${GameProvider.autoSellUnlockGemCost}개',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.crystalTeal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '현재 보유: 보석 ${game.state.gem}개',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final r = game.unlockAutoSell();
              Navigator.of(context).pop();
              if (!r.ok && r.message != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(r.message!),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tierEpic,
            ),
            child: const Text('잠금 해제'),
          ),
        ],
      ),
    );
  }

  Widget _inventoryCard(GameProvider game) {
    final kinds = game.inventoryKindCount();
    final value = game.inventoryTotalValue();
    final empty = kinds == 0;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _open(const OreInventorySheet()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cardBackgroundLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: empty
                ? AppColors.dividerColor
                : AppColors.crystalTeal.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.crystalTeal,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '광석 인벤토리',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        empty ? '비어있음' : '$kinds종',
                        style: TextStyle(
                          fontSize: 11,
                          color: empty
                              ? AppColors.textSecondary
                              : AppColors.crystalTeal,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    empty
                        ? '곡괭이질로 광석을 모아보세요'
                        : '${BigNumberFormat.format(value)} 코인 가치',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: empty
                          ? AppColors.textSecondary
                          : AppColors.starlightCream,
                    ),
                  ),
                ],
              ),
            ),
            if (!empty)
              ElevatedButton(
                onPressed: () => game.sellAllInventory(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  minimumSize: const Size(0, 0),
                ),
                child: const Text(
                  '모두팔기',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
            else
              const Icon(Icons.chevron_right,
                  color: AppColors.textSecondary, size: 20),
          ],
        ),
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
          '별빛 광산 v0.2.0\n방치형 채굴 클리커.',
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

