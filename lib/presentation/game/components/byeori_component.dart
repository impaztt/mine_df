import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors;

import '../../../app/theme/app_colors.dart';

/// 별이 (주인공) — 광산 위에서 곡괭이질하는 SD 캐릭터
class ByeoriComponent extends PositionComponent {
  ByeoriComponent() : super(size: Vector2(64, 80), anchor: Anchor.bottomCenter);

  double _swingT = 0;
  double _aimAngle = 0;

  /// 외부에서 곡괭이가 향할 각도를 설정 (라디안)
  void setAim(double angle) {
    _aimAngle = angle;
  }

  /// 발사 시 곡괭이를 휘두르는 짧은 애니메이션 트리거
  void swing() {
    _swingT = 0.25;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_swingT > 0) {
      _swingT = (_swingT - dt).clamp(0, 1);
    }
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    // 그림자
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, h - 4),
        width: 38,
        height: 8,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );

    // 다리 (멜빵바지)
    final legPaint = Paint()..color = const Color(0xFF3A4FB8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w / 2 - 12, h - 30, 10, 22),
        const Radius.circular(3),
      ),
      legPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w / 2 + 2, h - 30, 10, 22),
        const Radius.circular(3),
      ),
      legPaint,
    );

    // 몸 (멜빵 + 노란 셔츠)
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w / 2 - 16, h - 50, 32, 26),
      const Radius.circular(8),
    );
    canvas.drawRRect(bodyRect, Paint()..color = const Color(0xFF3A4FB8));
    // 멜빵 노란 패치
    canvas.drawRect(
      Rect.fromLTWH(w / 2 - 14, h - 48, 28, 8),
      Paint()..color = AppColors.gold,
    );

    // 머리 (피부톤)
    canvas.drawCircle(
      Offset(w / 2, h - 56),
      14,
      Paint()..color = const Color(0xFFFFE0B2),
    );

    // 눈
    final eyePaint = Paint()..color = Colors.black;
    canvas.drawCircle(Offset(w / 2 - 5, h - 57), 1.6, eyePaint);
    canvas.drawCircle(Offset(w / 2 + 5, h - 57), 1.6, eyePaint);
    // 입 (작은 미소)
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(w / 2, h - 52),
        width: 6,
        height: 4,
      ),
      0,
      math.pi,
      false,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // 광부 헬멧
    final helmetRect = Rect.fromCenter(
      center: Offset(w / 2, h - 64),
      width: 30,
      height: 20,
    );
    canvas.drawArc(
      helmetRect,
      math.pi,
      math.pi,
      true,
      Paint()..color = const Color(0xFFB85C3A),
    );
    canvas.drawRect(
      Rect.fromLTWH(w / 2 - 17, h - 56, 34, 4),
      Paint()..color = const Color(0xFF8B3A1E),
    );
    // 별 모양 램프
    _drawStar(
      canvas,
      Offset(w / 2, h - 68),
      4.5,
      AppColors.starlightCream,
    );
    canvas.drawCircle(
      Offset(w / 2, h - 68),
      8,
      Paint()
        ..color = AppColors.gold.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // 곡괭이 — 조준 방향 + swing 보정
    canvas.save();
    canvas.translate(w / 2 + 6, h - 36);
    final swingOffset = _swingT > 0 ? math.sin(_swingT * 12) * 0.6 : 0;
    canvas.rotate(_aimAngle + swingOffset);
    // 자루
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, -2, 30, 4),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF6B3A1F),
    );
    // 머리 (T자)
    canvas.drawRect(
      Rect.fromLTWH(26, -10, 8, 20),
      Paint()..color = const Color(0xFFB6B6C8),
    );
    canvas.drawRect(
      Rect.fromLTWH(26, -10, 3, 20),
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
