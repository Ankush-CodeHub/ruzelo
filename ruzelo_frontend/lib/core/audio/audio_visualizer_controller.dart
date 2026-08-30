import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AudioWaveformState {
  final List<double> bands;
  final double currentAmplitude;
  final bool isActive;

  const AudioWaveformState({
    this.bands = const [0.1, 0.2, 0.3, 0.4, 0.3, 0.2, 0.1, 0.2, 0.3, 0.5, 0.3, 0.2],
    this.currentAmplitude = 0.3,
    this.isActive = false,
  });
}

class AudioVisualizerController extends StateNotifier<AudioWaveformState> {
  Timer? _animTimer;
  final Random _rand = Random();

  AudioVisualizerController() : super(const AudioWaveformState()) {
    _startTicker();
  }

  void _startTicker() {
    _animTimer = Timer.periodic(const Duration(milliseconds: 60), (_) {
      if (!state.isActive) return;

      final count = 16;
      final newBands = List<double>.generate(count, (i) {
        final base = sin(i * 0.4 + DateTime.now().millisecondsSinceEpoch * 0.005).abs();
        final jitter = (_rand.nextDouble() - 0.5) * 0.35;
        return (base * 0.7 + jitter + 0.15).clamp(0.08, 1.0);
      });

      final avg = newBands.reduce((a, b) => a + b) / count;
      state = AudioWaveformState(
        bands: newBands,
        currentAmplitude: avg,
        isActive: state.isActive,
      );
    });
  }

  void setActive(bool active) {
    state = AudioWaveformState(
      bands: active ? state.bands : List.filled(16, 0.05),
      currentAmplitude: active ? state.currentAmplitude : 0.05,
      isActive: active,
    );
  }

  @override
  void dispose() {
    _animTimer?.cancel();
    super.dispose();
  }
}

final audioVisualizerControllerProvider =
    StateNotifierProvider<AudioVisualizerController, AudioWaveformState>((ref) {
  return AudioVisualizerController();
});
