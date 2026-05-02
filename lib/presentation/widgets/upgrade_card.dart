import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../core/utils/big_number.dart';

/// 일괄 구매 카드 — 곡괭이/광부/탭강화/조수 시트에서 공통 사용.
class UpgradeCard extends StatelessWidget {
  const UpgradeCard({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.subtitle,
    required this.hint,
    required this.levelBadge,
    required this.buttonLabel,
    required this.buttonTimes,
    required this.cost,
    required this.enabled,
    required this.onTap,
    this.emoji,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final String subtitle;
  final String hint;
  final String levelBadge;
  final String buttonLabel;
  final int buttonTimes;
  final double? cost;
  final bool enabled;
  final VoidCallback onTap;
  final String? emoji;

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
                                fontWeight: FontWeight.w800,
                                fontSize: 14),
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

/// 시트 상단 핸들 — 모든 시트가 공유
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
