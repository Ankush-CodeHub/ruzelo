import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shaders/shader_program_loader.dart';
import 'dynamic_theme_controller.dart';
import '../../features/player/application/player_notifier.dart';

enum AtmosphereEffectStyle {
  meshGlow,
  liquidGlass,
}

/// Dynamic atmospheric background driven by Flutter GLSL fragment shaders with automatic fallback
class RuzeloAtmosphereBackground extends ConsumerStatefulWidget {
  final Widget? child;
  final double blurAmount;
  final bool enableAudioReactivity;
  final AtmosphereEffectStyle effectStyle;

  const RuzeloAtmosphereBackground({
    super.key,
    this.child,
    this.blurAmount = 0.0,
    this.enableAudioReactivity = true,
    this.effectStyle = AtmosphereEffectStyle.meshGlow,
  });

  @override
  ConsumerState<RuzeloAtmosphereBackground> createState() => _RuzeloAtmosphereBackgroundState();
}

class _RuzeloAtmosphereBackgroundState extends ConsumerState<RuzeloAtmosphereBackground>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _elapsedTime = 0.0;
  ui.FragmentShader? _glowShader;
  ui.FragmentShader? _liquidShader;

  @override
  void initState() {
    super.initState();
    _initShaders();
    _ticker = createTicker((elapsed) {
      if (mounted) {
        setState(() {
          _elapsedTime = elapsed.inMicroseconds / 1000000.0;
        });
      }
    })..start();
  }

  Future<void> _initShaders() async {
    if (!ShaderProgramLoader.isLoaded) {
      await ShaderProgramLoader.initializeShaders();
    }
    if (mounted) {
      setState(() {
        _glowShader = ShaderProgramLoader.createAtmosphereGlowShader() ??
            ShaderProgramLoader.createAtmosphereMeshShader();
        _liquidShader = ShaderProgramLoader.createLiquidGlassShader();
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _glowShader?.dispose();
    _liquidShader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(dynamicThemeControllerProvider);
    final audioEnergy = widget.enableAudioReactivity
        ? ref.watch(playerNotifierProvider.select((s) => s.audioEnergy))
        : 0.0;

    final activeShader = widget.effectStyle == AtmosphereEffectStyle.liquidGlass
        ? _liquidShader
        : _glowShader;

    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(
            painter: _AtmosphereShaderCustomPainter(
              shader: activeShader,
              effectStyle: widget.effectStyle,
              elapsedTime: _elapsedTime * palette.animationSpeed,
              audioEnergy: audioEnergy,
              colorA: palette.primary,
              colorB: palette.secondary,
              colorC: palette.accent,
              colorD: palette.deepGlow,
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

class _AtmosphereShaderCustomPainter extends CustomPainter {
  final ui.FragmentShader? shader;
  final AtmosphereEffectStyle effectStyle;
  final double elapsedTime;
  final double audioEnergy;
  final Color colorA;
  final Color colorB;
  final Color colorC;
  final Color colorD;

  _AtmosphereShaderCustomPainter({
    required this.shader,
    required this.effectStyle,
    required this.elapsedTime,
    required this.audioEnergy,
    required this.colorA,
    required this.colorB,
    required this.colorC,
    required this.colorD,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (shader != null) {
      if (effectStyle == AtmosphereEffectStyle.liquidGlass) {
        // liquid_glass.frag uniforms:
        // uResolution (0,1), uTime (2), uAudioEnergy (3), uGlassTint (4,5,6), uRefractionIndex (7)
        shader!.setFloat(0, size.width);
        shader!.setFloat(1, size.height);
        shader!.setFloat(2, elapsedTime);
        shader!.setFloat(3, audioEnergy);
        shader!.setFloat(4, colorA.r);
        shader!.setFloat(5, colorA.g);
        shader!.setFloat(6, colorA.b);
        shader!.setFloat(7, 1.2);
      } else {
        // atmosphere_glow.frag uniforms:
        // uResolution (0,1), uTime (2), uAudioEnergy (3)
        // uColorA (4,5,6), uColorB (7,8,9), uColorC (10,11,12), uColorD (13,14,15)
        shader!.setFloat(0, size.width);
        shader!.setFloat(1, size.height);
        shader!.setFloat(2, elapsedTime);
        shader!.setFloat(3, audioEnergy);

        shader!.setFloat(4, colorA.r);
        shader!.setFloat(5, colorA.g);
        shader!.setFloat(6, colorA.b);

        shader!.setFloat(7, colorB.r);
        shader!.setFloat(8, colorB.g);
        shader!.setFloat(9, colorB.b);

        shader!.setFloat(10, colorC.r);
        shader!.setFloat(11, colorC.g);
        shader!.setFloat(12, colorC.b);

        shader!.setFloat(13, colorD.r);
        shader!.setFloat(14, colorD.g);
        shader!.setFloat(15, colorD.b);
      }

      final paint = Paint()..shader = shader;
      canvas.drawRect(Offset.zero & size, paint);
    } else {
      // Fluid multi-radial canvas fallback
      final rect = Offset.zero & size;
      final paint = Paint();

      final gradient = RadialGradient(
        center: Alignment(
          0.35 * (1.0 + 0.3 * audioEnergy),
          -0.3 + (elapsedTime * 0.08).remainder(1.0) * 0.5,
        ),
        radius: 1.5,
        colors: [
          colorA.withValues(alpha: 0.8),
          colorB.withValues(alpha: 0.55),
          colorC.withValues(alpha: 0.35),
          colorD.withValues(alpha: 0.95),
        ],
        stops: const [0.0, 0.4, 0.7, 1.0],
      );

      paint.shader = gradient.createShader(rect);
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AtmosphereShaderCustomPainter oldDelegate) {
    return oldDelegate.elapsedTime != elapsedTime ||
        oldDelegate.audioEnergy != audioEnergy ||
        oldDelegate.colorA != colorA ||
        oldDelegate.colorB != colorB ||
        oldDelegate.colorC != colorC ||
        oldDelegate.colorD != colorD;
  }
}
