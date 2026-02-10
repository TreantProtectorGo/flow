import 'package:flutter/animation.dart';

/// Motion tokens tuned for selective M3 Expressive moments.
class M3ExpressiveMotion {
  const M3ExpressiveMotion._();

  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);
  static const Curve emphasizedAccelerate = Cubic(0.3, 0.0, 0.8, 0.15);
  static const Curve emphasizedStandard = Cubic(0.2, 0.0, 0.0, 1.0);

  static const Duration short = Duration(milliseconds: 220);
  static const Duration medium = Duration(milliseconds: 420);
  static const Duration long = Duration(milliseconds: 620);

  static Duration pickDuration({
    required bool reducedMotion,
    required Duration normal,
    required Duration expressive,
  }) {
    if (reducedMotion) {
      return Duration.zero;
    }
    return expressive;
  }
}
