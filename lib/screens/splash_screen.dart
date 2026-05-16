import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/auth_session.dart';
import '../providers/auth_provider.dart';
import '../providers/pro_feature_providers.dart';
import '../providers/schedule_provider.dart';
import '../providers/weather_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/glass_card.dart';
import '../widgets/soft_gradient_background.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  String _status = 'Đang chuẩn bị lịch học…';
  double _progress = 0.12;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    _route();
  }

  Future<void> _route() async {
    final session = await _runStep<AuthSession?>(
      'Đang đồng bộ hồ sơ…',
      0.34,
      () => ref.read(authControllerProvider.future),
      fallback: null,
      timeout: const Duration(seconds: 2),
    );

    await _runStep<void>(
      'Đang chuẩn bị giao diện…',
      0.52,
      () => ref.read(appSettingsProvider.future),
      timeout: const Duration(seconds: 2),
    );

    if (session != null) {
      await _runStep<void>('Đang chuẩn bị lịch học…', 0.72, () async {
        await ref.read(appUserProvider.future);
        await ref.read(schedulesProvider.future);
      }, timeout: const Duration(seconds: 3));
    }

    await _runStep<void>(
      'Đang tải thời tiết hôm nay…',
      0.88,
      () => ref.read(homeWeatherProvider.future),
      timeout: const Duration(seconds: 2),
    );

    await _runStep<void>(
      'Sẵn sàng!',
      1,
      () => Future<void>.delayed(const Duration(milliseconds: 260)),
      timeout: const Duration(seconds: 1),
    );

    if (!mounted) return;
    context.go(session != null ? '/home' : '/login');
  }

  Future<T?> _runStep<T>(
    String status,
    double progress,
    Future<T> Function() task, {
    T? fallback,
    Duration timeout = const Duration(seconds: 2),
  }) async {
    if (mounted) {
      setState(() {
        _status = status;
        _progress = progress;
      });
    }
    try {
      return await task().timeout(timeout);
    } catch (_) {
      return fallback;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SoftGradientBackground(
        child: Center(
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: _controller,
              curve: Curves.easeOut,
            ),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.88, end: 1).animate(
                CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
              ),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 32,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _OrbitingLoader(
                      controller: _controller,
                      progress: _progress,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Thời Khóa Biểu',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AnimatedSwitcher(
                      duration: AppMotion.fast,
                      switchInCurve: AppMotion.liquid,
                      switchOutCurve: AppMotion.exit,
                      child: Text(
                        _status,
                        key: ValueKey(_status),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: 220,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(end: _progress),
                          duration: AppMotion.medium,
                          curve: AppMotion.liquid,
                          builder: (context, value, child) {
                            return LinearProgressIndicator(
                              value: value,
                              minHeight: 9,
                              backgroundColor: colorScheme.tileSurface,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _LoadingDots(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbitingLoader extends StatelessWidget {
  const _OrbitingLoader({required this.controller, required this.progress});

  final AnimationController controller;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return SizedBox(
          width: 132,
          height: 132,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 124,
                height: 124,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5,
                  strokeCap: StrokeCap.round,
                  backgroundColor: colorScheme.tileSurface,
                ),
              ),
              Transform.rotate(
                angle: controller.value * 6.28318,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.tertiary,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.tertiary.withValues(alpha: 0.42),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Hero(
                tag: 'app-logo',
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [colorScheme.primary, colorScheme.tertiary],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.30),
                        blurRadius: 30,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 980),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.18;
            final progress = ((_controller.value - delay) % 1).clamp(0.0, 1.0);
            final scale = 0.82 + (1 - (progress - 0.5).abs() * 2) * 0.32;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary.withValues(
                      alpha: 0.46 + scale * 0.28,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
