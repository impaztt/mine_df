import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../../app/theme/app_colors.dart';

/// 광산 엔트리 (별이가 있는 본거지)
/// 화면 정중앙 하단. 적이 도달하는 목표 지점.
class MineComponent extends PositionComponent {
  MineComponent() : super(anchor: Anchor.bottomCenter);

  double _t = 0;

  @override
  Future<void> onLoad() async {
    size = Vector2(180, 110);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    // 광산 입구 (반원 아치)
    final archRect = Rect.fromLTWH(0, 20, w, h - 20);
    final archRRect = RRect.fromRectAndCorners(
      archRect,
      topLeft: const Radius.circular(60),
      topRight: const Radius.circular(60),
    );

    // 그림자
    canvas.drawRRect(
      archRRect.shift(const Offset(2, 4)),
      Paint()..color = const Color(0x66000000),
    );

    // 광산 외벽 (나무틀 느낌)
    canvas.drawRRect(
      archRRect,
      Paint()..color = const Color(0xFF6E4030),
    );
    canvas.drawRRect(
      archRRect.deflate(7),
      Paint()..color = const Color(0xFF1B1330),
    );

    // 광산 입구 안쪽 빛 (램프 글로우)
    final glowCenter = Offset(w / 2, h * 0.6);
    canvas.drawCircle(
      glowCenter,
      40 + math.sin(_t * 2) * 3,
      Paint()
        ..color = AppColors.minerDusk.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    canvas.drawCircle(
      glowCenter,
      18,
      Paint()..color = AppColors.starlightCream.withValues(alpha: 0.95),
    );

    // 나무 받침 (지지대)
    final beamPaint = Paint()..color = const Color(0xFF8B5A2B);
    canvas.drawRect(Rect.fromLTWH(0, h - 14, w, 14), beamPaint);
    canvas.drawRect(Rect.fromLTWH(-6, 14, 14, h - 14), beamPaint);
    canvas.drawRect(Rect.fromLTWH(w - 8, 14, 14, h - 14), beamPaint);

    // 간판 — 별 하나
    final star = Path();
    final cx = w / 2;
    const starR = 11.0;
    for (int i = 0; i < 5; i++) {
      final outer = -math.pi / 2 + i * 2 * math.pi / 5;
      final inner = outer + math.pi / 5;
      final ox = cx + math.cos(outer) * starR;
      final oy = 8 + math.sin(outer) * starR;
      final ix = cx + math.cos(inner) * starR / 2;
      final iy = 8 + math.sin(inner) * starR / 2;
      if (i == 0) {
        star.moveTo(ox, oy);
      } else {
        star.lineTo(ox, oy);
      }
      star.lineTo(ix, iy);
    }
    star.close();
    canvas.drawPath(
      star,
      Paint()..color = AppColors.gold,
    );
  }
}
