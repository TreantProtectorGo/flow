class CalendarTimeSlot {
  final DateTime start;
  final DateTime end;

  const CalendarTimeSlot({required this.start, required this.end});
}

class CalendarQuickAddPlanner {
  static DateTime nextQuarterHour(DateTime from) {
    final normalized = DateTime(
      from.year,
      from.month,
      from.day,
      from.hour,
      from.minute,
    );
    final remainder = normalized.minute % 15;
    final minutesToAdd = remainder == 0 ? 15 : 15 - remainder;
    return normalized.add(Duration(minutes: minutesToAdd));
  }

  static int computeDurationMinutes({
    required int pomodoroCount,
    required int focusMinutes,
  }) {
    final count = pomodoroCount <= 0 ? 1 : pomodoroCount;
    final focus = focusMinutes <= 0 ? 25 : focusMinutes;
    final total = count * focus;
    return total < 15 ? 15 : total;
  }

  static List<CalendarTimeSlot> buildSequentialSlots({
    required DateTime from,
    required List<int> durationsInMinutes,
    int gapBetweenEventsMinutes = 5,
  }) {
    final slots = <CalendarTimeSlot>[];
    var cursor = nextQuarterHour(from);

    for (final rawDuration in durationsInMinutes) {
      final duration = rawDuration <= 0 ? 15 : rawDuration;
      final end = cursor.add(Duration(minutes: duration));
      slots.add(CalendarTimeSlot(start: cursor, end: end));
      cursor = end.add(Duration(minutes: gapBetweenEventsMinutes));
    }

    return slots;
  }
}
