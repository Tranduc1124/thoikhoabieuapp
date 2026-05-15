import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'glass_card.dart';

enum LoadingSkeletonVariant { cards, profile, stats }

class LoadingSkeleton extends StatefulWidget {
  const LoadingSkeleton({
    super.key,
    this.itemCount = 3,
    this.variant = LoadingSkeletonVariant.cards,
  });

  final int itemCount;
  final LoadingSkeletonVariant variant;

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
        return switch (widget.variant) {
          LoadingSkeletonVariant.profile => _ProfileSkeleton(
            value: _controller.value,
          ),
          LoadingSkeletonVariant.stats => _StatsSkeleton(
            value: _controller.value,
          ),
          LoadingSkeletonVariant.cards => Column(
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
          ),
        };
      },
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GlassCard(
          margin: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Circle(value: value, size: 76),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Bar(widthFactor: 0.58, value: value),
                        const SizedBox(height: 12),
                        _Bar(widthFactor: 0.42, value: value),
                        const SizedBox(height: 12),
                        _Bar(widthFactor: 0.88, value: value),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: _MetricBlock(value: value)),
                  const SizedBox(width: 10),
                  Expanded(child: _MetricBlock(value: value)),
                  const SizedBox(width: 10),
                  Expanded(child: _MetricBlock(value: value)),
                ],
              ),
            ],
          ),
        ),
        for (var i = 0; i < 2; i++)
          GlassCard(
            margin: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Bar(widthFactor: 0.32, value: value),
                const SizedBox(height: 14),
                _Bar(widthFactor: 0.92, value: value),
                const SizedBox(height: 10),
                _Bar(widthFactor: 0.74, value: value),
              ],
            ),
          ),
      ],
    );
  }
}

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _MetricBlock(value: value, tall: true)),
            const SizedBox(width: 12),
            Expanded(child: _MetricBlock(value: value, tall: true)),
          ],
        ),
        const SizedBox(height: 14),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Bar(widthFactor: 0.66, value: value),
              const SizedBox(height: 12),
              _Bar(widthFactor: 0.48, value: value),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final height in [86.0, 132.0, 104.0, 156.0, 92.0]) ...[
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: _ChartBar(height: height, value: value),
                      ),
                    ),
                    if (height != 92.0) const SizedBox(width: 10),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
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
        ? Colors.white.withValues(alpha: 0.12)
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

class _Circle extends StatelessWidget {
  const _Circle({required this.value, required this.size});

  final double value;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final base = colorScheme.tileSurface;
    final highlight = colorScheme.isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.95);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
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
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({required this.value, this.tall = false});

  final double value;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(tall ? 18 : 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Theme.of(context).colorScheme.tileSurface,
        border: Border.all(
          color: Theme.of(context).colorScheme.glassStrokeSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Bar(widthFactor: 0.54, value: value),
          SizedBox(height: tall ? 14 : 10),
          _Bar(widthFactor: 0.72, value: value),
        ],
      ),
    );
  }
}

class _ChartBar extends StatelessWidget {
  const _ChartBar({required this.height, required this.value});

  final double height;
  final double value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final base = colorScheme.tileSurface;
    final highlight = colorScheme.isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.95);
    return Container(
      width: 24,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            base.withValues(alpha: 0.6),
            highlight.withValues(alpha: 0.9),
            base.withValues(alpha: 0.45),
          ],
          stops: [0, value.clamp(0.2, 0.72), 1],
        ),
      ),
    );
  }
}
