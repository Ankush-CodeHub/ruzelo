import 'dart:developer' as developer;
import 'dart:ui';

/// Asynchronous loader and cache manager for Flutter GLSL Fragment Programs
class ShaderProgramLoader {
  static const String atmosphereGlowAsset = 'assets/shaders/atmosphere_glow.frag';
  static const String liquidGlassAsset = 'assets/shaders/liquid_glass.frag';
  static const String atmosphereMeshAsset = 'assets/shaders/atmosphere_mesh.frag';

  static FragmentProgram? _atmosphereGlowProgram;
  static FragmentProgram? _liquidGlassProgram;
  static FragmentProgram? _atmosphereMeshProgram;

  static bool _isLoaded = false;
  static bool _hasError = false;

  static bool get isLoaded => _isLoaded;
  static bool get hasError => _hasError;

  /// Loads all GLSL shaders asynchronously on app initialization
  static Future<void> initializeShaders() async {
    try {
      final results = await Future.wait([
        _loadProgram(atmosphereGlowAsset),
        _loadProgram(liquidGlassAsset),
        _loadProgram(atmosphereMeshAsset),
      ]);
      _atmosphereGlowProgram = results[0];
      _liquidGlassProgram = results[1];
      _atmosphereMeshProgram = results[2];
      _isLoaded = true;
      developer.log('All GLSL Shaders initialized successfully.', name: 'ShaderProgramLoader');
    } catch (e, stackTrace) {
      _hasError = true;
      _isLoaded = true;
      developer.log(
        'Shader initialization warning (fallback canvas will be used): $e',
        name: 'ShaderProgramLoader',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<FragmentProgram?> _loadProgram(String asset) async {
    try {
      return await FragmentProgram.fromAsset(asset);
    } catch (e) {
      developer.log('Could not load shader asset $asset: $e', name: 'ShaderProgramLoader');
      return null;
    }
  }

  static FragmentShader? createAtmosphereGlowShader() {
    return _atmosphereGlowProgram?.fragmentShader();
  }

  static FragmentShader? createLiquidGlassShader() {
    return _liquidGlassProgram?.fragmentShader();
  }

  static FragmentShader? createAtmosphereMeshShader() {
    return _atmosphereMeshProgram?.fragmentShader();
  }
}
