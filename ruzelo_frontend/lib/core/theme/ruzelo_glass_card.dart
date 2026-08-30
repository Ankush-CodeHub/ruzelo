import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'specular_border.dart';

/// Production glass card with BackdropFilter, specular light reflections, tactile spring feedback,
/// and RepaintBoundary isolation to prevent GPU overdraw.
class RuzeloGlassCard extends StatefulWidget {
  final Widget child;
  final double blur;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? fillColor;
  final Gradient? fillGradient;
  final Color? glowColor;
  final double glowRadius;
  final double borderWidth;
  final VoidCallback? onTap;
  final bool enableSpecular;

  const RuzeloGlassCard({
    super.key,
    required this.child,
    this.blur = 24.0,
    this.borderRadius = 24.0,
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
    this.fillColor,
    this.fillGradient,
    this.glowColor,
    this.glowRadius = 24.0,
    this.borderWidth = 1.2,
    this.onTap,
    this.enableSpecular = true,
  });

  @override
  State<RuzeloGlassCard> createState() => _RuzeloGlassCardState();
}

class _RuzeloGlassCardState extends State<RuzeloGlassCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveFill = widget.fillColor ?? AppColors.glassFill;
    final effectiveGradient = widget.fillGradient ??
        LinearGradient(
          colors: [
            effectiveFill,
            effectiveFill.withValues(alpha: (effectiveFill.a * 0.4).clamp(0.0, 1.0)),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

    Widget card = Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: widget.glowRadius,
            offset: const Offset(0, 10),
          ),
          if (widget.glowColor != null)
            BoxShadow(
              color: widget.glowColor!.withValues(alpha: 0.25),
              blurRadius: widget.glowRadius * 1.5,
              spreadRadius: -2,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              gradient: effectiveGradient,
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.enableSpecular) {
      card = SpecularBorder(
        borderRadius: widget.borderRadius,
        borderWidth: widget.borderWidth,
        child: card,
      );
    }

    // Isolate raster layer with RepaintBoundary for GPU cache optimization
    card = RepaintBoundary(child: card);

    if (widget.onTap != null) {
      return GestureDetector(
        onTapDown: (_) => _scaleController.forward(),
        onTapUp: (_) {
          _scaleController.reverse();
          widget.onTap!();
        },
        onTapCancel: () => _scaleController.reverse(),
        behavior: HitTestBehavior.opaque,
        child: ScaleTransition(scale: _scaleAnimation, child: card),
      );
    }

    return card;
  }
}
