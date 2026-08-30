import 'dart:math';
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Custom painter for light-reactive specular border edges with metallic refractive highlights
class SpecularBorderPainter extends CustomPainter {
  final double borderRadius;
  final double borderWidth;
  final double lightAngle;
  final Color primaryHighlight;
  final Color secondaryHighlight;
  final double intensity;

  SpecularBorderPainter({
    this.borderRadius = 24.0,
    this.borderWidth = 1.2,
    this.lightAngle = 0.75 * pi, // Top-left light source by default
    this.primaryHighlight = const Color(0x99FFFFFF),
    this.secondaryHighlight = const Color(0x15FFFFFF),
    this.intensity = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      borderWidth / 2,
      borderWidth / 2,
      size.width - borderWidth,
      size.height - borderWidth,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // Vector calculations for specular sweep gradient
    final startX = 0.5 + 0.5 * cos(lightAngle);
    final startY = 0.5 + 0.5 * sin(lightAngle);
    final endX = 0.5 + 0.5 * cos(lightAngle + pi);
    final endY = 0.5 + 0.5 * sin(lightAngle + pi);

    final gradient = LinearGradient(
      begin: Alignment(startX * 2 - 1, startY * 2 - 1),
      end: Alignment(endX * 2 - 1, endY * 2 - 1),
      colors: [
        primaryHighlight.withValues(alpha: (primaryHighlight.a * intensity).clamp(0.0, 1.0)),
        secondaryHighlight.withValues(alpha: (secondaryHighlight.a * intensity).clamp(0.0, 1.0)),
        Colors.white.withValues(alpha: 0.02 * intensity),
        secondaryHighlight.withValues(alpha: (secondaryHighlight.a * 0.6 * intensity).clamp(0.0, 1.0)),
      ],
      stops: const [0.0, 0.35, 0.7, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant SpecularBorderPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.lightAngle != lightAngle ||
        oldDelegate.primaryHighlight != primaryHighlight ||
        oldDelegate.secondaryHighlight != secondaryHighlight ||
        oldDelegate.intensity != intensity;
  }
}

/// Reusable SpecularBorder widget wrapping child with light-reactive refractive borders
class SpecularBorder extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double borderWidth;
  final double lightAngle;
  final double intensity;

  const SpecularBorder({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.borderWidth = 1.2,
    this.lightAngle = 0.75 * pi,
    this.intensity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: SpecularBorderPainter(
        borderRadius: borderRadius,
        borderWidth: borderWidth,
        lightAngle: lightAngle,
        intensity: intensity,
      ),
      child: child,
    );
  }
}
