import 'dart:math';

import 'package:flutter/material.dart';

class Confetti extends StatefulWidget {
  const Confetti({super.key});

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _Particle {
  final double x;
  final double delay;
  final double speed;
  final double size;
  final double drift;
  final Color color;
  _Particle(this.x, this.delay, this.speed, this.size, this.drift, this.color);
}

class _ConfettiState extends State<Confetti>
    with SingleTickerProviderStateMixin {
  static const _colors = [
    Color(0xFFE53935),
    Color(0xFFFFB300),
    Color(0xFF43A047),
    Color(0xFF1E88E5),
    Color(0xFF8E24AA),
    Color(0xFFFF7043),
  ];

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..forward();

  late final List<_Particle> _particles = () {
    final r = Random();
    return List.generate(
      70,
      (_) => _Particle(
        r.nextDouble(),
        r.nextDouble() * 0.4,
        0.6 + r.nextDouble() * 0.6,
        6 + r.nextDouble() * 6,
        (r.nextDouble() - 0.5) * 0.2,
        _colors[r.nextInt(_colors.length)],
      ),
    );
  }();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_particles, _c.value),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  _ConfettiPainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = ((progress - p.delay) / (1 - p.delay)).clamp(0.0, 1.0).toDouble();
      if (t <= 0) continue;
      final y = -20 + t * p.speed * (size.height + 40);
      final x = (p.x + p.drift * t) * size.width;
      final paint = Paint()
        ..color = p.color.withAlpha((255 * (1 - t * t)).round());
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * 10);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
