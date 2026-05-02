import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors, FontWeight;

import '../../../app/theme/app_theme.dart';

/// 광맥에서 튀어나오는 작은 광석 파편.
///
/// `OpacityEffect`는 `HasPaint` 컴포넌트가 필요해서 자체 `_alpha`
/// 변수로 페이드아웃을 처리한다.
class OreChip extends PositionComponent {
  OreChip({
    required Vector2 origin,
    required this.color,
    required this.angle,
    required this.speed,
  }) : super(
          position: origin,
          size: Vector2.all(10),
          anchor: Anchor.center,
          priority: 200,
        );

  final Color color;
  @override
  final double angle;
  final double speed;

  double _t = 0;
  double _spin = 0;
  double _alpha = 1.0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _spin += dt * 6;

    final vx = math.cos(angle) * speed;
    final vy = math.sin(angle) * speed - 220; // 위쪽 초기 속도
    position.x += vx * dt;
    position.y += (vy + 700 * _t) * dt; // 중력 누적

    // 0.4초 풀알파 → 그 후 0.7초 동안 페이드아웃
    if (_t > 0.4) {
      _alpha = (1 - (_t - 0.4) / 0.7).clamp(0.0, 1.0);
    }
    if (_t > 1.2) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(_spin);
    final path = Path();
    const r = 4.0;
    for (int i = 0; i < 5; i++) {
      final a = (i / 5) * math.pi * 2;
      final x = math.cos(a) * r;
      final y = math.sin(a) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()..color = color.withValues(alpha: _alpha),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.8 * _alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }
}

/// 떠오르며 사라지는 텍스트 (콤보 / 크리티컬 표기)
class FloatingText extends PositionComponent {
  FloatingText({
    required Vector2 origin,
    required this.text,
    required this.color,
    this.fontSize = 18,
  }) : super(
          position: origin,
          anchor: Anchor.center,
          priority: 1500,
        );

  final String text;
  final Color color;
  final double fontSize;

  double _alpha = 1.0;
  static const double _life = 0.9;
  double _t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    position.y -= 50 * dt;
    _alpha = (1 - _t / _life).clamp(0.0, 1.0);
    if (_t >= _life) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final painter = TextPaint(
      style: AppTheme.koreanStyle(
        fontSize: fontSize,
        color: color.withValues(alpha: _alpha),
        fontWeight: FontWeight.w900,
      ),
    );
    painter.render(canvas, text, Vector2.zero(), anchor: Anchor.center);
  }
}
