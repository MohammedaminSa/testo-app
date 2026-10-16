import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Central place for GCSE Ace's visual identity.
///
/// Everything visual (colour, type, component defaults) lives here so the look
/// can be tweaked in one spot instead of scattered across every screen.
abstract final class AppTheme {
  /// The colour the whole palette is derived from.
  static const Color seed = AppColors.primary;

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      primary: isDark ? const Color(0xFF818CF8) : AppColors.primary,
      onPrimary: isDark ? const Color(0xFF0B1020) : Colors.white,
      primaryContainer: isDark
          ? const Color(0xFF312E81)
          : const Color(0xFFE4E6FF),
      onPrimaryContainer: isDark
          ? const Color(0xFFC7D2FE)
          : const Color(0xFF2E1065),
      secondary: isDark ? const Color(0xFFC084FC) : AppColors.secondary,
      tertiary: isDark ? const Color(0xFF22D3EE) : AppColors.accent,
      surface: isDark ? AppColors.darkBgBottom : Colors.white,
      onSurface: isDark ? AppColors.darkInk : AppColors.ink,
      onSurfaceVariant: isDark ? AppColors.darkInkSoft : AppColors.inkSoft,
      outline: isDark ? const Color(0xFF2A3346) : AppColors.hairline,
      outlineVariant: isDark
          ? const Color(0xFF222A3B)
          : const Color(0xFFEDF0FA),
      error: isDark ? const Color(0xFFF87171) : AppColors.danger,
      onError: Colors.white,
      errorContainer: isDark
          ? const Color(0xFF4C0519)
          : const Color(0xFFFEE2E2),
      onErrorContainer: isDark
          ? const Color(0xFFFECACA)
          : const Color(0xFF7F1D1D),
      surfaceContainerLowest: isDark ? const Color(0xFF05070D) : Colors.white,
      surfaceContainerLow: isDark
          ? const Color(0xFF0D1220)
          : const Color(0xFFF8F9FF),
      surfaceContainer: isDark ? const Color(0xFF131A2B) : Colors.white,
      surfaceContainerHigh: isDark
          ? const Color(0xFF182034)
          : const Color(0xFFF1F4FF),
      surfaceContainerHighest: isDark
          ? const Color(0xFF1E2740)
          : const Color(0xFFE8ECFF),
    );

    final onSurface = scheme.onSurface;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark
          ? AppColors.darkBgTop
          : AppColors.lightBgTop,
      splashFactory: InkSparkle.splashFactory,
      textTheme: _textTheme(onSurface, isDark),
      appBarTheme: AppBarThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: _textTheme(onSurface, isDark).titleLarge,
        iconTheme: IconThemeData(color: onSurface),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          side: BorderSide(
            color: isDark ? const Color(0xFF2E3A55) : const Color(0xFFD9DEF2),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.85),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        hintStyle: TextStyle(
          color: isDark ? AppColors.darkInkFaint : AppColors.inkFaint,
        ),
        labelStyle: TextStyle(
          color: isDark ? AppColors.darkInkSoft : AppColors.inkSoft,
        ),
        prefixIconColor: isDark ? AppColors.darkInkSoft : AppColors.inkSoft,
        suffixIconColor: isDark ? AppColors.darkInkSoft : AppColors.inkSoft,
        border: _inputBorder(isDark),
        enabledBorder: _inputBorder(isDark),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppColors.darkBgBottom : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: _textTheme(onSurface, isDark).titleLarge,
        contentTextStyle: _textTheme(onSurface, isDark).bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF1E293B) : AppColors.ink,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? const Color(0xFF232C40) : const Color(0xFFE9EDF9),
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: isDark ? const Color(0xFF818CF8) : AppColors.primary,
        linearTrackColor: isDark
            ? const Color(0xFF243047)
            : const Color(0xFFD7DDF3),
        circularTrackColor: isDark
            ? const Color(0xFF243047)
            : const Color(0xFFD7DDF3),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: isDark ? AppColors.darkInkSoft : AppColors.inkSoft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? AppColors.darkBgBottom : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: isDark
            ? AppColors.darkInkSoft
            : AppColors.inkSoft,
        indicatorColor: AppColors.primary,
      ),
      checkboxTheme: CheckboxThemeData(
        side: BorderSide(
          color: isDark ? const Color(0xFF3A4460) : const Color(0xFFC3CAE4),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  static InputBorder _inputBorder(bool isDark) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: BorderSide(
      color: isDark ? const Color(0xFF2A3346) : const Color(0xFFE1E6F5),
    ),
  );

  static TextTheme _textTheme(Color foreground, bool isDark) {
    final soft = isDark ? AppColors.darkInkSoft : AppColors.inkSoft;
    final faint = isDark ? AppColors.darkInkFaint : AppColors.inkFaint;

    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 52,
        height: 1.05,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.6,
        color: foreground,
      ),
      displayMedium: TextStyle(
        fontSize: 44,
        height: 1.08,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        color: foreground,
      ),
      headlineLarge: TextStyle(
        fontSize: 34,
        height: 1.12,
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
        color: foreground,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        height: 1.18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: foreground,
      ),
      headlineSmall: TextStyle(
        fontSize: 23,
        height: 1.25,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: foreground,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        height: 1.3,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: foreground,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
        color: foreground,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        height: 1.35,
        fontWeight: FontWeight.w600,
        color: foreground,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.55,
        fontWeight: FontWeight.w400,
        color: foreground,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: soft,
      ),
      bodySmall: TextStyle(
        fontSize: 12.5,
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: faint,
      ),
      labelLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
        color: foreground,
      ),
      labelMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: soft,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: faint,
      ),
    );
  }
}
