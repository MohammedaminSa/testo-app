import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The soft gradient + floating colour blobs every screen sits on top of.
///
/// Keeping it in one widget means the whole app shares the same atmosphere
/// instead of each screen inventing its own background.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [AppColors.darkBgTop, AppColors.darkBgBottom]
              : const [AppColors.lightBgTop, AppColors.lightBgBottom],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -90,
            left: -70,
            child: _Blob(
              size: 300,
              color: AppColors.primary.withValues(alpha: isDark ? 0.38 : 0.18),
            ),
          ),
          Positioned(
            top: 40,
            right: -120,
            child: _Blob(
              size: 320,
              color: AppColors.secondary.withValues(
                alpha: isDark ? 0.3 : 0.15,
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -110,
            child: _Blob(
              size: 280,
              color: AppColors.accent.withValues(alpha: isDark ? 0.24 : 0.13),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -60,
            child: _Blob(
              size: 260,
              color: const Color(0xFFEC4899).withValues(
                alpha: isDark ? 0.2 : 0.1,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}
