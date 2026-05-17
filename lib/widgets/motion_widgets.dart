import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_motion.dart';

class MorphTransitionWidget extends StatelessWidget {
  const MorphTransitionWidget({
    super.key,
    required this.child,
    required this.animation,
    this.beginOffset = const Offset(0, 0.024),
    this.beginScale = 0.985,
    this.beginOpacity = 0.70,
  });

  final Widget child;
  final Animation<double> animation;
  final Offset beginOffset;
  final double beginScale;
  final double beginOpacity;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.liquid,
      reverseCurve: AppMotion.exit,
    );
    return FadeTransition(
      opacity: Tween<double>(begin: beginOpacity, end: 1).animate(curved),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        ).animate(curved),
        child: ScaleTransition(
          scale: Tween<double>(begin: beginScale, end: 1).animate(curved),
          child: child,
        ),
      ),
    );
  }
}

class ScheduleFadeWidget extends StatefulWidget {
  const ScheduleFadeWidget({
    super.key,
    required this.child,
    this.index = 0,
    this.enabled = true,
  });

  final Widget child;
  final int index;
  final bool enabled;

  @override
  State<ScheduleFadeWidget> createState() => _ScheduleFadeWidgetState();
}

class _ScheduleFadeWidgetState extends State<ScheduleFadeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curved;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.medium);
    _curved = CurvedAnimation(parent: _controller, curve: AppMotion.liquid);
    if (widget.enabled) {
      Future<void>.delayed(Duration(milliseconds: widget.index * 24), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant ScheduleFadeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      _controller
        ..duration = AppMotion.fast
        ..forward(from: widget.enabled ? 0.12 : 1);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _curved,
        child: widget.child,
        builder: (context, child) {
          final value = _curved.value.clamp(0.0, 1.0);
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 22 * (1 - value)),
              child: Transform.scale(
                scale: 0.965 + (0.035 * value),
                alignment: Alignment.topCenter,
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}

class AnimatedButton extends StatefulWidget {
  const AnimatedButton({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.scale = 0.965,
    this.pressedOpacity = 0.88,
    this.enableHaptics = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius borderRadius;
  final double scale;
  final double pressedOpacity;
  final bool enableHaptics;

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    final colorScheme = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: enabled ? (_) => _setHovered(true) : null,
      onExit: enabled ? (_) => _setHovered(false) : null,
      child: Semantics(
        button: true,
        enabled: enabled,
        child: AnimatedScale(
          scale: _pressed ? widget.scale : 1,
          duration: AppMotion.tap,
          curve: AppMotion.press,
          child: AnimatedOpacity(
            opacity: _pressed ? widget.pressedOpacity : 1,
            duration: AppMotion.tap,
            curve: AppMotion.press,
            child: Material(
              color: _hovered
                  ? colorScheme.primary.withValues(alpha: 0.035)
                  : Colors.transparent,
              borderRadius: widget.borderRadius,
              child: InkWell(
                borderRadius: widget.borderRadius,
                splashColor: colorScheme.primary.withValues(alpha: 0.10),
                highlightColor: colorScheme.primary.withValues(alpha: 0.05),
                hoverColor: colorScheme.primary.withValues(alpha: 0.04),
                onTapDown: enabled
                    ? (_) {
                        _setPressed(true);
                        if (widget.enableHaptics) {
                          HapticFeedback.selectionClick();
                        }
                      }
                    : null,
                onTapCancel: enabled ? () => _setPressed(false) : null,
                onTapUp: enabled ? (_) => _setPressed(false) : null,
                onTap: enabled ? widget.onTap : null,
                onLongPress: enabled ? widget.onLongPress : null,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _setPressed(bool value) {
    if (!mounted || _pressed == value) return;
    setState(() => _pressed = value);
  }

  void _setHovered(bool value) {
    if (!mounted || _hovered == value) return;
    setState(() => _hovered = value);
  }
}
