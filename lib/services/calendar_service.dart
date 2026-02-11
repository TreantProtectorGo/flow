import 'dart:io';

import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import 'calendar_ics_builder.dart';
import 'calendar_quick_add_planner.dart';
import 'ios_calendar_bridge.dart';

enum CalendarAddResult { saved, opened, canceled, duplicate, failed }

enum CalendarPlanScheduleMode { singleDay, spreadByDay }

class CalendarPlanEntry {
  final String title;
  final String description;
  final int pomodoroCount;

  const CalendarPlanEntry({
    required this.title,
    required this.description,
    required this.pomodoroCount,
  });
}

class CalendarPlanPreviewEvent {
  final int index;
  final int total;
  final String title;
  final String description;
  final DateTime start;
  final DateTime end;

  const CalendarPlanPreviewEvent({
    required this.index,
    required this.total,
    required this.title,
    required this.description,
    required this.start,
    required this.end,
  });
}

class CalendarService {
  static const String _planExportCacheKey =
      'calendar_plan_export_fingerprints_v1';
  static const int _planExportCacheLimit = 200;

  const CalendarService({
    IosCalendarBridge iosCalendarBridge = const IosCalendarBridge(),
  }) : _iosCalendarBridge = iosCalendarBridge;

  final IosCalendarBridge _iosCalendarBridge;

  Future<CalendarAddResult> quickAddTask(
    Task task, {
    required int focusMinutes,
    DateTime? now,
  }) async {
    return quickAddCustom(
      title: task.title,
      description: task.description,
      pomodoroCount: task.pomodoroCount,
      focusMinutes: focusMinutes,
      now: now,
    );
  }

  Future<CalendarAddResult> quickAddCustom({
    required String title,
    String? description,
    required int pomodoroCount,
    required int focusMinutes,
    DateTime? now,
  }) async {
    final start = CalendarQuickAddPlanner.nextQuarterHour(
      now ?? DateTime.now(),
    );
    final durationMinutes = CalendarQuickAddPlanner.computeDurationMinutes(
      pomodoroCount: pomodoroCount,
      focusMinutes: focusMinutes,
    );
    final end = start.add(Duration(minutes: durationMinutes));

    final details = StringBuffer()
      ..writeln('Pomodoros: $pomodoroCount')
      ..writeln('Estimated focus: $durationMinutes min');

    if (description != null && description.trim().isNotEmpty) {
      details
        ..writeln()
        ..writeln(description.trim());
    }

    final event = Event(
      title: title,
      description: details.toString(),
      startDate: start,
      endDate: end,
      allDay: false,
    );

    if (Platform.isAndroid) {
      final opened = await Add2Calendar.addEvent2Cal(event);
      return opened ? CalendarAddResult.opened : CalendarAddResult.failed;
    }

    if (Platform.isIOS) {
      try {
        final iosResult = await _iosCalendarBridge.presentEventEditor(
          title: title,
          description: details.toString(),
          start: start,
          end: end,
        );
        if (iosResult == IosCalendarResult.saved) {
          return CalendarAddResult.saved;
        }
        if (iosResult == IosCalendarResult.canceled) {
          return CalendarAddResult.canceled;
        }
      } catch (_) {
        // Fall through to plugin + ICS fallback below.
      }

      try {
        final opened = await Add2Calendar.addEvent2Cal(
          event,
        ).timeout(const Duration(seconds: 2));
        if (opened) {
          return CalendarAddResult.opened;
        }
      } catch (_) {
        // Fall through to ICS fallback below.
      }
    }

    final opened = await _openIcsEvent(
      title: title,
      description: details.toString(),
      start: start,
      end: end,
    );
    return opened ? CalendarAddResult.opened : CalendarAddResult.failed;
  }

  Future<CalendarAddResult> quickAddPlanEntries({
    required String planTitle,
    required List<CalendarPlanEntry> entries,
    required int focusMinutes,
    required DateTime startFrom,
    CalendarPlanScheduleMode scheduleMode = CalendarPlanScheduleMode.singleDay,
    int spreadDays = 1,
    String? exportFingerprint,
  }) async {
    if (entries.isEmpty) {
      return CalendarAddResult.failed;
    }

    if (exportFingerprint != null &&
        await _hasExportFingerprint(exportFingerprint)) {
      return CalendarAddResult.duplicate;
    }

    final previewEvents = buildPlanPreview(
      planTitle: planTitle,
      entries: entries,
      focusMinutes: focusMinutes,
      startFrom: startFrom,
      scheduleMode: scheduleMode,
      spreadDays: spreadDays,
    );

    if (Platform.isIOS) {
      final iosEvents = <IosCalendarDraftEvent>[];
      for (final previewEvent in previewEvents) {
        iosEvents.add(
          IosCalendarDraftEvent(
            title: previewEvent.title,
            description: previewEvent.description,
            start: previewEvent.start,
            end: previewEvent.end,
          ),
        );
      }

      final savedCount = await _iosCalendarBridge.saveEvents(events: iosEvents);
      if (savedCount != null) {
        if (savedCount > 0) {
          if (exportFingerprint != null) {
            await _rememberExportFingerprint(exportFingerprint);
          }
          return CalendarAddResult.saved;
        }
        return CalendarAddResult.failed;
      }
    }

    final events = <CalendarIcsEvent>[];
    for (final previewEvent in previewEvents) {
      events.add(
        CalendarIcsEvent(
          title: previewEvent.title,
          description: previewEvent.description,
          start: previewEvent.start,
          end: previewEvent.end,
        ),
      );
    }
    final ics = CalendarIcsBuilder.buildCalendarIcs(events: events);
    final opened = await _openIcs(ics);
    if (opened && exportFingerprint != null) {
      await _rememberExportFingerprint(exportFingerprint);
    }
    return opened ? CalendarAddResult.opened : CalendarAddResult.failed;
  }

