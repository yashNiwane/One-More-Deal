import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand core
  static const Color primary = Color(0xFF1A2B5F);      // Deep Navy
  static const Color primaryLight = Color(0xFF2D4A9B);  // Medium Blue
  static const Color accent = Color(0xFFF59E0B);        // Premium Gold
  static const Color accentLight = Color(0xFFFBBF24);   // Light Gold

  // Gradients
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D1B4B), Color(0xFF1A2B5F), Color(0xFF1E3A8A)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E3A8A), Color(0xFF1A2B5F)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
  );

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF8FAFC);
  static const Color lightGray = Color(0xFFE2E8F0);
  static const Color mediumGray = Color(0xFF94A3B8);
  static const Color darkGray = Color(0xFF475569);
  static const Color charcoal = Color(0xFF1E293B);

  // Feedback
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Surfaces
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF0F172A);
  static const Color overlay = Color(0x66000000);

  // Glass morphism
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);

  // ── iOS / Apple-style design tokens ──────────────────────────────────
  static const Color iosGroupedBg = Color(0xFFF2F2F7);     // iOS Settings background
  static const Color iosCardBg = Color(0xFFFFFFFF);         // White card surface
  static const Color iosSeparator = Color(0xFFC6C6C8);     // iOS thin separator
  static const Color iosSecondaryLabel = Color(0xFF8E8E93); // iOS secondary text
  static const Color iosTertiaryLabel = Color(0xFFAEAEB2);  // iOS tertiary text
  static const Color iosSystemBlue = Color(0xFF022B5F);     // iOS tappable blue (primary)
  static const Color iosDestructive = Color(0xFFFF3B30);    // iOS destructive red
  static const Color iosSystemGreen = Color(0xFF34C759);    // iOS green
  static const Color iosFill = Color(0xFFE5E5EA);           // iOS fill color

  // Frosted nav bar
  static const Color frostedNavBg = Color(0xF0F9F9F9);     // ~94% opaque white
  static const Color frostedNavBorder = Color(0x33A0A0A0);  // Thin top border
}
