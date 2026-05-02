import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../providers/game_provider.dart';

/// 설정 화면 — 자동환전 / 게임 정보 / 디버그 초기화.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final state = game.state;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
      children: [
        const _SectionTitle('환전'),
        _AutoSellCard(game: game),
        const SizedBox(height: 16),
        const _SectionTitle('게임 정보'),
        _InfoCard(
          rows: [
            ('환생 횟수', '${state.rebirthCount}회'),
            ('누적 채굴', '${state.totalSwings}회'),
            ('도감 발견', '${state.discoveredOres.length}종'),
            ('보석', '${state.gem}개'),
            ('별의 결정', '${state.stardust}개'),
          ],
        ),
        const SizedBox(height: 16),
        const _SectionTitle('앱'),
        _InfoCard(rows: const [
          ('버전', '0.3.0 (sw_clicker 5탭 구조)'),
          ('빌드', '광산 클리커 베타'),
        ]),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => _confirmReset(context, game),
          icon: const Icon(Icons.delete_forever, size: 18),
          label: const Text(
            '진행도 모두 초기화',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B6B),
            minimumSize: const Size(double.infinity, 44),
          ),
        ),
      ],
    );
  }

  void _confirmReset(BuildContext context, GameProvider game) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('진행도 초기화'),
        content: const Text(
          '모든 진행도(코인/광석/광부/탭강화/조수/광맥/정수/환생/별의 결정)가 영구 삭제됩니다.\n\n'
          '되돌릴 수 없습니다. 정말 진행하시겠습니까?',
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              await game.hardReset();
              if (context.mounted) Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
            ),
            child: const Text(
              '초기화',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});
  final List<(String label, String value)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                color: AppColors.dividerColor,
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Text(
                    rows[i].$1,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    rows[i].$2,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AutoSellCard extends StatelessWidget {
  const _AutoSellCard({required this.game});
  final GameProvider game;

  @override
  Widget build(BuildContext context) {
    final state = game.state;
    final unlocked = state.autoSellUnlocked;
    final on = state.autoSell;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: on
              ? AppColors.gold
              : (unlocked
                  ? AppColors.dividerColor
                  : AppColors.tierEpic.withValues(alpha: 0.6)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                on
                    ? Icons.toggle_on
                    : (unlocked ? Icons.toggle_off : Icons.lock),
                color: on
                    ? AppColors.gold
                    : (unlocked
                        ? AppColors.textSecondary
                        : AppColors.tierEpic),
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '자동 환전',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      !unlocked
                          ? '잠금 상태 — 보석 ${GameProvider.autoSellUnlockGemCost}개로 해제'
                          : (on
                              ? '광석을 캐자마자 코인으로 자동 변환됩니다'
                              : '수집 모드 — 광석이 인벤토리에 쌓입니다'),
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
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              if (!unlocked) {
                final r = game.unlockAutoSell();
                if (!r.ok && r.message != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(r.message!),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              } else {
                game.toggleAutoSell();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: !unlocked
                  ? AppColors.tierEpic
                  : (on ? AppColors.minerDusk : AppColors.gold),
              foregroundColor: !unlocked || on ? Colors.white : Colors.black,
              minimumSize: const Size(double.infinity, 40),
            ),
            child: Text(
              !unlocked
                  ? '잠금 해제 (보석 ${GameProvider.autoSellUnlockGemCost}개)'
                  : (on ? '수집 모드로 전환' : '자동 환전 켜기'),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