  List<CalendarPlanPreviewEvent> buildPlanPreview({
    required String planTitle,
    required List<CalendarPlanEntry> entries,
    required int focusMinutes,
    required DateTime startFrom,
    CalendarPlanScheduleMode scheduleMode = CalendarPlanScheduleMode.singleDay,
    int spreadDays = 1,
  }) {
    if (scheduleMode == CalendarPlanScheduleMode.singleDay) {
      final durations = entries
          .map(
            (entry) => CalendarQuickAddPlanner.computeDurationMinutes(
              pomodoroCount: entry.pomodoroCount,
              focusMinutes: focusMinutes,
            ),
          )
          .toList();
      final slots = CalendarQuickAddPlanner.buildSequentialSlots(
        from: startFrom,
        durationsInMinutes: durations,
      );

      return List<CalendarPlanPreviewEvent>.generate(entries.length, (index) {
        final entry = entries[index];
        final slot = slots[index];
        return CalendarPlanPreviewEvent(
          index: index + 1,
          total: entries.length,
          title: '${index + 1}/${entries.length} ${entry.title}',
          description: 'Plan: $planTitle\n\n${entry.description}',
          start: slot.start,
          end: slot.end,
        );
      });
    }

    final dayCount = spreadDays < 1 ? 1 : spreadDays;
    final eventsPerDay = (entries.length / dayCount).ceil();
    final cursorsByDay = <int, DateTime>{};
    final events = <CalendarPlanPreviewEvent>[];

    for (var index = 0; index < entries.length; index++) {
      final entry = entries[index];
      final hintedDay = _parseDayNumber(entry.title);
      final fallbackOffset = index ~/ eventsPerDay;
      final dayOffset =
          (((hintedDay ?? (fallbackOffset + 1)) - 1).clamp(0, dayCount - 1)
                  as num)
              .toInt();
      final dayStart = DateTime(
        startFrom.year,
        startFrom.month,
        startFrom.day + dayOffset,
        startFrom.hour,
        startFrom.minute,
      );
      final startCursor =
          cursorsByDay[dayOffset] ??
          CalendarQuickAddPlanner.nextQuarterHour(dayStart);
      final duration = CalendarQuickAddPlanner.computeDurationMinutes(
        pomodoroCount: entry.pomodoroCount,
        focusMinutes: focusMinutes,
      );
      final end = startCursor.add(Duration(minutes: duration));
      cursorsByDay[dayOffset] = end.add(const Duration(minutes: 5));

      events.add(
        CalendarPlanPreviewEvent(
          index: index + 1,
          total: entries.length,
          title: '${index + 1}/${entries.length} ${entry.title}',
          description: 'Plan: $planTitle\n\n${entry.description}',
          start: startCursor,
          end: end,
        ),
      );
    }

    return events;
  }

  String buildPlanExportFingerprint({
    required String planTitle,
    required List<CalendarPlanEntry> entries,
    required int focusMinutes,
    required DateTime startFrom,
    CalendarPlanScheduleMode scheduleMode = CalendarPlanScheduleMode.singleDay,
    int spreadDays = 1,
  }) {
    final buffer = StringBuffer()
      ..write(planTitle.trim())
      ..write('|')
      ..write(focusMinutes)
      ..write('|')
      ..write(startFrom.toIso8601String())
      ..write('|')
      ..write(scheduleMode.name)
      ..write('|')
      ..write(spreadDays);
    for (final entry in entries) {
      buffer
        ..write('|')
        ..write(entry.title.trim())
        ..write('|')
        ..write(entry.pomodoroCount);
    }
    return _stableHash(buffer.toString());
  }

  Future<bool> _openIcsEvent({
    required String title,
    required String description,
    required DateTime start,
    required DateTime end,
  }) async {
    final ics = CalendarIcsBuilder.buildEventIcs(
      title: title,
      description: description,
      start: start,
      end: end,
    );
    return _openIcs(ics);
  }

  Future<bool> _openIcs(String ics) async {
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/focus-task-${DateTime.now().millisecondsSinceEpoch}.ics';
    final file = File(path);
    await file.writeAsString(ics, flush: true);
    final result = await OpenFilex.open(file.path);
    return result.type == ResultType.done;
  }

  Future<bool> _hasExportFingerprint(String fingerprint) async {
    final prefs = await SharedPreferences.getInstance();
    final existing =
        prefs.getStringList(_planExportCacheKey) ?? const <String>[];
    return existing.contains(fingerprint);
  }

  Future<void> _rememberExportFingerprint(String fingerprint) async {
    final prefs = await SharedPreferences.getInstance();
    final existing =
        prefs.getStringList(_planExportCacheKey) ?? const <String>[];
    if (existing.contains(fingerprint)) {
      return;
    }
    final updated = <String>[...existing, fingerprint];
    if (updated.length > _planExportCacheLimit) {
      updated.removeRange(0, updated.length - _planExportCacheLimit);
    }
    await prefs.setStringList(_planExportCacheKey, updated);
  }

  String _stableHash(String value) {
    var hash = 2166136261;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 16777619) & 0xffffffff;
    }
    return hash.toRadixString(16);
  }

  int? _parseDayNumber(String text) {
    final match = RegExp(
      r'\bday\s*(\d{1,2})\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (match == null) {
      return null;
    }
    return int.tryParse(match.group(1)!);
  }
}
