import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../core/utils/big_number.dart';

/// 일괄 구매 카드 — 모든 강화 화면에서 공통으로 쓰임.
///
/// 다음 정보를 한 카드에 모두 노출한다:
/// - 현재 효과 ([subtitle])
/// - 다음 +1 단위 비용/효과 ([nextStepCost] + [nextStepGain]) — 항상 표시
/// - 일괄 모드 합계 ([bulkTimes] + [bulkTotalCost]) — 모드가 ×1이 아닐 때
/// - 버튼: 실제 구매 가능한 횟수 + 합계 비용
class UpgradeCard extends StatelessWidget {
  const UpgradeCard({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.subtitle,
    required this.levelBadge,
    required this.nextStepCost,
    required this.nextStepGain,
    required this.bulkTimes,
    required this.bulkTotalCost,
    required this.buttonLabel,
    required this.enabled,
    required this.onTap,
    this.emoji,
    this.atMax = false,
    this.costColor = AppColors.gold,
    this.costIcon = Icons.monetization_on_outlined,
  });

  /// 제목
  final String title;
  final IconData icon;
  final Color iconColor;
  final String? emoji;

  /// 현재 효과 (예: "광석/초 1.2K", "탭당 +500", "데미지 ×7")
  final String subtitle;

  /// "Lv.12" 또는 "12/50" 같은 레벨 배지 텍스트
  final String levelBadge;

  /// 다음 +1 비용 — 항상 표시 (살 수 없어도). 최대 레벨이면 null.
  final double? nextStepCost;

  /// 다음 +1 효과 한 줄 (예: "→ 광석/초 1.5K"). 없으면 null.
  final String? nextStepGain;

  /// 일괄 모드에서 살 수 있는 횟수. ×1이거나 buyable이 1이면 1.
  final int bulkTimes;

  /// 일괄 합계 비용 — bulkTimes ≥ 2일 때만 별도 표시.
  final double? bulkTotalCost;

  /// "강화" / "영입" / "최대" 같은 버튼 라벨
  final String buttonLabel;

  /// 버튼 활성 여부
  final bool enabled;
  final VoidCallback onTap;

  /// 최대 레벨에 도달했는가
  final bool atMax;

  /// 비용 표시 색상 — 환생 트리는 별의 결정(노랑), 그 외 코인(노랑) 동일
  final Color costColor;
  final IconData costIcon;

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
          _header(),
          const SizedBox(height: 8),
          _infoBox(),
          const SizedBox(height: 10),
          _button(),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: emoji != null
              ? Text(emoji!, style: const TextStyle(fontSize: 24))
              : Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
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
                      levelBadge,
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
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.starlightCream,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 회색 박스 — 다음 +1 비용/효과 + (있으면) ×N 일괄 합계
  Widget _infoBox() {
    if (atMax) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.dividerColor),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline,
                size: 14, color: AppColors.gold),
            SizedBox(width: 6),
            Text(
              '최대 레벨에 도달했습니다',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.gold,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    final showBulk = bulkTimes > 1 && bulkTotalCost != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 다음 +1 라인 (항상)
          Row(
            children: [
              const SizedBox(
                width: 56,
                child: Text(
                  '다음 +1',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (nextStepCost != null) ...[
                Icon(costIcon, color: costColor, size: 12),
                const SizedBox(width: 2),
                Text(
                  BigNumberFormat.format(nextStepCost!),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: costColor,
                  ),
                ),
              ] else
                const Text(
                  '-',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              if (nextStepGain != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    nextStepGain!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.starlightCream,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          // ×N 합계 라인 (일괄 모드일 때만)
          if (showBulk) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                SizedBox(
                  width: 56,
                  child: Text(
                    '×$bulkTimes 합계',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(costIcon, color: costColor, size: 12),
                const SizedBox(width: 2),
                Text(
                  BigNumberFormat.format(bulkTotalCost!),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: costColor,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '($bulkTimes 레벨 강화)',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _button() {
    final hasAffordable = bulkTimes > 0 && bulkTotalCost != null;
    final showCount = hasAffordable && bulkTimes > 1;
    final label = atMax
        ? '최대'
        : (hasAffordable
            ? (showCount ? '$buttonLabel ×$bulkTimes' : buttonLabel)
            : '코인 부족');

    return ElevatedButton(
      onPressed: enabled ? onTap : null,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            enabled ? iconColor : AppColors.dividerColor,
        minimumSize: const Size(double.infinity, 38),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800),
          ),
          if (hasAffordable && bulkTotalCost != null) ...[
            const SizedBox(width: 8),
            Icon(costIcon, size: 13, color: Colors.white),
            const SizedBox(width: 2),
            Text(
              BigNumberFormat.format(bulkTotalCost!),
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }
}

/// 시트 상단 핸들 (예전 모달 시트 잔재 — 인벤토리 시트만 사용)
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
