import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import 'animated_pressable.dart';
import 'glass_card.dart';

class AppNavigationShell extends StatelessWidget {
  const AppNavigationShell({
    super.key,
    required this.currentIndex,
    required this.child,
    this.floatingActionButton,
  });

  final int currentIndex;
  final Widget child;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: child,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: PremiumBottomNav(
          currentIndex: currentIndex,
          onSelected: (index) {
            switch (index) {
              case 0:
                context.go('/home');
              case 1:
                context.go('/week');
              case 2:
                context.go('/today');
              case 3:
                context.go('/statistics');
              case 4:
                context.go('/settings');
            }
          },
        ),
      ),
    );
  }
}

class PremiumBottomNav extends StatelessWidget {
  const PremiumBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    _NavItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
    _NavItem(
      Icons.calendar_view_week_outlined,
      Icons.calendar_view_week_rounded,
      'Tuần',
    ),
    _NavItem(Icons.today_outlined, Icons.today_rounded, 'Hôm nay'),
    _NavItem(Icons.insights_outlined, Icons.insights_rounded, 'Thống kê'),
    _NavItem(Icons.settings_outlined, Icons.settings_rounded, 'Cài đặt'),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GlassCard(
      radius: 30,
      padding: const EdgeInsets.all(6),
      opacity: colorScheme.isDark ? 1 : 0.94,
      borderColor: colorScheme.glassStroke,
      child: Row(
        children: [
          for (var index = 0; index < _items.length; index++)
            Expanded(
              child: _PremiumNavButton(
                item: _items[index],
                selected: currentIndex == index,
                onTap: () => onSelected(index),
              ),
            ),
        ],
      ),
    );
  }
}

class _PremiumNavButton extends StatelessWidget {
  const _PremiumNavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedPressable(
      onTap: onTap,
      scale: 0.94,
      child: AnimatedContainer(
        duration: AppMotion.medium,
        curve: AppMotion.liquid,
        height: 58,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: selected
              ? LinearGradient(
                  colors: [
                    colorScheme.primary,
                    Color.lerp(
                      colorScheme.primary,
                      colorScheme.tertiary,
                      0.45,
                    )!,
                  ],
                )
              : null,
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.22)
                : Colors.transparent,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? item.selectedIcon : item.icon,
              size: 21,
              color: selected
                  ? colorScheme.onPrimary
                  : colorScheme.textSecondary,
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                item.label,
                maxLines: 1,
                style: TextStyle(
                  color: selected
                      ? colorScheme.onPrimary
                      : colorScheme.textSecondary,
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.selectedIcon, this.label);

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
