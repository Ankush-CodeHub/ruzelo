import 'package:flutter/material.dart';

/// Design tokens for Ruzelo's cinematic glassmorphic dark theme
class AppColors {
  AppColors._();

  // Background & Deep Space
  static const Color background = Color(0xFF0A0B10);
  static const Color surfaceDark = Color(0xFF12141F);
  static const Color surfaceElevated = Color(0xFF1B1E2E);
  static const Color surfaceCard = Color(0x2A252A40);

  // Glass Elements
  static const Color glassFill = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassHighlight = Color(0x4DFFFFFF);
  static const Color glassDarkFill = Color(0x800D0F18);

  // Brand Accent Neon Colors
  static const Color primaryNeon = Color(0xFF8B5CF6);      // Electric Violet
  static const Color secondaryNeon = Color(0xFF06B6D4);    // Cyber Cyan
  static const Color accentNeon = Color(0xFFEC4899);       // Velvet Magenta
  static const Color pulseAmber = Color(0xFFF59E0B);       // Luminous Amber
  static const Color pulseGreen = Color(0xFF10B981);       // Neon Emerald

  // Text & Content
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textTertiary = Color(0xFF64748B);
  static const Color textGlow = Color(0xFFE2E8F0);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [
      Color(0x33FFFFFF),
      Color(0x0DFFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [
      Color(0x401E2238),
      Color(0x200E101C),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
