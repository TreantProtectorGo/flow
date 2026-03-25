import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focus/l10n/app_localizations.dart';
import 'package:focus/widgets/stats_streak_card.dart';

void main() {
  Widget buildSubject({
    required int streakDays,
    required int todayCompleted,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: StatsStreakCard(
          streakDays: streakDays,
          todayCompleted: todayCompleted,
        ),
      ),
    );
  }

  testWidgets('shows sprout-style icon for zero streak without emoji', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildSubject(streakDays: 0, todayCompleted: 0));

    expect(find.byIcon(Icons.spa_rounded), findsOneWidget);
    expect(find.text('🌱'), findsNothing);
    expect(find.text('🔥'), findsNothing);
  });

  testWidgets('shows fire icon for active streak without emoji', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildSubject(streakDays: 3, todayCompleted: 1));

    expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);
    expect(find.text('🌱'), findsNothing);
    expect(find.text('🔥'), findsNothing);
  });
}
