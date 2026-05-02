import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart'
    show Colors, FontWeight, TextStyle;

/// 광맥에서 튀어나오는 작은 광석 파편
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

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(
      OpacityEffect.to(
        0,
        EffectController(duration: 0.7, startDelay: 0.4),
        onComplete: removeFromParent,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _spin += dt * 6;

    // 포물선 — 위로 튀었다 떨어짐
    final vx = math.cos(angle) * speed;
    final vy = math.sin(angle) * speed - 220; // 위쪽 초기 속도
    position.x += vx * dt;
    position.y += (vy + 700 * _t) * dt; // 중력 누적
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
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }
}

/// 크리티컬 시 화면에 표시되는 떠오르는 텍스트
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

  late TextPaint _painter;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _painter = TextPaint(
      style: TextStyle(
        fontSize: fontSize,
        color: color,
        fontWeight: FontWeight.w900,
      ),
    );
    add(
      OpacityEffect.to(
        0,
        EffectController(duration: 0.9),
        onComplete: removeFromParent,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y -= 50 * dt;
  }

  @override
  void render(Canvas canvas) {
    _painter.render(canvas, text, Vector2.zero(), anchor: Anchor.center);
  }
}
