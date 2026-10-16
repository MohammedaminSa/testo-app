import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The app's primary call-to-action: a gradient pill with a coloured glow.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.gradient = AppColors.brand,
    this.height = 56,
    this.expanded = true,
    this.icon,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Gradient gradient;
  final double height;
  final bool expanded;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            gradient: disabled
                ? LinearGradient(
                    colors: [
                      Colors.grey.withValues(alpha: 0.4),
                      Colors.grey.withValues(alpha: 0.3),
                    ],
                  )
                : gradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: disabled
                ? const []
                : [
                    BoxShadow(
                      color: gradient.colors.last.withValues(alpha: 0.4),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          child: Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            alignment: Alignment.center,
            child: DefaultTextStyle(
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                  ],
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (!expanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}

/// Light counterpart of [GradientButton], for use on top of gradient heroes.
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.height = 52,
    this.expanded = true,
    this.icon,
    this.filled = true,
    this.onGradient = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final double height;
  final bool expanded;
  final IconData? icon;
  final bool filled;

  /// Set when the button sits on top of a coloured gradient surface, so it
  /// stays solid white with indigo text instead of following the dark theme.
  final bool onGradient;

  @override
  Widget build(BuildContext context) {
    final isDark =
        !onGradient && Theme.of(context).brightness == Brightness.dark;

    final Color foreground = isDark
        ? AppColors.darkInk
        : filled || onGradient
        ? AppColors.primaryDeep
        : Colors.white;

    final Color background;
    if (onGradient) {
      background = Colors.white.withValues(alpha: 0.95);
    } else if (filled) {
      background = isDark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.white.withValues(alpha: 0.92);
    } else {
      background = Colors.transparent;
    }

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(18),
            border: filled
                ? null
                : Border.all(color: Colors.white.withValues(alpha: 0.6)),
          ),
          child: Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            alignment: Alignment.center,
            child: DefaultTextStyle(
              style: TextStyle(
                color: foreground,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: foreground),
                    const SizedBox(width: 8),
                  ],
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (!expanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
