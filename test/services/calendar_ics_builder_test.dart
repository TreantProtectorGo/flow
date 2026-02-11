import 'package:flutter_test/flutter_test.dart';
import 'package:focus/services/calendar_ics_builder.dart';

void main() {
  test('builds valid VCALENDAR payload', () {
    final ics = CalendarIcsBuilder.buildEventIcs(
      title: 'Write report',
      description: 'Deep work block',
      start: DateTime.utc(2026, 2, 10, 9, 0),
      end: DateTime.utc(2026, 2, 10, 10, 0),
    );

    expect(ics, contains('BEGIN:VCALENDAR'));
    expect(ics, contains('VERSION:2.0'));
    expect(ics, contains('BEGIN:VEVENT'));
    expect(ics, contains('SUMMARY:Write report'));
    expect(ics, contains('DESCRIPTION:Deep work block'));
    expect(ics, contains('DTSTART:20260210T090000Z'));
    expect(ics, contains('DTEND:20260210T100000Z'));
    expect(ics, contains('END:VEVENT'));
    expect(ics, contains('END:VCALENDAR'));
  });

  test('escapes special characters for ICS text fields', () {
    final ics = CalendarIcsBuilder.buildEventIcs(
      title: 'A,B;C',
      description: 'Line1\nLine2',
      start: DateTime.utc(2026, 2, 10, 9, 0),
      end: DateTime.utc(2026, 2, 10, 10, 0),
    );

    expect(ics, contains(r'SUMMARY:A\,B\;C'));
    expect(ics, contains(r'DESCRIPTION:Line1\nLine2'));
  });

  test('builds multiple VEVENT entries in one calendar file', () {
    final ics = CalendarIcsBuilder.buildCalendarIcs(
      events: [
        CalendarIcsEvent(
          title: 'Task A',
          description: 'First',
          start: DateTime.utc(2026, 2, 10, 9, 0),
          end: DateTime.utc(2026, 2, 10, 9, 30),
        ),
        CalendarIcsEvent(
          title: 'Task B',
          description: 'Second',
          start: DateTime.utc(2026, 2, 10, 10, 0),
          end: DateTime.utc(2026, 2, 10, 10, 45),
        ),
      ],
    );

    expect('BEGIN:VEVENT'.allMatches(ics).length, 2);
    expect(ics, contains('SUMMARY:Task A'));
    expect(ics, contains('SUMMARY:Task B'));
    expect(ics, contains('END:VCALENDAR'));
  });
}
