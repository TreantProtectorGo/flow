import 'package:flutter_test/flutter_test.dart';
import 'package:focus/theme/m3_expressive.dart';

void main() {
  test('expressive durations are longer than standard motion', () {
    expect(M3ExpressiveMotion.short.inMilliseconds, greaterThan(150));
    expect(M3ExpressiveMotion.medium.inMilliseconds, greaterThan(300));
    expect(M3ExpressiveMotion.long.inMilliseconds, greaterThan(500));
  });

  test('duration selection respects reduced motion preference', () {
    expect(
      M3ExpressiveMotion.pickDuration(
        reducedMotion: true,
        normal: const Duration(milliseconds: 220),
        expressive: const Duration(milliseconds: 520),
      ),
      Duration.zero,
    );

    expect(
      M3ExpressiveMotion.pickDuration(
        reducedMotion: false,
        normal: const Duration(milliseconds: 220),
        expressive: const Duration(milliseconds: 520),
      ),
      const Duration(milliseconds: 520),
    );
  });
}
