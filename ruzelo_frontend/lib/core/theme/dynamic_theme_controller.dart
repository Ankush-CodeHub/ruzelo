import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import 'app_colors.dart';

/// Dynamic theme palette for real-time atmosphere and lighting adaptation
class AtmospherePalette {
  final String id;
  final String name;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color deepGlow;
  final double animationSpeed;
  final double noiseScale;
  final double audioEnergyFactor;

  const AtmospherePalette({
    required this.id,
    required this.name,
    required this.primary,
    required this.secondary,
    required this.accent,
    this.deepGlow = const Color(0xFF0A0B10),
    this.animationSpeed = 1.0,
    this.noiseScale = 1.0,
    this.audioEnergyFactor = 1.0,
  });

  /// Luminance-aware foreground text color ensuring readability
  Color get onPrimaryColor {
    return primary.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }

  /// Contrast-safe accent with elevated saturation
  Color get dynamicGlowAccent {
    final hsl = HSLColor.fromColor(accent);
    return hsl.withLightness((hsl.lightness + 0.15).clamp(0.0, 0.9)).toColor();
  }

  static const AtmospherePalette saffronDusk = AtmospherePalette(
    id: 'saffron_dusk',
    name: 'Saffron Dusk',
    primary: Color(0xFFF59E0B),    // Warm Turmeric Gold
    secondary: Color(0xFFEA580C),  // Royal Saffron
    accent: Color(0xFFE11D48),     // Sunset Crimson
    deepGlow: Color(0xFF2E1005),
    animationSpeed: 0.9,
    noiseScale: 1.1,
    audioEnergyFactor: 1.2,
  );

  static const AtmospherePalette gangesMystic = AtmospherePalette(
    id: 'ganges_mystic',
    name: 'Ganges Mystic',
    primary: Color(0xFF0284C7),    // Celestial River Blue
    secondary: Color(0xFF6366F1),  // Temple Incense Violet
    accent: Color(0xFF14B8A6),     // Nocturnal Teal
    deepGlow: Color(0xFF061528),
    animationSpeed: 0.7,
    noiseScale: 0.9,
    audioEnergyFactor: 0.9,
  );

  static const AtmospherePalette jaipurRose = AtmospherePalette(
    id: 'jaipur_rose',
    name: 'Jaipur Rose',
    primary: Color(0xFFE11D48),    // Royal Rajasthani Rose
    secondary: Color(0xFFD97706),  // Desert Amber
    accent: Color(0xFF9333EA),     // Ruby Magenta
    deepGlow: Color(0xFF260515),
    animationSpeed: 1.0,
    noiseScale: 1.2,
    audioEnergyFactor: 1.1,
  );

  static const AtmospherePalette marigoldDawn = AtmospherePalette(
    id: 'marigold_dawn',
    name: 'Marigold Dawn',
    primary: Color(0xFFF97316),    // Festive Marigold Orange
    secondary: Color(0xFFEAB308),  // Sunlit Amber
    accent: Color(0xFF10B981),     // Emerald Leaf
    deepGlow: Color(0xFF241003),
    animationSpeed: 1.1,
    noiseScale: 1.0,
    audioEnergyFactor: 1.3,
  );

  static const AtmospherePalette cyberAura = AtmospherePalette(
    id: 'cyber_aura',
    name: 'Cyber Aura',
    primary: Color(0xFF8B5CF6),    // Electric Violet
    secondary: Color(0xFF06B6D4),  // Cyber Cyan
    accent: Color(0xFFEC4899),     // Velvet Magenta
    deepGlow: Color(0xFF1E1B4B),
    animationSpeed: 1.2,
    noiseScale: 1.1,
    audioEnergyFactor: 1.3,
  );

  static const AtmospherePalette midnightVelvet = AtmospherePalette(
    id: 'midnight_velvet',
    name: 'Midnight Velvet',
    primary: Color(0xFF312E81),    // Deep Indigo
    secondary: Color(0xFF1E1B4B),  // Midnight Navy
    accent: Color(0xFF7C3AED),     // Royal Violet
    deepGlow: Color(0xFF0B0C16),
    animationSpeed: 0.8,
    noiseScale: 0.9,
    audioEnergyFactor: 0.9,
  );

  static const List<AtmospherePalette> allPresets = [
    saffronDusk,
    gangesMystic,
    jaipurRose,
    marigoldDawn,
    cyberAura,
    midnightVelvet,
  ];

  AtmospherePalette copyWith({
    String? id,
    String? name,
    Color? primary,
    Color? secondary,
    Color? accent,
    Color? deepGlow,
    double? animationSpeed,
    double? noiseScale,
    double? audioEnergyFactor,
  }) {
    return AtmospherePalette(
      id: id ?? this.id,
      name: name ?? this.name,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      deepGlow: deepGlow ?? this.deepGlow,
      animationSpeed: animationSpeed ?? this.animationSpeed,
      noiseScale: noiseScale ?? this.noiseScale,
      audioEnergyFactor: audioEnergyFactor ?? this.audioEnergyFactor,
    );
  }
}

class DynamicThemeController extends StateNotifier<AtmospherePalette> {
  DynamicThemeController() : super(AtmospherePalette.saffronDusk);

  void setPalette(AtmospherePalette palette) {
    state = palette;
  }

  /// Extracts dominant and vibrant colors from an album art image provider using palette_generator
  Future<void> extractFromImage(ImageProvider imageProvider) async {
    try {
      final generator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        size: const Size(128, 128),
        maximumColorCount: 16,
      );

      final vibrant = generator.vibrantColor?.color ?? generator.dominantColor?.color ?? state.primary;
      final lightVibrant = generator.lightVibrantColor?.color ?? generator.mutedColor?.color ?? state.secondary;
      final darkVibrant = generator.darkVibrantColor?.color ?? generator.darkMutedColor?.color ?? state.accent;

      state = state.copyWith(
        name: 'Extracted Mood',
        primary: vibrant,
        secondary: lightVibrant,
        accent: darkVibrant,
      );
    } catch (_) {}
  }

  void setCustomColors({
    required Color primary,
    required Color secondary,
    required Color accent,
  }) {
    state = state.copyWith(
      primary: primary,
      secondary: secondary,
      accent: accent,
    );
  }

  void updateFromGenre(String genre) {
    final g = genre.toLowerCase();
    if (g.contains('bollywood') || g.contains('romance')) {
      state = AtmospherePalette.saffronDusk;
    } else if (g.contains('sufi') || g.contains('mystic') || g.contains('qawwali')) {
      state = AtmospherePalette.gangesMystic;
    } else if (g.contains('punjabi') || g.contains('bhangra') || g.contains('pop')) {
      state = AtmospherePalette.marigoldDawn;
    } else if (g.contains('south') || g.contains('carnatic') || g.contains('classical')) {
      state = AtmospherePalette.jaipurRose;
    } else if (g.contains('lo-fi') || g.contains('indie')) {
      state = AtmospherePalette.gangesMystic;
    } else if (g.contains('synthwave') || g.contains('cyberpunk')) {
      state = AtmospherePalette.cyberAura;
    } else {
      state = AtmospherePalette.saffronDusk;
    }
  }
}

final dynamicThemeControllerProvider =
    StateNotifierProvider<DynamicThemeController, AtmospherePalette>((ref) {
  return DynamicThemeController();
});
