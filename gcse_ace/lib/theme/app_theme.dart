import 'package:flutter/material.dart';

/// Central place for GCSE Ace's visual identity.
///
/// Everything visual (colors, theme) lives here so we can tweak the look in
/// one spot instead of scattered across all screens.
abstract final class AppTheme {
  /// GCSE Ace uses a deep blue as its brand colour:
  /// calm enough to study with, but not boring.
  static const Color seed = Color(0xFF1D4ED8);

  /// The single source of truth for the app's look.
  static ThemeData get light =>
      ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: seed));
}
