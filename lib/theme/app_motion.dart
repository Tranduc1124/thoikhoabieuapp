import 'package:flutter/animation.dart';

class AppMotion {
  const AppMotion._();

  static const Duration tap = Duration(milliseconds: 110);
  static const Duration instant = Duration(milliseconds: 80);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 520);
  static const Duration sheet = Duration(milliseconds: 380);

  static const Curve press = Curves.easeOut;
  static const Curve swift = Curves.easeOutCubic;
  static const Curve spring = Curves.easeOutBack;
  static const Curve liquid = Cubic(0.22, 1, 0.36, 1);
  static const Curve emphasized = Cubic(0.16, 1, 0.3, 1);
  static const Curve exit = Curves.easeInCubic;
}
