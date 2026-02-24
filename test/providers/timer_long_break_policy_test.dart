import 'package:flutter_test/flutter_test.dart';
import 'package:focus/providers/timer_provider.dart';

void main() {
  group('shouldTakeLongBreak', () {
    test('returns true when completed sessions hits frequency boundary', () {
      expect(
        shouldTakeLongBreak(completedSessions: 4, longBreakFrequency: 4),
        isTrue,
      );
      expect(
        shouldTakeLongBreak(completedSessions: 8, longBreakFrequency: 4),
        isTrue,
      );
      expect(
        shouldTakeLongBreak(completedSessions: 6, longBreakFrequency: 3),
        isTrue,
      );
    });

    test('returns false when completed sessions has not reached boundary', () {
      expect(
        shouldTakeLongBreak(completedSessions: 1, longBreakFrequency: 4),
        isFalse,
      );
      expect(
        shouldTakeLongBreak(completedSessions: 3, longBreakFrequency: 4),
        isFalse,
      );
      expect(
        shouldTakeLongBreak(completedSessions: 5, longBreakFrequency: 3),
        isFalse,
      );
    });

    test('sanitizes invalid frequency values to avoid divide-by-zero', () {
      expect(
        shouldTakeLongBreak(completedSessions: 4, longBreakFrequency: 0),
        isTrue,
      );
      expect(
        shouldTakeLongBreak(completedSessions: 1, longBreakFrequency: -1),
        isFalse,
      );
    });
  });
}
