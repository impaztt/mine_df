import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart' show Colors, TextStyle, FontWeight;

import '../../../app/theme/app_colors.dart';
import '../../../data/models/enemy_type.dart';
import '../starlit_mine_game.dart';

/// 적 컴포넌트 — 손님 / 침입자 / 보스 통합
class EnemyComponent extends PositionComponent
    with HasGameReference<StarlitMineGame> {
  EnemyComponent({
    required this.def,
    required this.maxHp,
    required this.fromLeft,
    required this.targetX,
    required this.speed,
  }) : super(size: Vector2.all(56), anchor: Anchor.center);

  final EnemyDef def;
  final double maxHp;
  final bool fromLeft;
  final double targetX;
  final double speed;

  late double hp = maxHp;
  bool isDead = false;
  bool reachedMine = false;
  double _bounce = 0;

  /// 충돌 반경 (발사체용)
  double get hitRadius =>
      def.kind == EnemyKind.boss ? 36 : 24;

  late final TextPaint _emojiPainter = TextPaint(
    style: TextStyle(
      fontSize: def.kind == EnemyKind.boss ? 56 : 36,
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
  );

  @override
  void update(double dt) {
    super.update(dt);
    if (isDead || reachedMine) return;
    _bounce += dt;

    // 광산 방향으로 이동
    final dir = (targetX - position.x).sign;
    position.x += dir * speed * dt;

    if ((position.x - targetX).abs() < 6) {
      reachedMine = true;
      game.onEnemyReachedMine(this);
      removeFromParent();
    }
  }

  void takeDamage(double dmg) {
    if (isDead) return;
    hp -= dmg;
    // 피격 흰 플래시
    add(
      ColorEffect(
        Colors.white,
        EffectController(duration: 0.08, alternate: true),
        opacityTo: 0.6,
      ),
    );
    if (hp <= 0) {
      isDead = true;
      game.onEnemyKilled(this);
      add(
        OpacityEffect.to(
          0,
          EffectController(duration: 0.25),
          onComplete: removeFromParent,
        ),
      );
    }
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    // 살짝 출렁이는 위아래
    final yOff = math.sin(_bounce * 6) * 2;

    // 오라 (손님 = 노란빛, 침입자 = 보랏빛, 보스 = 짙은 보랏빛)
    final auraColor = def.kind == EnemyKind.boss
        ? const Color(0xFFFF6B5C)
        : def.auraColor;
    canvas.drawCircle(
      Offset(w / 2, h / 2 + yOff),
      def.kind == EnemyKind.boss ? 38 : 24,
      Paint()
        ..color = auraColor.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // 머리 위 마커 — 손님은 ⭐, 침입자는 💀
    final markerY = h / 2 + yOff - (def.kind == EnemyKind.boss ? 36 : 26);
    final markerColor = def.kind == EnemyKind.customer
        ? AppColors.gold
        : (def.kind == EnemyKind.boss
            ? const Color(0xFFFF3030)
            : AppColors.intruderAura);
    if (def.kind == EnemyKind.customer) {
      _drawStar(canvas, Offset(w / 2, markerY), 6, markerColor);
    } else {
      canvas.drawCircle(
        Offset(w / 2, markerY),
        4,
        Paint()..color = markerColor,
      );
    }

    // 이모지 본체
    _emojiPainter.render(
      canvas,
      def.emoji,
      Vector2(w / 2, h / 2 + yOff),
      anchor: Anchor.center,
    );

    // HP 바
    if (def.kind == EnemyKind.boss || hp < maxHp) {
      final barW = def.kind == EnemyKind.boss ? 60.0 : 36.0;
      final barX = (w - barW) / 2;
      final barY = h - 6;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(barX, barY, barW, 5),
          const Radius.circular(2),
        ),
        Paint()..color = Colors.black.withValues(alpha: 0.5),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(barX, barY, barW * (hp / maxHp).clamp(0, 1), 5),
          const Radius.circular(2),
        ),
        Paint()
          ..color = def.kind == EnemyKind.customer
              ? AppColors.gold
              : Colors.redAccent,
      );
    }
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
