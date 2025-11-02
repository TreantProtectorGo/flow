import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../services/database_helper.dart';

/// 資料遷移工具：從 SharedPreferences 遷移到 SQLite
class DataMigrationHelper {
  static final DatabaseHelper _db = DatabaseHelper.instance;
  
  /// 檢查是否需要遷移
  static Future<bool> needsMigration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // 檢查是否有舊資料且未標記為已遷移
      final hasOldData = prefs.getStringList('tasks') != null;
      final alreadyMigrated = prefs.getBool('data_migrated_to_sqlite') ?? false;
      
      return hasOldData && !alreadyMigrated;
    } catch (e) {
      debugPrint('檢查遷移狀態時發生錯誤: $e');
      return false;
    }
  }
  
  /// 執行資料遷移
  static Future<void> migrate() async {
    try {
      debugPrint('🔄 開始資料遷移...');
      
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = prefs.getStringList('tasks') ?? [];
      
      if (tasksJson.isEmpty) {
        debugPrint('✅ 沒有需要遷移的資料');
        await _markAsMigrated();
        return;
      }
      
      debugPrint('📦 發現 ${tasksJson.length} 個任務需要遷移');
      
      // 解析任務
      final tasks = tasksJson
          .map((taskString) {
            try {
              return Task.fromJson(jsonDecode(taskString));
            } catch (e) {
              debugPrint('❌ 解析任務失敗: $e');
              return null;
            }
          })
          .whereType<Task>()
          .toList();
      
      // 遷移到 SQLite
      int successCount = 0;
      for (final task in tasks) {
        try {
          await _db.insertTask(task);
          successCount++;
        } catch (e) {
          debugPrint('❌ 遷移任務失敗 [${task.title}]: $e');
        }
      }
      
      debugPrint('✅ 成功遷移 $successCount / ${tasks.length} 個任務');
      
      // 標記為已遷移
      await _markAsMigrated();
      
      // 保留舊資料作為備份（不刪除，以防萬一）
      debugPrint('💾 保留 SharedPreferences 中的資料作為備份');
      
      debugPrint('🎉 資料遷移完成！');
    } catch (e) {
      debugPrint('❌ 資料遷移失敗: $e');
      rethrow;
    }
  }
  
  /// 標記為已遷移
  static Future<void> _markAsMigrated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('data_migrated_to_sqlite', true);
    await prefs.setString('migration_date', DateTime.now().toIso8601String());
  }
  
  /// 清除舊資料（可選，僅在確認遷移成功後使用）
  static Future<void> cleanupOldData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('tasks');
      debugPrint('🗑️ 已清除 SharedPreferences 中的舊任務資料');
    } catch (e) {
      debugPrint('❌ 清除舊資料失敗: $e');
    }
  }
  
  /// 獲取遷移資訊
  static Future<Map<String, dynamic>> getMigrationInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final migrated = prefs.getBool('data_migrated_to_sqlite') ?? false;
      final migrationDate = prefs.getString('migration_date');
      final oldTasksCount = (prefs.getStringList('tasks') ?? []).length;
      
      // 獲取 SQLite 中的任務數量
      final sqliteTasks = await _db.getAllTasks();
      
      return {
        'migrated': migrated,
        'migration_date': migrationDate,
        'old_tasks_count': oldTasksCount,
        'sqlite_tasks_count': sqliteTasks.length,
      };
    } catch (e) {
      debugPrint('❌ 獲取遷移資訊失敗: $e');
      return {
        'migrated': false,
        'error': e.toString(),
      };
    }
  }
}
