import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../services/database_helper.dart';

/// Data migration helper: migrate from SharedPreferences to SQLite
class DataMigrationHelper {
  static final DatabaseHelper _db = DatabaseHelper.instance;

  /// Check if migration is needed
  static Future<bool> needsMigration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Check if old data exists and not marked as migrated
      final hasOldData = prefs.getStringList('tasks') != null;
      final alreadyMigrated = prefs.getBool('data_migrated_to_sqlite') ?? false;

      return hasOldData && !alreadyMigrated;
    } catch (e) {
      debugPrint('Error checking migration status: $e');
      return false;
    }
  }

  /// Perform data migration
  static Future<void> migrate() async {
    try {
      debugPrint('🔄 Starting data migration...');

      final prefs = await SharedPreferences.getInstance();
      final tasksJson = prefs.getStringList('tasks') ?? [];

      if (tasksJson.isEmpty) {
        debugPrint('✅ No data to migrate');
        await _markAsMigrated();
        return;
      }

      debugPrint('📦 Found ${tasksJson.length} tasks to migrate');

      // Parse tasks
      final tasks = tasksJson
          .map((taskString) {
            try {
              return Task.fromJson(jsonDecode(taskString));
            } catch (e) {
              debugPrint('❌ Failed to parse task: $e');
              return null;
            }
          })
          .whereType<Task>()
          .toList();

      // Migrate to SQLite
      int successCount = 0;
      for (final task in tasks) {
        try {
          await _db.insertTask(task);
          successCount++;
        } catch (e) {
          debugPrint('❌ Failed to migrate task [${task.title}]: $e');
        }
      }

      debugPrint(
        '✅ Successfully migrated $successCount / ${tasks.length} tasks',
      );

      // Mark as migrated
      await _markAsMigrated();

      // Keep old data as backup (not deleted, just in case)
      debugPrint('💾 Keep old data as backup in SharedPreferences');

      debugPrint('🎉 Data migration completed!');
    } catch (e) {
      debugPrint('❌ Data migration failed: $e');
      rethrow;
    }
  }

  /// Mark as migrated
  static Future<void> _markAsMigrated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('data_migrated_to_sqlite', true);
    await prefs.setString('migration_date', DateTime.now().toIso8601String());
  }

  /// Clear old data (optional, use only after confirming successful migration)
  static Future<void> cleanupOldData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('tasks');
      debugPrint('🗑️ Removed old task data from SharedPreferences');
    } catch (e) {
      debugPrint('❌ Failed to clean up old data: $e');
    }
  }

  /// Get migration info
  static Future<Map<String, dynamic>> getMigrationInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final migrated = prefs.getBool('data_migrated_to_sqlite') ?? false;
      final migrationDate = prefs.getString('migration_date');
      final oldTasksCount = (prefs.getStringList('tasks') ?? []).length;

      // Get task count from SQLite
      final sqliteTasks = await _db.getAllTasks();

      return {
        'migrated': migrated,
        'migration_date': migrationDate,
        'old_tasks_count': oldTasksCount,
        'sqlite_tasks_count': sqliteTasks.length,
      };
    } catch (e) {
      debugPrint('❌ Failed to get migration info: $e');
      return {'migrated': false, 'error': e.toString()};
    }
  }
}
