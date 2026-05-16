import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_motion.dart';

class AnimatedPressable extends StatefulWidget {
  const AnimatedPressable({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.975,
    this.duration = AppMotion.tap,
    this.pressedOpacity = 0.88,
    this.enableHaptics = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final Duration duration;
  final double pressedOpacity;
  final bool enableHaptics;

  @override
  State<AnimatedPressable> createState() => _AnimatedPressableState();
}

class _AnimatedPressableState extends State<AnimatedPressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled
            ? () {
                _setPressed(false);
                if (widget.enableHaptics) {
                  HapticFeedback.selectionClick();
                }
                widget.onTap?.call();
              }
            : null,
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapCancel: enabled ? () => _setPressed(false) : null,
        onTapUp: enabled ? (_) => _setPressed(false) : null,
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
    );
  }

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }
}
