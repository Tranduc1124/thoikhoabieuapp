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
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/week',
        builder: (context, state) => const WeekScheduleScreen(),
      ),
      GoRoute(path: '/today', builder: (context, state) => const TodayScreen()),
      GoRoute(
        path: '/statistics',
        builder: (context, state) => const StatisticsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/schedule/new',
        builder: (context, state) => const AddEditScheduleScreen(),
      ),
      GoRoute(
        path: '/schedule/:id',
        builder: (context, state) => AddEditScheduleScreen(
          schedule: state.extra is ScheduleModel
              ? state.extra! as ScheduleModel
              : null,
        ),
      ),
    ],
  );
});

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
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
    );
  }

  ThemeData _theme(Brightness brightness) {
    final seed = brightness == Brightness.light
        ? const Color(0xFF246BFE)
        : const Color(0xFF7AA2FF);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? const Color(0xFFF7F8FC)
          : const Color(0xFF101218),
      fontFamily: 'SF Pro Display',
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      cardTheme: CardThemeData(
        elevation: 0,
        color: brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF191C22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
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
