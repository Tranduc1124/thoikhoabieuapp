import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
        child: GlassCard(
          radius: 28,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: NavigationBar(
            height: 64,
            selectedIndex: currentIndex,
            onDestinationSelected: (index) {
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
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_view_week_outlined),
                selectedIcon: Icon(Icons.calendar_view_week_rounded),
                label: 'Tuần',
              ),
              NavigationDestination(
                icon: Icon(Icons.today_outlined),
                selectedIcon: Icon(Icons.today_rounded),
                label: 'Hôm nay',
              ),
              NavigationDestination(
                icon: Icon(Icons.insights_outlined),
                selectedIcon: Icon(Icons.insights_rounded),
                label: 'Thống kê',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded),
                label: 'Cài đặt',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
