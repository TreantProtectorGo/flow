import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _flushMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  test(
    'settings defaults enable vibration and task reminder defaults',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      await _flushMicrotasks();

      final AppSettings settings = container.read(settingsProvider);
      expect(settings.vibration, isTrue);
      expect(settings.defaultTaskReminderEnabled, isTrue);
      expect(settings.defaultTaskReminderTime, equals('09:00'));
    },
  );
}
