import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../core/utils/big_number.dart';

/// 화폐/자원 표시용 작은 칩
class ResourceChip extends StatelessWidget {
  const ResourceChip({
    super.key,
    required this.icon,
    required this.value,
    this.color = AppColors.starlightCream,
    this.compact = false,
  });

  final IconData icon;
  final double value;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: compact ? 14 : 16),
          const SizedBox(width: 4),
          Text(
            BigNumberFormat.format(value),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 11 : 13,
            ),
          ),
        ],
      ),
    );
  }
}
