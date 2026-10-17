import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../screens/admin/admin_home.dart';
import '../screens/home_screen.dart';
import '../screens/materials_screen.dart';
import '../screens/papers_screen.dart';
import '../screens/profile_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/app_background.dart';
import '../providers/auth_provider.dart';

/// Which tab the shell is showing. Other screens (e.g. Home's CTA) can switch
/// tabs by writing to this instead of pushing a route.
final shellIndexProvider = StateProvider<int>((ref) => 0);

/// The root scaffold: a floating glass tab bar over the main areas.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(shellIndexProvider);
    final isAdmin = ref.watch(isAdminProvider).value ?? false;

    final screens = <Widget>[
      HomeScreen(),
      PapersScreen(),
      MaterialsScreen(),
      ProfileScreen(),
      if (isAdmin) AdminHomeScreen(),
    ];

    final items = <(IconData, IconData, String)>[
      (Icons.dashboard_outlined, Icons.dashboard, 'Home'),
      (Icons.description_outlined, Icons.description, 'Papers'),
      (Icons.menu_book_outlined, Icons.menu_book, 'Materials'),
      (Icons.person_outline, Icons.person, 'Profile'),
      if (isAdmin) (Icons.admin_panel_settings_outlined, Icons.admin_panel_settings, 'Admin'),
    ];

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: false,
        body: IndexedStack(index: index, children: screens),
        bottomNavigationBar: _GlassNavBar(
          index: index,
          onSelect: (i) => ref.read(shellIndexProvider.notifier).state = i,
          itemCount: items.length,
          items: items,
        ),
      ),
    );
  }
}

class _GlassNavBar extends StatelessWidget {
  const _GlassNavBar({required this.index, required this.onSelect, required this.itemCount, required this.items});

  final int index;
  final ValueChanged<int> onSelect;
  final int itemCount;
  final List<(IconData, IconData, String)> items;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: bottomInset > 0 ? bottomInset : 14,
          ),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.95),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.4)
                      : AppColors.primary.withValues(alpha: 0.14),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: List.generate(itemCount, (i) {
                final selected = i == index;
                final item = items[i];
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onSelect(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        gradient: selected ? AppColors.brand : null,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.45,
                                  ),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : const [],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            selected ? item.$2 : item.$1,
                            size: 22,
                            color: selected
                                ? Colors.white
                                : (isDark
                                      ? AppColors.darkInkFaint
                                      : AppColors.inkFaint),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.$3,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : (isDark
                                        ? AppColors.darkInkFaint
                                        : AppColors.inkFaint),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}