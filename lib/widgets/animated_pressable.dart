import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_motion.dart';

class AnimatedPressable extends StatefulWidget {
  const AnimatedPressable({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.975,
    this.duration = AppMotion.fast,
    this.enableHaptics = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final Duration duration;
  final bool enableHaptics;

  @override
  State<AnimatedPressable> createState() => _AnimatedPressableState();
}

class _AnimatedPressableState extends State<AnimatedPressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.enableHaptics) {
                HapticFeedback.lightImpact();
              }
              widget.onTap?.call();
            },
      onTapDown: widget.onTap == null
          ? null
          : (_) => setState(() => _pressed = true),
      onTapCancel: widget.onTap == null
          ? null
          : () => setState(() => _pressed = false),
      onTapUp: widget.onTap == null
          ? null
          : (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: widget.duration,
        curve: AppMotion.liquid,
        child: AnimatedSlide(
          offset: _pressed ? const Offset(0, 0.01) : Offset.zero,
          duration: widget.duration,
          curve: AppMotion.liquid,
          child: widget.child,
        ),
      ),
    );
  }
}
