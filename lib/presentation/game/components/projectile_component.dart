import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../../data/models/ore_type.dart';
import 'enemy_component.dart';

/// 광물 발사체 — 적을 추적해서 충돌 시 데미지
class ProjectileComponent extends PositionComponent {
  ProjectileComponent({
    required super.position,
    required this.ore,
    required this.target,
    required this.damage,
    required this.speed,
  }) : super(size: Vector2.all(16), anchor: Anchor.center);

  final OreDef ore;
  final EnemyComponent target;
  final double damage;
  final double speed;

  double _spin = 0;
  double _life = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _spin += dt * 8;
    _life += dt;

    // 추적
    if (target.isMounted && !target.isDead) {
      final dir = (target.absolutePosition - absolutePosition);
      if (dir.length > 1) {
        final norm = dir.normalized();
        position += norm * speed * dt;
      }

      // 충돌 체크 (간단 거리 기반)
      if ((target.absolutePosition - absolutePosition).length <
          target.hitRadius + 10) {
        target.takeDamage(damage);
        removeFromParent();
        return;
      }
    } else {
      // 타겟이 사라지면 직진하다 자가 제거
      if (_life > 1.5) {
        removeFromParent();
        return;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(_spin);

    // 발광 트레일
    canvas.drawCircle(
      Offset.zero,
      11,
      Paint()
        ..color = ore.color.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // 광물 다각형 (보석 모양)
    final path = Path();
    const sides = 6;
    const r = 7.0;
    for (int i = 0; i < sides; i++) {
      final a = (i / sides) * math.pi * 2;
      final x = math.cos(a) * r;
      final y = math.sin(a) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = ore.color);

    // 하이라이트
    canvas.drawCircle(
      const Offset(-2, -2),
      2,
      Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.8),
    );
  }
}
