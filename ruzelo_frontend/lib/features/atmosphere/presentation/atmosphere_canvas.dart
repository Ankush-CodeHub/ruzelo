import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/shaders/shader_program_loader.dart';
import '../../../core/theme/dynamic_theme_controller.dart';
import '../../player/application/player_notifier.dart';

/// Full-screen ambient atmospheric background driven by GLSL shaders with smooth fallback
class AtmosphereCanvas extends ConsumerStatefulWidget {
  final Widget? child;
  final double blurAmount;
  final bool enableAudioReactivity;

  const AtmosphereCanvas({
    super.key,
    this.child,
    this.blurAmount = 0.0,
    this.enableAudioReactivity = true,
  });

  @override
  ConsumerState<AtmosphereCanvas> createState() => _AtmosphereCanvasState();
}

class _AtmosphereCanvasState extends ConsumerState<AtmosphereCanvas>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _elapsedTime = 0.0;
  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    _initShader();
    _ticker = createTicker((elapsed) {
      setState(() {
        _elapsedTime = elapsed.inMicroseconds / 1000000.0;
      });
    })..start();
  }

  Future<void> _initShader() async {
    if (!ShaderProgramLoader.isLoaded) {
      await ShaderProgramLoader.initializeShaders();
    }
    if (mounted) {
      setState(() {
        _shader = ShaderProgramLoader.createAtmosphereMeshShader();
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(dynamicThemeControllerProvider);
    final audioEnergy = widget.enableAudioReactivity
        ? ref.watch(playerNotifierProvider.select((s) => s.audioEnergy))
        : 0.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(
            painter: _AtmosphereShaderPainter(
              shader: _shader,
              elapsedTime: _elapsedTime * palette.animationSpeed,
              audioEnergy: audioEnergy,
              colorA: palette.primary,
              colorB: palette.secondary,
              colorC: palette.accent,
            ),
          ),
        ),
        if (widget.blurAmount > 0)
          BackdropFilter(
            filter: ui.ImageFilter.blur(
              sigmaX: widget.blurAmount,
              sigmaY: widget.blurAmount,
            ),
            child: Container(color: Colors.transparent),
          ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _AtmosphereShaderPainter extends CustomPainter {
  final ui.FragmentShader? shader;
  final double elapsedTime;
  final double audioEnergy;
  final Color colorA;
  final Color colorB;
  final Color colorC;

  _AtmosphereShaderPainter({
    required this.shader,
    required this.elapsedTime,
    required this.audioEnergy,
    required this.colorA,
    required this.colorB,
    required this.colorC,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (shader != null) {
      // Set uniforms for GLSL shader:
      // uniform vec2 uResolution; (index 0, 1)
      // uniform float uTime; (index 2)
      // uniform float uAudioEnergy; (index 3)
      // uniform vec3 uColorA; (index 4, 5, 6)
      // uniform vec3 uColorB; (index 7, 8, 9)
      // uniform vec3 uColorC; (index 10, 11, 12)
      shader!.setFloat(0, size.width);
      shader!.setFloat(1, size.height);
      shader!.setFloat(2, elapsedTime);
      shader!.setFloat(3, audioEnergy);

      // Color A RGB (0..1)
      shader!.setFloat(4, colorA.r);
      shader!.setFloat(5, colorA.g);
      shader!.setFloat(6, colorA.b);

      // Color B RGB (0..1)
      shader!.setFloat(7, colorB.r);
      shader!.setFloat(8, colorB.g);
      shader!.setFloat(9, colorB.b);

      // Color C RGB (0..1)
      shader!.setFloat(10, colorC.r);
      shader!.setFloat(11, colorC.g);
      shader!.setFloat(12, colorC.b);

      final paint = Paint()..shader = shader;
      canvas.drawRect(Offset.zero & size, paint);
    } else {
      // Fallback fluid gradient canvas drawing
      final paint = Paint();
      final rect = Offset.zero & size;

      final gradient = RadialGradient(
        center: Alignment(
          0.3 * (1.0 + 0.5 * (audioEnergy)),
          -0.2 + (elapsedTime * 0.1).remainder(1.0) * 0.4,
        ),
        radius: 1.4,
        colors: [
          colorA.withValues(alpha: 0.85),
          colorB.withValues(alpha: 0.6),
          colorC.withValues(alpha: 0.4),
          const Color(0xFF0A0B10),
        ],
        stops: const [0.0, 0.45, 0.75, 1.0],
      );

      paint.shader = gradient.createShader(rect);
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AtmosphereShaderPainter oldDelegate) {
    return oldDelegate.elapsedTime != elapsedTime ||
        oldDelegate.audioEnergy != audioEnergy ||
        oldDelegate.colorA != colorA ||
        oldDelegate.colorB != colorB ||
        oldDelegate.colorC != colorC;
  }
}
