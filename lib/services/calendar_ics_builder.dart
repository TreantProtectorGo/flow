class CalendarIcsEvent {
  final String title;
  final String description;
  final DateTime start;
  final DateTime end;

  const CalendarIcsEvent({
    required this.title,
    required this.description,
    required this.start,
    required this.end,
  });
}

class CalendarIcsBuilder {
  static String buildEventIcs({
    required String title,
    required String description,
    required DateTime start,
    required DateTime end,
  }) {
    return buildCalendarIcs(
      events: [
        CalendarIcsEvent(
          title: title,
          description: description,
          start: start,
          end: end,
        ),
      ],
    );
  }

  static String buildCalendarIcs({required List<CalendarIcsEvent> events}) {
    final nowUtc = DateTime.now().toUtc();
    final lines = <String>[
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//Focus App//Task Calendar//EN',
      'CALSCALE:GREGORIAN',
    ];

    for (var i = 0; i < events.length; i++) {
      final event = events[i];
      final startUtc = event.start.toUtc();
      final endUtc = event.end.toUtc();
      lines.addAll([
        'BEGIN:VEVENT',
        'UID:${nowUtc.microsecondsSinceEpoch}-$i@focus.app',
        'DTSTAMP:${_icsDateTime(nowUtc)}',
        'DTSTART:${_icsDateTime(startUtc)}',
        'DTEND:${_icsDateTime(endUtc)}',
        'SUMMARY:${_escapeText(event.title)}',
        'DESCRIPTION:${_escapeText(event.description)}',
        'END:VEVENT',
      ]);
    }

    lines.addAll(['END:VCALENDAR', '']);
    return lines.join('\r\n');
  }

  static String _icsDateTime(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$y$m${d}T$h$min${s}Z';
  }

  static String _escapeText(String input) {
    return input
        .replaceAll(r'\', r'\\')
        .replaceAll('\n', r'\n')
        .replaceAll(',', r'\,')
        .replaceAll(';', r'\;');
  }
}
