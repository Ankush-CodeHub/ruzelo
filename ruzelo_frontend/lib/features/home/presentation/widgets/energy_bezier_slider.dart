import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Interactive cubic Bezier curve slider for real-time energy filtering
class EnergyBezierSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const EnergyBezierSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<EnergyBezierSlider> createState() => _EnergyBezierSliderState();
}

class _EnergyBezierSliderState extends State<EnergyBezierSlider> {
  String _getEnergyLabel(double val) {
    if (val < 0.25) return 'CHILL AMBIENT (0-25%)';
    if (val < 0.50) return 'MELLOW GROOVE (25-50%)';
    if (val < 0.75) return 'EUPHORIC FLOW (50-75%)';
    return 'OVERDRIVE PEAK (75-100%)';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('YOUR ENERGY', style: AppTypography.badgeLabel.copyWith(color: AppColors.textSecondary)),
            Text(
              _getEnergyLabel(widget.value),
              style: AppTypography.badgeLabel.copyWith(
                color: widget.value > 0.75 ? AppColors.accentNeon : AppColors.secondaryNeon,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 60,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onPanDown: (details) => _updateValue(details.localPosition.dx, constraints.maxWidth),
                onPanUpdate: (details) => _updateValue(details.localPosition.dx, constraints.maxWidth),
                child: CustomPaint(
                  size: Size(constraints.maxWidth, 60),
                  painter: _BezierWavePainter(
                    value: widget.value,
                    primaryColor: AppColors.primaryNeon,
                    accentColor: AppColors.secondaryNeon,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _updateValue(double localX, double width) {
    final newValue = (localX / width).clamp(0.0, 1.0);
    HapticFeedback.selectionClick();
    widget.onChanged(newValue);
  }
}

class _BezierWavePainter extends CustomPainter {
  final double value;
  final Color primaryColor;
  final Color accentColor;

  _BezierWavePainter({
    required this.value,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final midY = h * 0.5;

    // Background track curve
    final trackPath = Path();
    trackPath.moveTo(0, midY);
    for (double x = 0; x <= w; x += 10) {
      final y = midY + sin((x / w) * 2 * pi) * 12;
      trackPath.lineTo(x, y);
    }

    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(trackPath, trackPaint);

    // Active illuminated curve up to `value`
    final activeWidth = w * value;
    final activePath = Path();
    activePath.moveTo(0, midY);
    for (double x = 0; x <= activeWidth; x += 5) {
      final y = midY + sin((x / w) * 2 * pi) * 12;
      activePath.lineTo(x, y);
    }

    final activeGradient = LinearGradient(
      colors: [primaryColor, accentColor],
    );

    final activePaint = Paint()
      ..shader = activeGradient.createShader(Rect.fromLTWH(0, 0, activeWidth, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(activePath, activePaint);

    // Glowing Thumb Node on Bezier Curve
    final thumbX = activeWidth;
    final thumbY = midY + sin((thumbX / w) * 2 * pi) * 12;

    // Glow Shadow
    final glowPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset(thumbX, thumbY), 14, glowPaint);

    // Core Thumb
    final corePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(thumbX, thumbY), 7, corePaint);

    final rimPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(Offset(thumbX, thumbY), 7, rimPaint);
  }

  @override
  bool shouldRepaint(covariant _BezierWavePainter oldDelegate) {
    return oldDelegate.value != value;
  }
}
