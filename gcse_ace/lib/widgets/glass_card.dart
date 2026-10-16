import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A frosted-glass surface: translucent fill, hairline border, soft shadow.
///
/// This is the app's main container. Cards, panels, the nav bar and dialogs
/// are all built from it so the UI reads as one system.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.radius = 24,
    this.onTap,
    this.onLongPress,
    this.blur = false,
    this.opacity = 1,
    this.gradient,
    this.borderColor,
    this.alignment,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Blurs whatever is behind the card (needs a backdrop worth blurring).
  final bool blur;

  /// Overall strength of the glass effect, 0 - 1.
  final double opacity;

  /// Replaces the glass fill with an explicit gradient (hero surfaces).
  final Gradient? gradient;

  final Color? borderColor;
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color fill;
    if (isDark) {
      fill = Colors.white.withValues(alpha: 0.06 * opacity);
    } else {
      fill = Colors.white.withValues(alpha: 0.78 * opacity);
    }

    final Color border =
        borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.1 * opacity)
            : Colors.white.withValues(alpha: 0.95 * opacity));

    final Color shadowTint = isDark
        ? Colors.black.withValues(alpha: 0.45)
        : AppColors.primary.withValues(alpha: 0.10);

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: border, width: 1),
    );

    final surface = DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? fill : null,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: shadowTint,
            blurRadius: isDark ? 18 : 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Align(
        alignment: alignment ?? Alignment.topLeft,
        child: Padding(padding: padding, child: child),
      ),
    );

    Widget content = surface;
    if (blur) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: surface,
        ),
      );
    }

    return Container(
      margin: margin,
      child: Material(
        color: Colors.transparent,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: content,
        ),
      ),
    );
  }
}

/// Small tinted pill used for metadata (year, duration, marks...).
class MetaChip extends StatelessWidget {
  const MetaChip({
    super.key,
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = color ?? Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: tint),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: tint,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section heading with an optional trailing action.
class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// Rounded icon badge painted with one of the app's accent gradients.
class GradientIcon extends StatelessWidget {
  const GradientIcon({
    super.key,
    required this.icon,
    this.size = 52,
    this.iconSize = 24,
    this.gradient,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final g = gradient ?? AppColors.brand;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: g,
        borderRadius: BorderRadius.circular(size * 0.34),
        boxShadow: [
          BoxShadow(
            color: g.colors.first.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: iconSize),
    );
  }
}
