import 'dart:ui';

import 'package:flutter/material.dart';

/// Frosted, transparent app bar.
///
/// Content scrolling underneath blurs instead of colliding with the title.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.bottom,
  });

  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: AppBar(
          title: title,
          actions: actions,
          leading: leading,
          bottom: bottom,
          automaticallyImplyLeading: automaticallyImplyLeading,
          backgroundColor: isDark
              ? Colors.black.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.55),
          surfaceTintColor: Colors.transparent,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
