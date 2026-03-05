import 'package:flutter_test/flutter_test.dart';
import 'package:focus/utils/pomodoro_time_utils.dart';

void main() {
  test('returns 0 when totalPomodoros is 0', () {
    expect(
      calculateEstimatedMinutes(
        totalPomodoros: 0,
        focusMinutes: 25,
        shortBreakMinutes: 5,
        longBreakMinutes: 15,
        longBreakFrequency: 4,
      ),
      0,
    );
  });

  test('returns 25 for 1 pomodoro with default settings', () {
    expect(
      calculateEstimatedMinutes(
        totalPomodoros: 1,
        focusMinutes: 25,
        shortBreakMinutes: 5,
        longBreakMinutes: 15,
        longBreakFrequency: 4,
      ),
      25,
    );
  });

  test('returns 55 for 2 pomodoros with default settings', () {
    expect(
      calculateEstimatedMinutes(
        totalPomodoros: 2,
        focusMinutes: 25,
        shortBreakMinutes: 5,
        longBreakMinutes: 15,
        longBreakFrequency: 4,
      ),
      55,
    );
  });

  test('returns 115 for 4 pomodoros with default settings', () {
    // Breaks at positions 1,2,3 — all short (none divisible by 4)
    // 4*25 + 3*5 = 115
    expect(
      calculateEstimatedMinutes(
        totalPomodoros: 4,
        focusMinutes: 25,
        shortBreakMinutes: 5,
        longBreakMinutes: 15,
        longBreakFrequency: 4,
      ),
      115,
    );
  });

  test('returns 155 for 5 pomodoros with default settings', () {
    // Breaks at positions 1,2,3,4 — position 4 is long
    // 5*25 + 3*5 + 1*15 = 155
    expect(
      calculateEstimatedMinutes(
        totalPomodoros: 5,
        focusMinutes: 25,
        shortBreakMinutes: 5,
        longBreakMinutes: 15,
        longBreakFrequency: 4,
      ),
      155,
    );
  });

  test('returns 245 for 8 pomodoros with default settings', () {
    // Breaks at positions 1..7 — position 4 is long
    // 8*25 + 6*5 + 1*15 = 245
    expect(
      calculateEstimatedMinutes(
        totalPomodoros: 8,
        focusMinutes: 25,
        shortBreakMinutes: 5,
        longBreakMinutes: 15,
        longBreakFrequency: 4,
      ),
      245,
    );
  });

  test('returns 285 for 9 pomodoros with default settings', () {
    // Breaks at positions 1..8 — positions 4,8 are long
    // 9*25 + 6*5 + 2*15 = 285
    expect(
      calculateEstimatedMinutes(
        totalPomodoros: 9,
        focusMinutes: 25,
        shortBreakMinutes: 5,
        longBreakMinutes: 15,
        longBreakFrequency: 4,
      ),
      285,
    );
  });

  test('uses custom settings for 2 pomodoros', () {
    // 2*50 + 1 break at position 1 (1%2≠0 → short 10) = 110
    expect(
      calculateEstimatedMinutes(
        totalPomodoros: 2,
        focusMinutes: 50,
        shortBreakMinutes: 10,
        longBreakMinutes: 20,
        longBreakFrequency: 2,
      ),
      110,
    );
  });

  test('returns 0 when totalPomodoros is negative', () {
    expect(
      calculateEstimatedMinutes(
        totalPomodoros: -2,
        focusMinutes: 25,
        shortBreakMinutes: 5,
        longBreakMinutes: 15,
        longBreakFrequency: 4,
      ),
      0,
    );
  });

  test('normalizes longBreakFrequency 0 to 4', () {
    expect(
      calculateEstimatedMinutes(
        totalPomodoros: 4,
        focusMinutes: 25,
        shortBreakMinutes: 5,
        longBreakMinutes: 15,
        longBreakFrequency: 0,
      ),
      115,
    );
  });

  test('uses long break for every break when frequency is 1', () {
    // 3*25 + breaks at 1,2: both divisible by 1 → long
    // 75 + 2*15 = 105
    expect(
      calculateEstimatedMinutes(
        totalPomodoros: 3,
        focusMinutes: 25,
        shortBreakMinutes: 5,
        longBreakMinutes: 15,
        longBreakFrequency: 1,
      ),
      105,
    );
  });
}
