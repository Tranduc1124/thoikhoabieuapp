import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';
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
    await Future<void>.delayed(const Duration(milliseconds: 1250));
    if (!mounted) return;
    final user = await ref.read(authControllerProvider.future);
    if (!mounted) return;
    context.go(
      FirebaseService.isAvailable && user != null ? '/home' : '/login',
    );
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
                    Hero(
                      tag: 'app-logo',
                      child: Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(34),
                          gradient: LinearGradient(
                            colors: [colorScheme.primary, colorScheme.tertiary],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(
                                alpha: 0.28,
                              ),
                              blurRadius: 30,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: Colors.white,
                          size: 54,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Thời Khoá Biểu',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lịch học gọn gàng, đồng bộ mọi nơi',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
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
