import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../core/utils/big_number.dart';

/// 강화 카드 — sw_clicker `UpgradeTile` 스타일 가로형.
///
/// 한 행 구조:
///   [아이콘 박스] [이름+레벨뱃지 / 부제 / 다음효과 pill] [구매 버튼]
///
/// 구매 버튼은 코인 부족이어도 비용을 그대로 표시하고 회색으로
/// 비활성화될 뿐, "코인 부족" 같은 라벨은 사용하지 않는다.
class UpgradeCard extends StatelessWidget {
  const UpgradeCard({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.subtitle,
    required this.gainPill,
    required this.levelBadge,
    required this.buyCount,
    required this.totalCost,
    required this.affordable,
    required this.onTap,
    this.emoji,
    this.atMax = false,
    this.costColor = AppColors.gold,
    this.costIcon = Icons.monetization_on_outlined,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final String? emoji;

  /// 현재 효과/상태 한 줄 (예: "곡괭이질 1번에 광석 8개")
  final String subtitle;

  /// 다음 +1 효과 — pill 형태로 표시 (예: "다음 +1 → 11개")
  final String gainPill;

  /// "Lv.5" / "5/50" / "미영입" 같은 레벨 뱃지
  final String levelBadge;

  /// 현재 모드의 구매 횟수 (×1 모드면 1, ×10이면 10 등)
  final int buyCount;

  /// 현재 모드의 합계 비용 — 살 수 없어도 그대로 표시. 최대 도달이면 null.
  final double? totalCost;

  /// 살 수 있는가
  final bool affordable;

  final VoidCallback onTap;

  /// 최대 레벨 도달 여부 — 버튼이 "최대"로 바뀜
  final bool atMax;

  /// 환생 트리는 별 아이콘
  final Color costColor;
  final IconData costIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: affordable && !atMax
              ? iconColor.withValues(alpha: 0.6)
              : AppColors.dividerColor,
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          // 좌: 아이콘
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: emoji != null
                ? Text(emoji!, style: const TextStyle(fontSize: 26))
                : Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 10),
          // 가운데: 이름 / 부제 / 다음 효과 pill
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        levelBadge,
                        style: TextStyle(
                          fontSize: 10,
                          color: iconColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 5),
                _GainPill(label: gainPill, color: iconColor),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 우: 구매 버튼
          _BuyButton(
            buyCount: buyCount,
            totalCost: totalCost,
            affordable: affordable,
            atMax: atMax,
            costColor: costColor,
            costIcon: costIcon,
            iconColor: iconColor,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

class _GainPill extends StatelessWidget {
  const _GainPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _BuyButton extends StatelessWidget {
  const _BuyButton({
    required this.buyCount,
    required this.totalCost,
    required this.affordable,
    required this.atMax,
    required this.costColor,
    required this.costIcon,
    required this.iconColor,
    required this.onTap,
  });

  final int buyCount;
  final double? totalCost;
  final bool affordable;
  final bool atMax;
  final Color costColor;
  final IconData costIcon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // 색상 결정
    final Color bg;
    final Color fg;
    if (atMax) {
      bg = AppColors.dividerColor;
      fg = AppColors.textSecondary;
    } else if (affordable) {
      bg = iconColor;
      fg = Colors.white;
    } else {
      // 살 수 없을 때 — 회색이지만 텍스트는 그대로 보임
      bg = AppColors.dividerColor;
      fg = AppColors.textSecondary;
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: (!atMax && affordable) ? onTap : null,
        child: Container(
          width: 92,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                atMax ? '최대' : '×$buyCount',
                style: TextStyle(
                  color: fg,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              if (!atMax && totalCost != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(costIcon,
                        color: affordable ? fg : costColor, size: 14),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        BigNumberFormat.format(totalCost!),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: affordable ? fg : costColor,
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

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});
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
