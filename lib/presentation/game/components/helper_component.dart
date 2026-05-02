import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors, FontWeight;

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../data/models/helper.dart';

/// 광산 옆에서 함께 곡괭이질하는 조수 (이모지 기반 SD)
class HelperComponent extends PositionComponent {
  HelperComponent({
    required this.def,
    required this.level,
  }) : super(size: Vector2(40, 48), anchor: Anchor.bottomCenter);

  final HelperDef def;
  final int level;
  double _t = 0;

  late final TextPaint _emojiPainter = TextPaint(
    style: AppTheme.koreanStyle(
      fontSize: 26,
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
  );

  late final TextPaint _levelPainter = TextPaint(
    style: AppTheme.koreanStyle(
      fontSize: 9,
      color: AppColors.starlightCream,
      fontWeight: FontWeight.bold,
    ),
  );

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    // 점프 모션
    final yOff = (math.sin(_t * 3) * 2).abs() * -1;

    // 그림자
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, h - 2),
        width: 26,
        height: 5,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );

    // 등급 색 후광
    canvas.drawCircle(
      Offset(w / 2, h - 22 + yOff),
      14,
      Paint()
        ..color = def.color.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // 이모지
    _emojiPainter.render(
      canvas,
      def.emoji,
      Vector2(w / 2, h - 22 + yOff),
      anchor: Anchor.center,
    );

    // 레벨 배지
    canvas.drawCircle(
      Offset(w - 6, h - 32),
      7,
      Paint()..color = def.color,
    );
    _levelPainter.render(
      canvas,
      '$level',
      Vector2(w - 6, h - 32),
      anchor: Anchor.center,
    );
  }
}
