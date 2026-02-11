import 'package:flutter/services.dart';

enum IosCalendarResult { saved, canceled }

class IosCalendarDraftEvent {
  final String title;
  final String description;
  final DateTime start;
  final DateTime end;

  const IosCalendarDraftEvent({
    required this.title,
    required this.description,
    required this.start,
    required this.end,
  });

  Map<String, Object> toMap() {
    return {
      'title': title,
      'description': description,
      'startMillis': start.millisecondsSinceEpoch,
      'endMillis': end.millisecondsSinceEpoch,
    };
  }
}

class IosCalendarBridge {
  static const MethodChannel _channel = MethodChannel('focus/calendar');

  const IosCalendarBridge();

  Future<IosCalendarResult?> presentEventEditor({
    required String title,
    required String description,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final raw = await _channel.invokeMethod<String>('presentEventEditor', {
        'title': title,
        'description': description,
        'startMillis': start.millisecondsSinceEpoch,
        'endMillis': end.millisecondsSinceEpoch,
      });
      return _parseResult(raw);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  IosCalendarResult? _parseResult(String? value) {
    switch (value) {
      case 'saved':
        return IosCalendarResult.saved;
      case 'canceled':
        return IosCalendarResult.canceled;
      default:
        return null;
    }
  }

  Future<int?> saveEvents({required List<IosCalendarDraftEvent> events}) async {
    try {
      return await _channel.invokeMethod<int>('saveEvents', {
        'events': events.map((event) => event.toMap()).toList(),
      });
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
