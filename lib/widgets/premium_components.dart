import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'animated_pressable.dart';
import 'empty_state.dart';
import 'glass_card.dart';
import 'section_header.dart';
import 'soft_gradient_background.dart';

class AppScaffoldBackground extends StatelessWidget {
  const AppScaffoldBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SoftGradientBackground(child: child);
}

class LiquidGlassCard extends StatelessWidget {
  const LiquidGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 32,
      padding: padding,
      margin: margin,
      onTap: onTap,
      child: child,
    );
  }
}

class FrostedSection extends StatelessWidget {
  const FrostedSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title, subtitle: subtitle, trailing: trailing),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class GradientIconBox extends StatelessWidget {
  const GradientIconBox({
    super.key,
    required this.icon,
    this.size = 44,
    this.color,
  });

  final IconData icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final base = color ?? colorScheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.38),
        gradient: LinearGradient(
          colors: [
            base.withValues(alpha: 0.28),
            colorScheme.tertiary.withValues(alpha: 0.16),
          ],
        ),
        border: Border.all(color: base.withValues(alpha: 0.18)),
      ),
      child: Icon(icon, color: base, size: size * 0.48),
    );
  }
}

class PremiumButton extends StatelessWidget {
  const PremiumButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [Icon(icon), const SizedBox(width: 8), Text(label)],
          );
    return AnimatedPressable(
      onTap: onPressed,
      child: FilledButton(onPressed: onPressed, child: child),
    );
  }
}

class PremiumSearchBar extends StatelessWidget {
  const PremiumSearchBar({
    super.key,
    required this.hintText,
    required this.onChanged,
  });

  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      hintText: hintText,
      leading: const Icon(Icons.search_rounded),
      onChanged: onChanged,
    );
  }
}

class SoftStatCard extends StatelessWidget {
  const SoftStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LiquidGlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientIconBox(icon: icon, size: 36),
          const SizedBox(height: 12),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          Text(
            label,
            style: TextStyle(
              color: colorScheme.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyStateCard extends EmptyState {
  const EmptyStateCard({
    super.key,
    required super.title,
    required super.message,
    super.action,
    super.icon,
  });
}

class ErrorStateCard extends EmptyState {
  const ErrorStateCard({
    super.key,
    required super.title,
    required super.message,
    super.action,
  }) : super(icon: Icons.warning_amber_rounded);
}

class SectionTitle extends SectionHeader {
  const SectionTitle({
    super.key,
    required super.title,
    super.subtitle,
    super.trailing,
  });
}

class AnimatedPageHeader extends StatelessWidget {
  const AnimatedPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - value)),
          child: child,
        ),
      ),
      child: SectionHeader(
        title: title,
        subtitle: subtitle,
        trailing: trailing,
      ),
    );
  }
}
