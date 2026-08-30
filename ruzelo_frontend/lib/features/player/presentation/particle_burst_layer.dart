import 'dart:math';
import 'package:flutter/material.dart';

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  double radius;
  Color color;
  double alpha;
  double lifespan;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.color,
    this.alpha = 1.0,
    this.lifespan = 1.0,
  });

  bool update(double dt) {
    x += vx * dt;
    y += vy * dt;
    lifespan -= dt * 1.5;
    alpha = max(0.0, lifespan);
    return lifespan > 0;
  }
}

/// Interactive particle burst layer rendering luminous audio-reactive micro-particles
class ParticleBurstLayer extends StatefulWidget {
  final Widget child;
  final GlobalKey<ParticleBurstLayerState>? burstKey;

  const ParticleBurstLayer({
    super.key,
    required this.child,
    this.burstKey,
  });

  @override
  State<ParticleBurstLayer> createState() => ParticleBurstLayerState();
}

class ParticleBurstLayerState extends State<ParticleBurstLayer>
    with SingleTickerProviderStateMixin {
  final List<Particle> _particles = [];
  late final AnimationController _animController;
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updateParticles);
  }

  void spawnBurst(Offset position, {List<Color>? colors, int count = 28}) {
    final particleColors = colors ??
        const [
          Color(0xFF8B5CF6),
          Color(0xFF06B6D4),
          Color(0xFFEC4899),
          Color(0xFFF59E0B),
          Colors.white,
        ];

    for (int i = 0; i < count; i++) {
      final angle = _rand.nextDouble() * 2 * pi;
      final speed = 80.0 + _rand.nextDouble() * 220.0;
      _particles.add(
        Particle(
          x: position.dx,
          y: position.dy,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          radius: 2.0 + _rand.nextDouble() * 3.5,
          color: particleColors[_rand.nextInt(particleColors.length)],
        ),
      );
    }

    if (!_animController.isAnimating) {
      _animController.repeat();
    }
  }

  void _updateParticles() {
    if (_particles.isEmpty) {
      if (_animController.isAnimating) _animController.stop();
      return;
    }

    setState(() {
      const dt = 1.0 / 60.0;
      _particles.removeWhere((p) => !p.update(dt));
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _ParticlePainter(particles: _particles),
            ),
          ),
        ),
      ],
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  _ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withValues(alpha: p.alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.radius * 0.8);
      canvas.drawCircle(Offset(p.x, p.y), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
