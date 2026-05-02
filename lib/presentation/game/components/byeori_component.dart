import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors;

import '../../../app/theme/app_colors.dart';

/// 별이 — 광맥 옆에서 곡괭이질하는 SD 캐릭터.
class ByeoriComponent extends PositionComponent {
  ByeoriComponent()
      : super(size: Vector2(72, 92), anchor: Anchor.bottomCenter);

  /// 곡괭이가 광맥 쪽을 향하는 각도 (0 = 위쪽 향함)
  double aimAngle = -math.pi / 4;

  /// 곡괭이질 진행도 (0 = 정지, >0 = swing 진행)
  double _swingT = 0;

  /// 광부가 가운데를 보고 있을 때 약간 좌우로 출렁이는 호흡 모션
  double _breathT = 0;

  /// 외부 호출 — 곡괭이질 모션 트리거
  void swing() {
    _swingT = 1.0; // 1.0초 동안 swing 애니메이션
  }

  @override
  void update(double dt) {
    super.update(dt);
    _breathT += dt;
    if (_swingT > 0) {
      _swingT = (_swingT - dt * 4).clamp(0.0, 1.0);
    }
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    final breathOff = math.sin(_breathT * 2.4) * 1.5;

    // 그림자
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, h - 4),
        width: 42,
        height: 9,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );

    // 다리
    final legPaint = Paint()..color = const Color(0xFF3A4FB8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w / 2 - 13, h - 32, 11, 24),
        const Radius.circular(3),
      ),
      legPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w / 2 + 2, h - 32, 11, 24),
        const Radius.circular(3),
      ),
      legPaint,
    );

    // 몸
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w / 2 - 18, h - 56 + breathOff, 36, 28),
      const Radius.circular(9),
    );
    canvas.drawRRect(bodyRect, Paint()..color = const Color(0xFF3A4FB8));
    canvas.drawRect(
      Rect.fromLTWH(w / 2 - 16, h - 53 + breathOff, 32, 9),
      Paint()..color = AppColors.gold,
    );

    // 머리
    canvas.drawCircle(
      Offset(w / 2, h - 64 + breathOff),
      15,
      Paint()..color = const Color(0xFFFFE0B2),
    );

    // 눈
    final eyePaint = Paint()..color = Colors.black;
    canvas.drawCircle(
      Offset(w / 2 - 5, h - 65 + breathOff),
      1.8,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(w / 2 + 5, h - 65 + breathOff),
      1.8,
      eyePaint,
    );

    // 입
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(w / 2, h - 60 + breathOff),
        width: 6.5,
        height: 4,
      ),
      0,
      math.pi,
      false,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // 헬멧
    final helmetRect = Rect.fromCenter(
      center: Offset(w / 2, h - 73 + breathOff),
      width: 32,
      height: 22,
    );
    canvas.drawArc(
      helmetRect,
      math.pi,
      math.pi,
      true,
      Paint()..color = const Color(0xFFB85C3A),
    );
    canvas.drawRect(
      Rect.fromLTWH(w / 2 - 18, h - 64 + breathOff, 36, 4),
      Paint()..color = const Color(0xFF8B3A1E),
    );

    // 별 모양 램프
    _drawStar(
      canvas,
      Offset(w / 2, h - 78 + breathOff),
      5,
      AppColors.starlightCream,
    );
    // 램프 후광 (블러 없이 다중 원)
    for (int i = 3; i >= 1; i--) {
      canvas.drawCircle(
        Offset(w / 2, h - 78 + breathOff),
        4.0 + i * 3,
        Paint()..color = AppColors.gold.withValues(alpha: 0.10),
      );
    }

    // === 곡괭이 ===
    canvas.save();
    canvas.translate(w / 2 + 8, h - 40 + breathOff);

    // swing 애니메이션 — _swingT가 1.0에서 0으로 줄어듦. 그동안 -π/3 → +π/4 회전
    final swingProg = 1 - _swingT; // 0 → 1
    final swingDelta =
        _swingT > 0 ? -math.pi / 3 + swingProg * (math.pi / 3 + math.pi / 4) : 0;
    canvas.rotate(aimAngle + swingDelta);

    // 자루
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, -2, 32, 4),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF6B3A1F),
    );
    // 머리 (T자)
    canvas.drawRect(
      Rect.fromLTWH(28, -11, 10, 22),
      Paint()..color = const Color(0xFFB6B6C8),
    );
    canvas.drawRect(
      Rect.fromLTWH(28, -11, 4, 22),
      Paint()..color = const Color(0xFFE8F4FF),
    );
    canvas.restore();
  }

  void _drawStar(Canvas canvas, Offset c, double r, Color color) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final outer = -math.pi / 2 + i * 2 * math.pi / 5;
      final inner = outer + math.pi / 5;
      final ox = c.dx + math.cos(outer) * r;
      final oy = c.dy + math.sin(outer) * r;
      final ix = c.dx + math.cos(inner) * r * 0.5;
      final iy = c.dy + math.sin(inner) * r * 0.5;
      if (i == 0) {
        path.moveTo(ox, oy);
      } else {
        path.lineTo(ox, oy);
      }
      path.lineTo(ix, iy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }
}
