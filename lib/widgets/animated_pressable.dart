import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_motion.dart';

class AnimatedPressable extends StatefulWidget {
  const AnimatedPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.975,
    this.duration = AppMotion.tap,
    this.pressedOpacity = 0.88,
    this.enableHaptics = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final Duration duration;
  final double pressedOpacity;
  final bool enableHaptics;

  @override
  State<AnimatedPressable> createState() => _AnimatedPressableState();
}

class _AnimatedPressableState extends State<AnimatedPressable> {
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
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled
              ? () {
                  _setPressed(false);
                  widget.onTap?.call();
                }
              : null,
          onLongPress: enabled
              ? () {
                  _setPressed(false);
                  widget.onLongPress?.call();
                }
              : null,
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
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _hovered
                  ? colorScheme.primary.withValues(alpha: 0.035)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: AnimatedOpacity(
              opacity: _pressed ? widget.pressedOpacity : 1,
              duration: widget.duration,
              curve: AppMotion.press,
              child: AnimatedScale(
                scale: _pressed ? widget.scale : 1,
                duration: widget.duration,
                curve: AppMotion.press,
                child: AnimatedSlide(
                  offset: _pressed ? const Offset(0, 0.006) : Offset.zero,
                  duration: widget.duration,
                  curve: AppMotion.press,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }

  void _setHovered(bool value) {
    if (_hovered == value || !mounted) return;
    setState(() => _hovered = value);
  }
}
