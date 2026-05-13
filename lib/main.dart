import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'models/schedule_model.dart';
import 'providers/auth_provider.dart';
import 'screens/add_edit_schedule_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/today_screen.dart';
import 'screens/week_schedule_screen.dart';
import 'services/firebase_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  await NotificationService.initialize();
  runApp(const ProviderScope(child: ThoiKhoaBieuApp()));
}

final _routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _page(state, const SplashScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _page(state, const LoginScreen()),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => _page(state, const HomeScreen()),
      ),
      GoRoute(
        path: '/week',
        pageBuilder: (context, state) =>
            _page(state, const WeekScheduleScreen()),
      ),
      GoRoute(
        path: '/today',
        pageBuilder: (context, state) => _page(state, const TodayScreen()),
      ),
      GoRoute(
        path: '/statistics',
        pageBuilder: (context, state) => _page(state, const StatisticsScreen()),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => _page(state, const SettingsScreen()),
      ),
      GoRoute(
        path: '/schedule/new',
        pageBuilder: (context, state) =>
            _page(state, const AddEditScheduleScreen()),
      ),
      GoRoute(
        path: '/schedule/:id',
        pageBuilder: (context, state) => _page(
          state,
          AddEditScheduleScreen(
            schedule: state.extra is ScheduleModel
                ? state.extra! as ScheduleModel
                : null,
          ),
        ),
      ),
    ],
  );
});

CustomTransitionPage<void> _page(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 360),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.035),
            end: Offset.zero,
          ).animate(curve),
          child: child,
        ),
      );
    },
  );
}

class ThoiKhoaBieuApp extends ConsumerWidget {
  const ThoiKhoaBieuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);
    final themeMode = ref
        .watch(appUserProvider)
        .maybeWhen(
          data: (user) => _themeModeFromString(user?.themeMode),
          orElse: () => ThemeMode.system,
        );

    return MaterialApp.router(
      title: 'Thời Khoá Biểu',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      themeMode: themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
    );
  }

  ThemeMode _themeModeFromString(String? value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
}
