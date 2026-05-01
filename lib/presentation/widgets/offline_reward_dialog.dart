import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../core/utils/big_number.dart';

class OfflineRewardDialog extends StatelessWidget {
  const OfflineRewardDialog({super.key, required this.amount});
  final double amount;

  static Future<void> show(BuildContext context, double amount) {
    if (amount <= 0) return Future.value();
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => OfflineRewardDialog(amount: amount),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🌙 자리를 비운 사이',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.starlightCream,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '광부들이 부지런히 광물을 캤어요',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.diamond_outlined,
                    color: AppColors.crystalTeal, size: 28),
                const SizedBox(width: 8),
                Text(
                  '+${BigNumberFormat.format(amount)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.starlightCream,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('받기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
