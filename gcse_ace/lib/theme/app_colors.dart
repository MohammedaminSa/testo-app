import 'package:flutter/material.dart';

/// GCSE Ace colour tokens.
///
/// Raw `Color(...)` values only live here so screens can stay consistent
/// without inventing their own colours.
abstract final class AppColors {
  // Brand -------------------------------------------------------------
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryDeep = Color(0xFF4338CA);
  static const Color secondary = Color(0xFF7C3AED);
  static const Color accent = Color(0xFF06B6D4);
  static const Color sky = Color(0xFF38BDF8);

  // Semantic ----------------------------------------------------------
  static const Color success = Color(0xFF10B981);
  static const Color successDeep = Color(0xFF059669);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerDeep = Color(0xFFDC2626);

  // Light -------------------------------------------------------------
  static const Color lightBgTop = Color(0xFFF7F8FF);
  static const Color lightBgBottom = Color(0xFFECEFFF);
  static const Color ink = Color(0xFF101828);
  static const Color inkSoft = Color(0xFF475569);
  static const Color inkFaint = Color(0xFF94A3B8);
  static const Color hairline = Color(0xFFE4E8F4);

  // Dark --------------------------------------------------------------
  static const Color darkBgTop = Color(0xFF080B14);
  static const Color darkBgBottom = Color(0xFF111726);
  static const Color darkInk = Color(0xFFF1F5F9);
  static const Color darkInkSoft = Color(0xFFA9B4C8);
  static const Color darkInkFaint = Color(0xFF6B7893);

  // Gradients ---------------------------------------------------------
  static const LinearGradient brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF7C3AED)],
  );

  static const LinearGradient brandSoft = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF818CF8), Color(0xFFA78BFA)],
  );

  static const LinearGradient aurora = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF38BDF8), Color(0xFF6366F1), Color(0xFF9333EA)],
  );

  static const LinearGradient mint = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF34D399), Color(0xFF06B6D4)],
  );

  static const LinearGradient sunset = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFBBF24), Color(0xFFF97316)],
  );

  static const LinearGradient ember = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFB7185), Color(0xFFE11D48)],
  );

  /// Every accent used to tint department / quick-action tiles.
  static const List<LinearGradient> accents = [
    brand,
    aurora,
    mint,
    sunset,
    ember,
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF22D3EE), Color(0xFF0EA5E9)],
    ),
  ];

  /// Picks an accent deterministically so a given item keeps its colour.
  static LinearGradient accentFor(int index) =>
      accents[index % accents.length];
}
