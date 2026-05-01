import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart'
    show Colors, LinearGradient, Alignment;

import '../../../app/theme/app_colors.dart';

/// 광맥 깊이별로 색상이 바뀌는 그라데이션 배경 + 떠다니는 별빛
class BackgroundComponent extends Component
    with HasGameReference {
  int layer;
  BackgroundComponent({required this.layer});

  final List<_Star> _stars = [];
  final math.Random _rng = math.Random(42);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    for (int i = 0; i < 36; i++) {
      _stars.add(_Star(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        size: 1 + _rng.nextDouble() * 2,
        phase: _rng.nextDouble() * math.pi * 2,
      ));
    }
  }

  double _t = 0;
  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    final size = game.size;
    final colors = AppColors.layerGradient(layer);

    // 배경 그라데이션
    final bgRect = Rect.fromLTWH(0, 0, size.x, size.y);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
      ).createShader(bgRect);
    canvas.drawRect(bgRect, paint);

    // 동굴 천장 — 진한 어둠 그라데이션
    final ceilingRect = Rect.fromLTWH(0, 0, size.x, size.y * 0.35);
    canvas.drawRect(
      ceilingRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1A1B3A).withValues(alpha: 0.6),
            const Color(0xFF1A1B3A).withValues(alpha: 0.0),
          ],
        ).createShader(ceilingRect),
    );

    // 별/광물 반짝임
    for (final s in _stars) {
      final x = s.x * size.x;
      final y = s.y * size.y * 0.5; // 위쪽에만
      final alpha = (math.sin(_t * 1.6 + s.phase) + 1) / 2;
      canvas.drawCircle(
        Offset(x, y),
        s.size,
        Paint()
          ..color = AppColors.starlightCream
              .withValues(alpha: 0.45 + alpha * 0.55),
      );
    }

    // 바닥 — 어두운 광산 흙
    final floorRect = Rect.fromLTWH(
        0, size.y * 0.78, size.x, size.y * 0.22);
    canvas.drawRect(
      floorRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors.last.withValues(alpha: 0.5),
            Colors.black.withValues(alpha: 0.7),
          ],
        ).createShader(floorRect),
    );

    // 적 이동 라인 (점선)
    final laneY = size.y * 0.66;
    final dotPaint = Paint()
      ..color = AppColors.starlightCream.withValues(alpha: 0.18)
      ..strokeWidth = 2;
    for (double x = 0; x < size.x; x += 14) {
      canvas.drawLine(
        Offset(x, laneY),
        Offset(x + 6, laneY),
        dotPaint,
      );
    }
  }
}

class _Star {
  final double x, y, size, phase;
  _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.phase,
  });
}
