import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'api/api.dart';
import 'models/profile_card_model.dart';
import 'models/schedule_model.dart';
import 'models/share_schedule_model.dart';
import 'providers/pro_feature_providers.dart';
import 'providers/schedule_provider.dart';
import 'screens/add_edit_schedule_screen.dart';
import 'screens/backend_diagnostics_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/manage_shared_links_screen.dart';
import 'screens/notification_settings_screen.dart';
import 'screens/profile_card_preview_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/public_profile_card_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/shared_schedule_view_screen.dart';
import 'screens/share_preview_screen.dart';
import 'screens/share_schedule_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/today_screen.dart';
import 'screens/week_schedule_screen.dart';
import 'screens/widget_preview_screen.dart';
import 'services/backend_diagnostics_service.dart';
import 'services/deep_link_service.dart';
import 'services/notification_service.dart';
import 'services/widget_sync_service.dart';
import 'theme/app_motion.dart';
import 'theme/app_theme.dart';
import 'widgets/app_navigation_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Api.initialize();
  runApp(const ProviderScope(child: ThoiKhoaBieuApp()));
  unawaited(BackendDiagnosticsService.checkBackendStatus());
  unawaited(NotificationService.initialize());
  unawaited(WidgetSyncService.initialize());
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppNavigationShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) =>
                    const NoTransitionPage<void>(child: HomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/week',
                pageBuilder: (context, state) =>
                    const NoTransitionPage<void>(child: WeekScheduleScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/today',
                pageBuilder: (context, state) =>
                    const NoTransitionPage<void>(child: TodayScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/statistics',
                pageBuilder: (context, state) =>
                    const NoTransitionPage<void>(child: StatisticsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                pageBuilder: (context, state) =>
                    const NoTransitionPage<void>(child: SettingsScreen()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/backend-diagnostics',
        pageBuilder: (context, state) =>
            _page(state, const BackendDiagnosticsScreen()),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) => _page(state, const ProfileScreen()),
      ),
      GoRoute(
        path: '/friends',
        pageBuilder: (context, state) => _page(state, const FriendsScreen()),
      ),
      GoRoute(
        path: '/profile-card',
        pageBuilder: (context, state) {
          final card = state.extra is ProfileCardModel
              ? state.extra! as ProfileCardModel
              : null;
          return _page(
            state,
            card == null
                ? const ProfileScreen()
                : ProfileCardPreviewScreen(card: card),
          );
        },
      ),
      GoRoute(
        path: '/profile-card-public/:id',
        pageBuilder: (context, state) => _page(
          state,
          PublicProfileCardScreen(cardId: state.pathParameters['id'] ?? ''),
        ),
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
    transitionDuration: const Duration(milliseconds: 240),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(
        parent: animation,
        curve: AppMotion.liquid,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(curve),
          child: child,
        ),
      );
    },
  );
}

class ThoiKhoaBieuApp extends ConsumerStatefulWidget {
  const ThoiKhoaBieuApp({super.key});

  @override
  ConsumerState<ThoiKhoaBieuApp> createState() => _ThoiKhoaBieuAppState();
}

class _ThoiKhoaBieuAppState extends ConsumerState<ThoiKhoaBieuApp> {
  Timer? _themeTimer;
  DateTime _themeClock = DateTime.now();

  @override
  void initState() {
    super.initState();
    _scheduleNextThemeTick();
  }

  @override
  void dispose() {
    _themeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(_routerProvider);
    unawaited(DeepLinkService.attach(router));

    ref.listen(schedulesProvider, (previous, next) {
      next.whenData((schedules) {
        final theme =
            ref.read(appSettingsProvider).valueOrNull?.themeMode ?? 'system';
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
        .watch(appSettingsProvider)
        .maybeWhen(
          data: (settings) => _themeModeFromString(settings.themeMode),
          orElse: () => ThemeMode.system,
        );

    return MaterialApp.router(
      title: 'Thời Khóa Biểu',
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
      'auto' => _isDarkHour(_themeClock) ? ThemeMode.dark : ThemeMode.light,
      _ => ThemeMode.system,
    };
  }

  bool _isDarkHour(DateTime now) {
    return now.hour < 6 || now.hour >= 18;
  }

  void _scheduleNextThemeTick() {
    final now = DateTime.now();
    final nextHour = DateTime(now.year, now.month, now.day, now.hour + 1);
    _themeTimer?.cancel();
    _themeTimer = Timer(nextHour.difference(now), () {
      if (!mounted) return;
      setState(() => _themeClock = DateTime.now());
      _scheduleNextThemeTick();
    });
  }
}
