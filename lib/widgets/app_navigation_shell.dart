import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
      body: child,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: NavigationBar(
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
            label: 'Tuan',
          ),
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today_rounded),
            label: 'Hom nay',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Thong ke',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Cai dat',
          ),
        ],
      ),
    );
  }
}
