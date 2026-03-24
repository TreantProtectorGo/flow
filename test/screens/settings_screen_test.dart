import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus/l10n/app_localizations.dart';
import 'package:focus/providers/statistics_provider.dart';
import 'package:focus/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeStatisticsNotifier extends StatisticsNotifier {
  @override
  Future<void> loadStatistics() async {}
}

void main() {
  testWidgets(
    'Settings screen shows privacy policy entry',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            statisticsProvider.overrideWith(
              (Ref ref) => _FakeStatisticsNotifier(),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Privacy Policy'), findsOneWidget);
    },
  );
}
