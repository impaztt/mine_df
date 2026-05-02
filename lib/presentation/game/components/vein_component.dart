import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart' show Colors, FontWeight;

import '../../../app/theme/app_theme.dart';
import '../../../data/models/ore_type.dart';

/// 광맥 — 화면 가운데 위치한 큰 광석 덩어리.
///
/// 광부의 곡괭이질을 받아 흔들리고 반짝이며, 부서지지 않는다.
/// 현재 광석 등급(`mineRank`)에 따라 외형/색이 변한다.
class VeinComponent extends PositionComponent {
  VeinComponent({required OreDef ore})
      : _ore = ore,
        super(
          size: Vector2(180, 180),
          anchor: Anchor.center,
          priority: 50,
        );

  OreDef _ore;
  OreDef get ore => _ore;

  double _t = 0;
  double _shake = 0;
  double _shakePhase = 0;

  late TextPaint _emojiPainter;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _refreshPainter();
  }

  void _refreshPainter() {
    _emojiPainter = TextPaint(
      style: AppTheme.koreanStyle(
        fontSize: 78,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  void setOre(OreDef ore) {
    if (_ore.id == ore.id) return;
    _ore = ore;
    add(
      ScaleEffect.by(
        Vector2.all(1.18),
        EffectController(duration: 0.18, alternate: true),
      ),
    );
  }

  /// 곡괭이질을 받아 흔들리는 효과 트리거
  void onHit({bool isCritical = false}) {
    _shake = isCritical ? 0.55 : 0.32;
    _shakePhase = math.Random().nextDouble() * math.pi;
    if (isCritical) {
      add(
        ScaleEffect.by(
          Vector2.all(1.12),
          EffectController(duration: 0.12, alternate: true),
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_shake > 0) {
      _shake = (_shake - dt * 1.6).clamp(0, 1);
    }
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final cx = w / 2;
    final cy = h / 2;

    // 흔들림 오프셋
    final shakeX =
        _shake > 0 ? math.sin(_t * 60 + _shakePhase) * _shake * 8 : 0.0;
    final shakeY =
        _shake > 0 ? math.cos(_t * 60 + _shakePhase) * _shake * 4 : 0.0;

    canvas.save();
    canvas.translate(shakeX, shakeY);

    // 글로우 (다중 원으로 web 호환)
    for (int i = 4; i >= 1; i--) {
      canvas.drawCircle(
        Offset(cx, cy),
        65.0 + i * 10,
        Paint()..color = _ore.color.withValues(alpha: 0.10),
      );
    }

    // 메인 광석 형태 — 다각형 기반 보석 컷
    final path = Path();
    const sides = 8;
    final r = 70.0 + math.sin(_t * 1.2) * 2;
    for (int i = 0; i < sides; i++) {
      final a = (i / sides) * math.pi * 2 - math.pi / 2;
      final ratio = i.isEven ? 1.0 : 0.78;
      final x = cx + math.cos(a) * r * ratio;
      final y = cy + math.sin(a) * r * ratio;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // 본체
    canvas.drawPath(path, Paint()..color = _ore.color);

    // 면 디테일 (밝은/어두운 면)
    final lightPath = Path();
    for (int i = 0; i < sides; i += 2) {
      final a1 = (i / sides) * math.pi * 2 - math.pi / 2;
      final a2 = ((i + 1) / sides) * math.pi * 2 - math.pi / 2;
      lightPath.moveTo(cx, cy);
      lightPath.lineTo(cx + math.cos(a1) * r, cy + math.sin(a1) * r);
      lightPath.lineTo(cx + math.cos(a2) * r * 0.78,
          cy + math.sin(a2) * r * 0.78);
      lightPath.close();
    }
    canvas.drawPath(
      lightPath,
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );

    // 외곽선
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // 작은 반짝이 (시간에 따라 위치 변경)
    final sparkA = _t * 0.7;
    final sx = cx + math.cos(sparkA) * 32;
    final sy = cy + math.sin(sparkA * 1.3) * 24;
    canvas.drawCircle(
      Offset(sx, sy),
      3.5,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );

    // 가운데 작은 이모지 (광석 식별용)
    _emojiPainter.render(
      canvas,
      _ore.emoji,
      Vector2(cx, cy),
      anchor: Anchor.center,
    );

    canvas.restore();
  }
}
