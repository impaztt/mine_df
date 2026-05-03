import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../data/models/ore_type.dart';

/// 광석을 그래픽 보석으로 표현하는 작은 아이콘 위젯.
///
/// 이모지 대신 사용해서 모든 화면에서 일관된 보석 컷 모습을 보여준다.
/// 6면 컷 + 그라데이션 면 + 흰 외곽선 + 좌상단 하이라이트 점.
class OreGemIcon extends StatelessWidget {
  const OreGemIcon({
    super.key,
    required this.ore,
    this.size = 28,
  });

  final OreDef ore;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GemPainter(color: ore.color),
      ),
    );
  }
}

class _GemPainter extends CustomPainter {
  _GemPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(size.width, size.height) / 2 * 0.92;

    // 6면 보석 컷
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final a = i / 6 * math.pi * 2 - math.pi / 2;
      final x = cx + math.cos(a) * r;
      final y = cy + math.sin(a) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // 글로우 (외곽으로 약하게)
    canvas.drawCircle(
      Offset(cx, cy),
      r * 1.15,
      Paint()..color = color.withValues(alpha: 0.18),
    );

    // 본체 — 좌상단 밝게 우하단 어둡게 그라데이션
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          _lighten(color, 0.35),
          color,
          _darken(color, 0.20),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
      );
    canvas.drawPath(path, fill);

    // 내부 면 — 짝수 인덱스 슬라이스에 흰 베일 (반사면)
    final facetPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22);
    final facetPath = Path();
    for (int i = 0; i < 6; i += 2) {
      final a1 = i / 6 * math.pi * 2 - math.pi / 2;
      final a2 = (i + 1) / 6 * math.pi * 2 - math.pi / 2;
      facetPath.moveTo(cx, cy);
      facetPath.lineTo(cx + math.cos(a1) * r, cy + math.sin(a1) * r);
      facetPath.lineTo(
        cx + math.cos(a2) * r * 0.78,
        cy + math.sin(a2) * r * 0.78,
      );
      facetPath.close();
    }
    canvas.drawPath(facetPath, facetPaint);

    // 외곽선
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, size.width * 0.05),
    );

    // 좌상단 하이라이트
    canvas.drawCircle(
      Offset(cx - r * 0.32, cy - r * 0.32),
      r * 0.18,
      Paint()..color = Colors.white.withValues(alpha: 0.95),
    );
  }

  Color _lighten(Color c, double t) {
    return Color.fromARGB(
      255,
      ((c.r * 255).round() + ((255 - (c.r * 255).round()) * t)).round(),
      ((c.g * 255).round() + ((255 - (c.g * 255).round()) * t)).round(),
      ((c.b * 255).round() + ((255 - (c.b * 255).round()) * t)).round(),
    );
  }

  Color _darken(Color c, double t) {
    return Color.fromARGB(
      255,
      ((c.r * 255).round() * (1 - t)).round(),
      ((c.g * 255).round() * (1 - t)).round(),
      ((c.b * 255).round() * (1 - t)).round(),
    );
  }

  @override
  bool shouldRepaint(covariant _GemPainter old) => old.color != color;
}
