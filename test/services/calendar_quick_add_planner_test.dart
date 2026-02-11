import 'package:flutter_test/flutter_test.dart';
import 'package:focus/services/calendar_quick_add_planner.dart';

void main() {
  test('rounds start time to next 15-minute slot', () {
    final start = CalendarQuickAddPlanner.nextQuarterHour(
      DateTime(2026, 2, 10, 10, 7),
    );
    expect(start, DateTime(2026, 2, 10, 10, 15));
  });

  test('moves to next hour when already on :45+', () {
    final start = CalendarQuickAddPlanner.nextQuarterHour(
      DateTime(2026, 2, 10, 10, 49),
    );
    expect(start, DateTime(2026, 2, 10, 11, 0));
  });

  test('computes duration from pomodoro count and focus minutes', () {
    final duration = CalendarQuickAddPlanner.computeDurationMinutes(
      pomodoroCount: 3,
      focusMinutes: 25,
    );
    expect(duration, 75);
  });

  test('applies minimum event duration of 15 minutes', () {
    final duration = CalendarQuickAddPlanner.computeDurationMinutes(
      pomodoroCount: 1,
      focusMinutes: 5,
    );
    expect(duration, 15);
  });

  test('builds sequential slots for a task plan', () {
    final slots = CalendarQuickAddPlanner.buildSequentialSlots(
      from: DateTime(2026, 2, 10, 10, 7),
      durationsInMinutes: const [25, 50],
    );

    expect(slots.length, 2);
    expect(slots[0].start, DateTime(2026, 2, 10, 10, 15));
    expect(slots[0].end, DateTime(2026, 2, 10, 10, 40));
    expect(slots[1].start, DateTime(2026, 2, 10, 10, 45));
    expect(slots[1].end, DateTime(2026, 2, 10, 11, 35));
  });
}
