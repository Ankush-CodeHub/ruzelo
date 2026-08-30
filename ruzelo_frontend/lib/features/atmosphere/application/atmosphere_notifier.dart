import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/dynamic_theme_controller.dart';
import '../domain/atmosphere_model.dart';

class AtmosphereState {
  final AtmosphereModel currentAtmosphere;
  final double userEnergyLevel; // 0.0 to 1.0 (Calm / Chill -> High Intensity / Euphoric)
  final String timeOfDayContext;
  final List<AtmosphereModel> availableAtmospheres;
  final bool isLoading;

  const AtmosphereState({
    required this.currentAtmosphere,
    this.userEnergyLevel = 0.70,
    this.timeOfDayContext = 'Midnight Groove',
    this.availableAtmospheres = AtmosphereModel.defaultAtmospheres,
    this.isLoading = false,
  });

  AtmosphereState copyWith({
    AtmosphereModel? currentAtmosphere,
    double? userEnergyLevel,
    String? timeOfDayContext,
    List<AtmosphereModel>? availableAtmospheres,
    bool? isLoading,
  }) {
    return AtmosphereState(
      currentAtmosphere: currentAtmosphere ?? this.currentAtmosphere,
      userEnergyLevel: userEnergyLevel ?? this.userEnergyLevel,
      timeOfDayContext: timeOfDayContext ?? this.timeOfDayContext,
      availableAtmospheres: availableAtmospheres ?? this.availableAtmospheres,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AtmosphereNotifier extends StateNotifier<AtmosphereState> {
  final Ref _ref;

  AtmosphereNotifier(this._ref)
      : super(AtmosphereState(
          currentAtmosphere: AtmosphereModel.defaultAtmospheres.first,
          timeOfDayContext: _calculateTimeOfDay(),
        ));

  static String _calculateTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Morning Resonance';
    if (hour >= 12 && hour < 17) return 'Afternoon Flow';
    if (hour >= 17 && hour < 21) return 'Golden Hour Drift';
    return 'Midnight Groove';
  }

  void selectAtmosphere(AtmosphereModel atmosphere) {
    state = state.copyWith(currentAtmosphere: atmosphere);
    _ref.read(dynamicThemeControllerProvider.notifier).setCustomColors(
          primary: atmosphere.primaryColor,
          secondary: atmosphere.secondaryColor,
          accent: atmosphere.accentColor,
        );
  }

  void setEnergyLevel(double energy) {
    state = state.copyWith(userEnergyLevel: energy.clamp(0.0, 1.0));
  }
}

final atmosphereNotifierProvider =
    StateNotifierProvider<AtmosphereNotifier, AtmosphereState>((ref) {
  return AtmosphereNotifier(ref);
});
