import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'glass_card.dart';

class LoadingSkeleton extends StatefulWidget {
  const LoadingSkeleton({super.key, this.itemCount = 3});

  final int itemCount;

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Column(
          children: [
            for (var i = 0; i < widget.itemCount; i++)
              GlassCard(
                margin: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Bar(widthFactor: 0.55, value: _controller.value),
                    const SizedBox(height: 14),
                    _Bar(widthFactor: 0.86, value: _controller.value),
                    const SizedBox(height: 10),
                    _Bar(widthFactor: 0.38, value: _controller.value),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.widthFactor, required this.value});

  final double widthFactor;
  final double value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final base = colorScheme.tileSurface;
    final highlight = colorScheme.isDark
        ? Colors.white.withValues(alpha: 0.20)
        : Colors.white.withValues(alpha: 0.95);
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 14,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(
            begin: Alignment(-1 + value * 2, 0),
            end: Alignment(value * 2, 0),
            colors: [
              base.withValues(alpha: 0.55),
              highlight.withValues(alpha: 0.92),
              base.withValues(alpha: 0.55),
            ],
          ),
        ),
      ),
    );
  }
}
