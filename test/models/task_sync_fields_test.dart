import 'package:flutter_test/flutter_test.dart';
import 'package:focus/models/task.dart';

void main() {
  group('Task model — sync fields', () {
    final now = DateTime(2026, 3, 6, 12, 0, 0);
    final later = DateTime(2026, 3, 6, 13, 0, 0);

    Task makeTask({DateTime? updatedAt, DateTime? deletedAt}) {
      return Task(
        id: '1',
        title: 'Test',
        pomodoroCount: 4,
        priority: TaskPriority.medium,
        status: TaskStatus.pending,
        createdAt: now,
        updatedAt: updatedAt,
        deletedAt: deletedAt,
      );
    }

    test('updatedAt defaults to createdAt when not provided', () {
      final task = makeTask();
      expect(task.updatedAt, equals(now));
    });

    test('updatedAt can be set explicitly', () {
      final task = makeTask(updatedAt: later);
      expect(task.updatedAt, equals(later));
    });

    test('deletedAt is null by default', () {
      final task = makeTask();
      expect(task.deletedAt, isNull);
    });

    test('deletedAt can be set', () {
      final task = makeTask(deletedAt: later);
      expect(task.deletedAt, equals(later));
    });

    test('copyWith preserves updatedAt and deletedAt', () {
      final task = makeTask(updatedAt: later, deletedAt: later);
      final copy = task.copyWith(title: 'Changed');
      expect(copy.title, 'Changed');
      expect(copy.updatedAt, equals(later));
      expect(copy.deletedAt, equals(later));
    });

    test('copyWith can override updatedAt and deletedAt', () {
      final task = makeTask();
      final evenLater = DateTime(2026, 3, 6, 14, 0, 0);
      final copy = task.copyWith(updatedAt: evenLater, deletedAt: evenLater);
      expect(copy.updatedAt, equals(evenLater));
      expect(copy.deletedAt, equals(evenLater));
    });

    test('toJson includes updatedAt and deletedAt', () {
      final task = makeTask(updatedAt: later, deletedAt: later);
      final json = task.toJson();
      expect(json['updatedAt'], equals(later.toIso8601String()));
      expect(json['deletedAt'], equals(later.toIso8601String()));
    });

    test('toJson has null deletedAt when not set', () {
      final task = makeTask();
      final json = task.toJson();
      expect(json['updatedAt'], equals(now.toIso8601String()));
      expect(json['deletedAt'], isNull);
    });

    test('fromJson parses updatedAt and deletedAt', () {
      final json = {
        'id': '1',
        'title': 'Test',
        'pomodoroCount': 4,
        'priority': 'medium',
        'status': 'pending',
        'createdAt': now.toIso8601String(),
        'updatedAt': later.toIso8601String(),
        'deletedAt': later.toIso8601String(),
      };
      final task = Task.fromJson(json);
      expect(task.updatedAt, equals(later));
      expect(task.deletedAt, equals(later));
    });

    test('fromJson handles missing updatedAt and deletedAt', () {
      final json = {
        'id': '1',
        'title': 'Test',
        'pomodoroCount': 4,
        'priority': 'medium',
        'status': 'pending',
        'createdAt': now.toIso8601String(),
      };
      final task = Task.fromJson(json);
      // updatedAt defaults to createdAt when null
      expect(task.updatedAt, equals(now));
      expect(task.deletedAt, isNull);
    });

    test('round-trip toJson/fromJson preserves all fields', () {
      final original = Task(
        id: '42',
        title: 'Round Trip',
        description: 'desc',
        pomodoroCount: 8,
        completedPomodoros: 3,
        priority: TaskPriority.high,
        status: TaskStatus.inProgress,
        createdAt: now,
        completedAt: later,
        isAIGenerated: true,
        aiSessionId: 'session1',
        aiSessionTitle: 'AI Plan',
        updatedAt: later,
        deletedAt: later,
        dailyReminderTime: '09:30',
      );
      final restored = Task.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.description, original.description);
      expect(restored.pomodoroCount, original.pomodoroCount);
      expect(restored.completedPomodoros, original.completedPomodoros);
      expect(restored.priority, original.priority);
      expect(restored.status, original.status);
      expect(restored.createdAt, original.createdAt);
      expect(restored.completedAt, original.completedAt);
      expect(restored.isAIGenerated, original.isAIGenerated);
      expect(restored.aiSessionId, original.aiSessionId);
      expect(restored.aiSessionTitle, original.aiSessionTitle);
      expect(restored.updatedAt, original.updatedAt);
      expect(restored.deletedAt, original.deletedAt);
      expect(restored.dailyReminderTime, original.dailyReminderTime);
    });

    test('toJson and fromJson preserve daily reminder time', () {
      final task = makeTask().copyWith(dailyReminderTime: '18:45');
      final json = task.toJson();

      expect(json['dailyReminderTime'], equals('18:45'));

      final restored = Task.fromJson(json);
      expect(restored.dailyReminderTime, equals('18:45'));
    });

    test('daily reminder time defaults to null when not provided', () {
      final task = makeTask();
      expect(task.dailyReminderTime, isNull);
    });
  });
}
