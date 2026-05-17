import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'glass_card.dart';

enum LoadingSkeletonVariant { cards, profile, stats }

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({
    super.key,
    this.itemCount = 3,
    this.variant = LoadingSkeletonVariant.cards,
  });

  final int itemCount;
  final LoadingSkeletonVariant variant;

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      LoadingSkeletonVariant.profile => const _ProfileSkeleton(),
      LoadingSkeletonVariant.stats => const _StatsSkeleton(),
      LoadingSkeletonVariant.cards => Column(
        children: [
          for (var i = 0; i < itemCount; i++)
            const GlassCard(
              margin: EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Bar(widthFactor: 0.55),
                  SizedBox(height: 14),
                  _Bar(widthFactor: 0.86),
                  SizedBox(height: 10),
                  _Bar(widthFactor: 0.38),
                ],
              ),
            ),
        ],
      ),
    };
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

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
                  _Circle(size: 76),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Bar(widthFactor: 0.58),
                        const SizedBox(height: 12),
                        _Bar(widthFactor: 0.42),
                        const SizedBox(height: 12),
                        _Bar(widthFactor: 0.88),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: _MetricBlock()),
                  const SizedBox(width: 10),
                  Expanded(child: _MetricBlock()),
                  const SizedBox(width: 10),
                  Expanded(child: _MetricBlock()),
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
                _Bar(widthFactor: 0.32),
                const SizedBox(height: 14),
                _Bar(widthFactor: 0.92),
                const SizedBox(height: 10),
                _Bar(widthFactor: 0.74),
              ],
            ),
          ),
      ],
    );
  }
}

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _MetricBlock(tall: true)),
            const SizedBox(width: 12),
            Expanded(child: _MetricBlock(tall: true)),
          ],
        ),
        const SizedBox(height: 14),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Bar(widthFactor: 0.66),
              const SizedBox(height: 12),
              _Bar(widthFactor: 0.48),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final height in [86.0, 132.0, 104.0, 156.0, 92.0]) ...[
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: _ChartBar(height: height),
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
  const _Bar({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final base = colorScheme.isDark
        ? const Color(0xFF172238)
        : colorScheme.tileSurface;
    final highlight = colorScheme.isDark
        ? const Color(0xFF26344F)
        : Colors.white.withValues(alpha: 0.76);
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 14,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              base.withValues(alpha: 0.72),
              highlight,
              base.withValues(alpha: 0.62),
            ],
          ),
        ),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final base = colorScheme.isDark
        ? const Color(0xFF172238)
        : colorScheme.tileSurface;
    final highlight = colorScheme.isDark
        ? const Color(0xFF26344F)
        : Colors.white.withValues(alpha: 0.95);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            base.withValues(alpha: 0.72),
            highlight,
            base.withValues(alpha: 0.62),
          ],
        ),
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({this.tall = false});

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
          const _Bar(widthFactor: 0.54),
          SizedBox(height: tall ? 14 : 10),
          const _Bar(widthFactor: 0.72),
        ],
      ),
    );
  }
}

class _ChartBar extends StatelessWidget {
  const _ChartBar({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final base = colorScheme.isDark
        ? const Color(0xFF172238)
        : colorScheme.tileSurface;
    final highlight = colorScheme.isDark
        ? const Color(0xFF26344F)
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
          stops: const [0, 0.54, 1],
        ),
      ),
    );
  }
}
