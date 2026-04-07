import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus/l10n/app_localizations.dart';
import 'package:focus/widgets/task_form_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'new task form defaults reminder to the configured task reminder time',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'settings_notifications': true,
        'settings_default_task_reminder_enabled': true,
        'settings_default_task_reminder_time': '09:30',
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: <LocalizationsDelegate<dynamic>>[
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: TaskFormDialog()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Reminder Time: 9:30'), findsOneWidget);
      final Switch reminderSwitch = tester.widget<Switch>(find.byType(Switch));
      expect(reminderSwitch.value, isTrue);
    },
  );

  testWidgets(
    'task form shows disabled reminder helper when notifications are off',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'settings_notifications': false,
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: <LocalizationsDelegate<dynamic>>[
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: TaskFormDialog()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Daily Reminder'), findsOneWidget);
      expect(
        find.text('Turn on push notifications to use task reminders'),
        findsOneWidget,
      );
    },
  );
}
