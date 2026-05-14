import 'package:flutter/animation.dart';

class AppMotion {
  const AppMotion._();

  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 520);

  static const Curve swift = Curves.easeOutCubic;
  static const Curve spring = Curves.easeOutBack;
  static const Curve liquid = Cubic(0.22, 1, 0.36, 1);
}
