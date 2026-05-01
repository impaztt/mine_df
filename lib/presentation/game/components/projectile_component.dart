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
  }) : super(
          size: Vector2.all(28),
          anchor: Anchor.center,
          priority: 1000,
        );

  final OreDef ore;
  final EnemyComponent target;
  final double damage;
  final double speed;

  double _spin = 0;
  double _life = 0;

  /// 트레일을 위한 이전 위치 기록
  final List<Vector2> _trail = [];
  static const int _trailMax = 6;

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

    // 트레일 기록 (월드 좌표 기준 — 컴포넌트 중심)
    _trail.insert(0, position.clone());
    if (_trail.length > _trailMax) {
      _trail.removeLast();
    }
  }

  @override
  void render(Canvas canvas) {
    // === 트레일 (월드 좌표 → 로컬 좌표 보정) ===
    // PositionComponent는 render 시 canvas 원점이 컴포넌트의 좌상단.
    // 트레일은 월드 좌표이므로 현재 컴포넌트의 (월드)좌상단 만큼 빼서 그린다.
    final originWorld = position - Vector2(size.x / 2, size.y / 2);
    for (int i = 0; i < _trail.length; i++) {
      final t = (1 - i / _trailMax);
      final p = _trail[i] - originWorld;
      canvas.drawCircle(
        Offset(p.x, p.y),
        4 + t * 4,
        Paint()..color = ore.color.withValues(alpha: t * 0.55),
      );
    }

    // === 발사체 본체 ===
    canvas.translate(size.x / 2, size.y / 2);

    // 외부 글로우 (블러 없이 큰 반투명 원으로 대체 — web 호환)
    for (int i = 3; i >= 1; i--) {
      canvas.drawCircle(
        Offset.zero,
        4.0 + i * 2.5,
        Paint()..color = ore.color.withValues(alpha: 0.18),
      );
    }

    canvas.save();
    canvas.rotate(_spin);

    // 광물 다각형 (보석 모양) — 외곽선 + 채움
    final path = Path();
    const sides = 6;
    const r = 8.0;
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
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // 하이라이트 (좌상단 점)
    canvas.drawCircle(
      const Offset(-2.5, -2.5),
      2.2,
      Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.95),
    );

    canvas.restore();
  }
}
