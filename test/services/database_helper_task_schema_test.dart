import 'package:flutter_test/flutter_test.dart';
import 'package:focus/services/database_helper.dart';

void main() {
  group('buildMissingTaskSchemaStatements', () {
    test('adds reminder_time migration when reminder column is missing', () {
      final Set<String> existingColumns = <String>{
        'id',
        'title',
        'description',
        'pomodoro_count',
      };

      final List<String> statements = buildMissingTaskSchemaStatements(
        existingColumns,
      );

      expect(
        statements,
        contains('ALTER TABLE tasks ADD COLUMN reminder_time TEXT'),
      );
    });

    test('does not add reminder migration when reminder column exists', () {
      final Set<String> existingColumns = <String>{
        'id',
        'title',
        'description',
        'pomodoro_count',
        'reminder_time',
      };

      final List<String> statements = buildMissingTaskSchemaStatements(
        existingColumns,
      );

      expect(
        statements.where(
          (String statement) => statement.contains('reminder_time'),
        ),
        isEmpty,
      );
    });
  });
}
