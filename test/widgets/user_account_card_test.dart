import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus/l10n/app_localizations.dart';
import 'package:focus/widgets/user_account_card.dart';

Widget _buildApp({required TargetPlatform platform}) {
  return ProviderScope(
    child: MaterialApp(
      theme: ThemeData(useMaterial3: true, platform: platform),
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: UserAccountCard()),
    ),
  );
}

void main() {
  testWidgets(
    'shows Apple sign-in button on iOS',
    (WidgetTester tester) async {
      await tester.pumpWidget(_buildApp(platform: TargetPlatform.iOS));
      await tester.pumpAndSettle();

      expect(find.text('Sign in with Apple'), findsOneWidget);
    },
  );

  testWidgets(
    'does not show Apple sign-in button on Android',
    (WidgetTester tester) async {
      await tester.pumpWidget(_buildApp(platform: TargetPlatform.android));
      await tester.pumpAndSettle();

      expect(find.text('Sign in with Apple'), findsNothing);
    },
  );
}
