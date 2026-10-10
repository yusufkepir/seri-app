import 'dart:math';

import 'package:flutter/material.dart';

class Ring extends StatelessWidget {
  final double progress;
  final double size;
  final double stroke;
  final Color color;
  final Widget? child;

  const Ring({
    super.key,
    required this.progress,
    required this.size,
    required this.color,
    this.stroke = 10,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress.clamp(0.0, 1.0).toDouble(),
              color,
              stroke,
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double stroke;
  _RingPainter(this.progress, this.color, this.stroke);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = color.withAlpha(40);
    canvas.drawArc(rect, 0, 2 * pi, false, track);
    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false, fg);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.stroke != stroke;
}
