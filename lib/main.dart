import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'models/schedule_model.dart';
import 'providers/auth_provider.dart';
import 'providers/pro_feature_providers.dart';
import 'providers/schedule_provider.dart';
import 'screens/add_edit_schedule_screen.dart';
import 'screens/firebase_diagnostics_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/manage_shared_links_screen.dart';
import 'screens/notification_settings_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/share_preview_screen.dart';
import 'screens/share_schedule_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/shared_schedule_view_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/today_screen.dart';
import 'screens/week_schedule_screen.dart';
import 'screens/widget_preview_screen.dart';
import 'models/share_schedule_model.dart';
import 'services/firebase_service.dart';
import 'services/firebase_diagnostics_service.dart';
import 'services/notification_service.dart';
import 'services/widget_sync_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  await FirebaseDiagnosticsService.checkFirebaseStatus();
  await NotificationService.initialize();
  await WidgetSyncService.initialize();
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
        path: '/firebase-diagnostics',
        pageBuilder: (context, state) =>
            _page(state, const FirebaseDiagnosticsScreen()),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) => _page(state, const ProfileScreen()),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) =>
            _page(state, const NotificationSettingsScreen()),
      ),
      GoRoute(
        path: '/widget-preview',
        pageBuilder: (context, state) =>
            _page(state, const WidgetPreviewScreen()),
      ),
      GoRoute(
        path: '/share',
        pageBuilder: (context, state) =>
            _page(state, const ShareScheduleScreen()),
      ),
      GoRoute(
        path: '/share/preview',
        pageBuilder: (context, state) {
          final share = state.extra is ShareScheduleModel
              ? state.extra! as ShareScheduleModel
              : null;
          return _page(
            state,
            share == null
                ? const ShareScheduleScreen()
                : SharePreviewScreen(share: share),
          );
        },
      ),
      GoRoute(
        path: '/shared',
        pageBuilder: (context, state) =>
            _page(state, const SharedScheduleViewScreen()),
      ),
      GoRoute(
        path: '/shared/:id',
        pageBuilder: (context, state) => _page(
          state,
          SharedScheduleViewScreen(shareId: state.pathParameters['id']),
        ),
      ),
      GoRoute(
        path: '/shared-links',
        pageBuilder: (context, state) =>
            _page(state, const ManageSharedLinksScreen()),
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
    ref.listen(schedulesProvider, (previous, next) {
      next.whenData((schedules) {
        final theme =
            ref.read(appUserProvider).valueOrNull?.themeMode ?? 'system';
        WidgetSyncService.syncSchedules(schedules: schedules, themeMode: theme);
        ref.read(liveActivityActionsProvider).refresh();
        final notificationSettings = ref
            .read(notificationSettingsProvider)
            .valueOrNull;
        if (notificationSettings != null) {
          NotificationService.rescheduleAllClassNotifications(
            schedules,
            settings: notificationSettings,
          );
        }
      });
    });
    ref.listen(notificationSettingsProvider, (previous, next) {
      next.whenData((settings) {
        final schedules = ref.read(schedulesProvider).valueOrNull ?? const [];
        if (schedules.isNotEmpty) {
          NotificationService.rescheduleAllClassNotifications(
            schedules,
            settings: settings,
          );
        }
      });
    });
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
