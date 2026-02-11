import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus/services/ios_calendar_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('focus/calendar');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('returns saved when native editor saves event', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'presentEventEditor');
          return 'saved';
        });

    final bridge = const IosCalendarBridge();
    final result = await bridge.presentEventEditor(
      title: 'Plan focus',
      description: 'Deep work',
      start: DateTime(2026, 2, 11, 10, 0),
      end: DateTime(2026, 2, 11, 11, 0),
    );

    expect(result, IosCalendarResult.saved);
  });

  test('returns canceled when native editor is canceled', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => 'canceled');

    final bridge = const IosCalendarBridge();
    final result = await bridge.presentEventEditor(
      title: 'Plan focus',
      description: 'Deep work',
      start: DateTime(2026, 2, 11, 10, 0),
      end: DateTime(2026, 2, 11, 11, 0),
    );

    expect(result, IosCalendarResult.canceled);
  });

  test('returns null for unsupported native result', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => 'unexpected');

    final bridge = const IosCalendarBridge();
    final result = await bridge.presentEventEditor(
      title: 'Plan focus',
      description: 'Deep work',
      start: DateTime(2026, 2, 11, 10, 0),
      end: DateTime(2026, 2, 11, 11, 0),
    );

    expect(result, isNull);
  });

  test('returns saved count for direct batch event save', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'saveEvents');
          final args = call.arguments as Map<Object?, Object?>;
          final events = args['events'] as List<Object?>;
          expect(events.length, 2);
          return 2;
        });

    final bridge = const IosCalendarBridge();
    final savedCount = await bridge.saveEvents(
      events: [
        IosCalendarDraftEvent(
          title: 'Task 1',
          description: 'Desc 1',
          start: DateTime(2026, 2, 11, 10, 0),
          end: DateTime(2026, 2, 11, 10, 30),
        ),
        IosCalendarDraftEvent(
          title: 'Task 2',
          description: 'Desc 2',
          start: DateTime(2026, 2, 11, 10, 35),
          end: DateTime(2026, 2, 11, 11, 0),
        ),
      ],
    );

    expect(savedCount, 2);
  });
}
