import 'package:flutter_test/flutter_test.dart';
import 'package:focus/services/calendar_service.dart';

void main() {
  const service = CalendarService();

  test('buildPlanPreview creates sequential calendar events', () {
    final events = service.buildPlanPreview(
      planTitle: 'Learn Flutter',
      entries: const [
        CalendarPlanEntry(
          title: 'Setup',
          description: 'Install SDK',
          pomodoroCount: 1,
        ),
        CalendarPlanEntry(
          title: 'Widgets',
          description: 'Build UI',
          pomodoroCount: 2,
        ),
      ],
      focusMinutes: 25,
      startFrom: DateTime(2026, 2, 11, 19, 22),
      scheduleMode: CalendarPlanScheduleMode.singleDay,
    );

    expect(events.length, 2);
    expect(events.first.title, '1/2 Setup');
    expect(events.last.title, '2/2 Widgets');
    expect(events.first.start, DateTime(2026, 2, 11, 19, 30));
    expect(events.first.end, DateTime(2026, 2, 11, 19, 55));
    expect(events.last.start, DateTime(2026, 2, 11, 20, 0));
    expect(events.last.end, DateTime(2026, 2, 11, 20, 50));
  });

  test('buildPlanPreview spreads events across days', () {
    final events = service.buildPlanPreview(
      planTitle: 'Learn Flutter in 5 Days',
      entries: const [
        CalendarPlanEntry(
          title: 'Day 1: Environment Setup',
          description: 'Install SDK',
          pomodoroCount: 1,
        ),
        CalendarPlanEntry(
          title: 'Day 2: Core Widgets',
          description: 'Build UI',
          pomodoroCount: 1,
        ),
        CalendarPlanEntry(
          title: 'Day 3: State Management',
          description: 'Provider basics',
          pomodoroCount: 1,
        ),
      ],
      focusMinutes: 25,
      startFrom: DateTime(2026, 2, 11, 18, 45),
      scheduleMode: CalendarPlanScheduleMode.spreadByDay,
      spreadDays: 5,
    );

    expect(events[0].start, DateTime(2026, 2, 11, 19, 0));
    expect(events[1].start, DateTime(2026, 2, 12, 19, 0));
    expect(events[2].start, DateTime(2026, 2, 13, 19, 0));
  });

  test('buildPlanExportFingerprint is stable and time-sensitive', () {
    const entries = [
      CalendarPlanEntry(
        title: 'Setup',
        description: 'Install SDK',
        pomodoroCount: 1,
      ),
    ];

    final fp1 = service.buildPlanExportFingerprint(
      planTitle: 'Learn Flutter',
      entries: entries,
      focusMinutes: 25,
      startFrom: DateTime(2026, 2, 11, 19, 30),
    );
    final fp2 = service.buildPlanExportFingerprint(
      planTitle: 'Learn Flutter',
      entries: entries,
      focusMinutes: 25,
      startFrom: DateTime(2026, 2, 11, 19, 30),
    );
    final fp3 = service.buildPlanExportFingerprint(
      planTitle: 'Learn Flutter',
      entries: entries,
      focusMinutes: 25,
      startFrom: DateTime(2026, 2, 11, 19, 45),
    );
    final fp4 = service.buildPlanExportFingerprint(
      planTitle: 'Learn Flutter',
      entries: entries,
      focusMinutes: 25,
      startFrom: DateTime(2026, 2, 11, 19, 30),
      scheduleMode: CalendarPlanScheduleMode.spreadByDay,
      spreadDays: 5,
    );

    expect(fp1, fp2);
    expect(fp1, isNot(fp3));
    expect(fp1, isNot(fp4));
  });
}
