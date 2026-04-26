import 'dart:math' as math;
import 'package:flutter/material.dart';

extension ColorExt on Color {
  int _clampToInt(num v) => math.max(0, math.min(255, v)).toInt();

  /// Returns a color with the given opacity without using the deprecated
  /// `.withOpacity` API. Opacity is a value between 0.0 and 1.0.
  Color withOpacitySafe(double opacity) {
    final a = _clampToInt((opacity * 255.0).round());
    final rr = _clampToInt((r * 255.0).round());
    final gg = _clampToInt((g * 255.0).round());
    final bb = _clampToInt((b * 255.0).round());
    return Color.fromARGB(a, rr, gg, bb);
  }
}
