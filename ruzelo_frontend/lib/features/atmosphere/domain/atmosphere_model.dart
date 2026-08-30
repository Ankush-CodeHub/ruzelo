import 'package:flutter/material.dart';

/// Domain representation of an Ambient Atmosphere configuration
class AtmosphereModel {
  final String id;
  final String name;
  final String description;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final double shaderSpeed;
  final double noiseScale;
  final double audioReactiveFactor;

  const AtmosphereModel({
    required this.id,
    required this.name,
    required this.description,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    this.shaderSpeed = 1.0,
    this.noiseScale = 1.0,
    this.audioReactiveFactor = 1.0,
  });

  factory AtmosphereModel.fromJson(Map<String, dynamic> json) {
    Color parseColor(dynamic hex, Color fallback) {
      if (hex is String) {
        final buffer = StringBuffer();
        if (hex.length == 6 || hex.length == 7) buffer.write('ff');
        buffer.write(hex.replaceFirst('#', ''));
        return Color(int.parse(buffer.toString(), radix: 16));
      }
      return fallback;
    }

    return AtmosphereModel(
      id: json['id'] as String? ?? 'cyber_aura',
      name: json['name'] as String? ?? 'Cyber Aura',
      description: json['description'] as String? ?? 'Electric hyper-space atmosphere',
      primaryColor: parseColor(json['primary_color'], const Color(0xFF8B5CF6)),
      secondaryColor: parseColor(json['secondary_color'], const Color(0xFF06B6D4)),
      accentColor: parseColor(json['accent_color'], const Color(0xFFEC4899)),
      shaderSpeed: (json['shader_speed'] as num?)?.toDouble() ?? 1.0,
      noiseScale: (json['noise_scale'] as num?)?.toDouble() ?? 1.0,
      audioReactiveFactor: (json['audio_reactive_factor'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'primary_color': '#${primaryColor.toARGB32().toRadixString(16).substring(2)}',
      'secondary_color': '#${secondaryColor.toARGB32().toRadixString(16).substring(2)}',
      'accent_color': '#${accentColor.toARGB32().toRadixString(16).substring(2)}',
      'shader_speed': shaderSpeed,
      'noise_scale': noiseScale,
      'audio_reactive_factor': audioReactiveFactor,
    };
  }

  static const List<AtmosphereModel> defaultAtmospheres = [
    AtmosphereModel(
      id: 'cyber_aura',
      name: 'Cyber Aura',
      description: 'Electric violet and neon cyan pulsating glow',
      primaryColor: Color(0xFF8B5CF6),
      secondaryColor: Color(0xFF06B6D4),
      accentColor: Color(0xFFEC4899),
      shaderSpeed: 1.2,
      noiseScale: 1.1,
      audioReactiveFactor: 1.3,
    ),
    AtmosphereModel(
      id: 'midnight_velvet',
      name: 'Midnight Velvet',
      description: 'Deep royal indigo and starlight hues',
      primaryColor: Color(0xFF312E81),
      secondaryColor: Color(0xFF1E1B4B),
      accentColor: Color(0xFF7C3AED),
      shaderSpeed: 0.8,
      noiseScale: 0.9,
      audioReactiveFactor: 0.9,
    ),
    AtmosphereModel(
      id: 'sunset_nebula',
      name: 'Sunset Nebula',
      description: 'Warm glowing magenta and sunset amber horizon',
      primaryColor: Color(0xFFF43F5E),
      secondaryColor: Color(0xFFFB923C),
      accentColor: Color(0xFF8B5CF6),
      shaderSpeed: 1.0,
      noiseScale: 1.2,
      audioReactiveFactor: 1.1,
    ),
    AtmosphereModel(
      id: 'deep_zen',
      name: 'Deep Zen',
      description: 'Tranquil emerald and atmospheric ocean depths',
      primaryColor: Color(0xFF059669),
      secondaryColor: Color(0xFF0284C7),
      accentColor: Color(0xFF10B981),
      shaderSpeed: 0.6,
      noiseScale: 0.8,
      audioReactiveFactor: 0.7,
    ),
  ];
}
