import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('focus.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 任務表
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        pomodoro_count INTEGER NOT NULL,
        priority TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        completed_at TEXT
      )
    ''');

    // 番茄鐘會話表
    await db.execute('''
      CREATE TABLE pomodoro_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id TEXT,
        start_time TEXT NOT NULL,
        end_time TEXT,
        duration INTEGER NOT NULL,
        completed INTEGER NOT NULL,
        session_type TEXT NOT NULL,
        FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE SET NULL
      )
    ''');

    // AI 對話歷史表
    await db.execute('''
      CREATE TABLE chat_messages (
        id TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        role TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        is_streaming INTEGER NOT NULL
      )
    ''');

    // 建立索引以提升查詢效能
    await db.execute('CREATE INDEX idx_tasks_status ON tasks(status)');
    await db.execute('CREATE INDEX idx_tasks_created_at ON tasks(created_at)');
    await db.execute('CREATE INDEX idx_pomodoro_sessions_start_time ON pomodoro_sessions(start_time)');
    await db.execute('CREATE INDEX idx_pomodoro_sessions_task_id ON pomodoro_sessions(task_id)');
  }

  // ==================== Tasks CRUD ====================

  Future<int> insertTask(Task task) async {
    final db = await database;
    debugPrint('📝 [DB] 插入任務: ${task.title} (ID: ${task.id})');
    final result = await db.insert(
      'tasks',
      {
        'id': task.id,
        'title': task.title,
        'description': task.description,
        'pomodoro_count': task.pomodoroCount,
        'priority': task.priority.name,
        'status': task.status.name,
        'created_at': task.createdAt.toIso8601String(),
        'completed_at': task.completedAt?.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('✅ [DB] 任務插入成功');
    return result;
  }

  Future<List<Task>> getAllTasks() async {
    final db = await database;
    debugPrint('📚 [DB] 載入所有任務...');
    final result = await db.query(
      'tasks',
      orderBy: 'created_at DESC',
    );

    debugPrint('✅ [DB] 載入完成，共 ${result.length} 個任務');
    return result.map((json) => Task.fromJson({
      'id': json['id'],
      'title': json['title'],
      'description': json['description'],
      'pomodoroCount': json['pomodoro_count'],
      'priority': json['priority'],
      'status': json['status'],
      'createdAt': json['created_at'],
      'completedAt': json['completed_at'],
    })).toList();
  }

  Future<Task?> getTask(String id) async {
    final db = await database;
    final results = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;

    final json = results.first;
    return Task.fromJson({
      'id': json['id'],
      'title': json['title'],
      'description': json['description'],
      'pomodoroCount': json['pomodoro_count'],
      'priority': json['priority'],
      'status': json['status'],
      'createdAt': json['created_at'],
      'completedAt': json['completed_at'],
    });
  }

  Future<int> updateTask(Task task) async {
    final db = await database;
    debugPrint('✏️ [DB] 更新任務: ${task.title} (ID: ${task.id}, 狀態: ${task.status.name})');
    final result = await db.update(
      'tasks',
      {
        'title': task.title,
        'description': task.description,
        'pomodoro_count': task.pomodoroCount,
        'priority': task.priority.name,
        'status': task.status.name,
        'created_at': task.createdAt.toIso8601String(),
        'completed_at': task.completedAt?.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [task.id],
    );
    debugPrint('✅ [DB] 任務更新成功');
    return result;
  }

  Future<int> deleteTask(String id) async {
    final db = await database;
    debugPrint('🗑️ [DB] 刪除任務 ID: $id');
    final result = await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
    debugPrint('✅ [DB] 任務刪除成功');
    return result;
  }

  Future<List<Task>> getTasksByStatus(String status, {DateTime? startDate, DateTime? endDate}) async {
    final db = await database;
    
    String whereClause = 'status = ?';
    List<dynamic> whereArgs = [status];
    
    // 如果指定了日期範圍，添加日期過濾
    if (startDate != null && endDate != null) {
      if (status == 'completed') {
        whereClause += ' AND completed_at >= ? AND completed_at < ?';
        whereArgs.addAll([
          startDate.toIso8601String(),
          endDate.toIso8601String(),
        ]);
      } else {
        whereClause += ' AND created_at >= ? AND created_at < ?';
        whereArgs.addAll([
          startDate.toIso8601String(),
          endDate.toIso8601String(),
        ]);
      }
    }
    
    final result = await db.query(
      'tasks',
      where: whereClause,
      whereArgs: whereArgs,
    );

    return result.map((json) => Task.fromJson({
      'id': json['id'],
      'title': json['title'],
      'description': json['description'],
      'pomodoroCount': json['pomodoro_count'],
      'priority': json['priority'],
      'status': json['status'],
      'createdAt': json['created_at'],
      'completedAt': json['completed_at'],
    })).toList();
  }

  // ==================== Pomodoro Sessions ====================

  Future<int> insertPomodoroSession({
    String? taskId,
    required DateTime startTime,
    DateTime? endTime,
    required int duration,
    required bool completed,
    required String sessionType, // 'focus' or 'break'
  }) async {
    final db = await database;
    debugPrint('⏱️ [DB] 插入番茄鐘會話: 任務ID=$taskId, 時長=$duration分鐘, 完成=$completed, 類型=$sessionType');
    final result = await db.insert('pomodoro_sessions', {
      'task_id': taskId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration': duration,
      'completed': completed ? 1 : 0,
      'session_type': sessionType,
    });
    debugPrint('✅ [DB] 番茄鐘會話插入成功 (ID: $result)');
    return result;
  }

  Future<List<Map<String, dynamic>>> getPomodoroSessions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String? whereClause;
    List<dynamic>? whereArgs;

    if (startDate != null && endDate != null) {
      whereClause = 'start_time >= ? AND start_time <= ?';
      whereArgs = [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ];
    }

    return await db.query(
      'pomodoro_sessions',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'start_time DESC',
    );
  }

  // 獲取統計數據
  Future<Map<String, dynamic>> getStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    
    String? whereClause;
    List<dynamic>? whereArgs;

    if (startDate != null && endDate != null) {
      whereClause = 'start_time >= ? AND start_time <= ? AND completed = 1';
      whereArgs = [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ];
    } else {
      whereClause = 'completed = 1';
    }

    // 完成的番茄鐘數量
    final completedSessions = await db.query(
      'pomodoro_sessions',
      where: '$whereClause AND session_type = ?',
      whereArgs: whereArgs != null ? [...whereArgs, 'focus'] : ['focus'],
    );

    // 總專注時間（分鐘）
    final totalDuration = completedSessions.fold<int>(
      0,
      (sum, session) => sum + (session['duration'] as int),
    );

    // 完成的任務數量
    final completedTasks = await db.query(
      'tasks',
      where: 'status = ?',
      whereArgs: ['completed'],
    );

    return {
      'completedPomodoros': completedSessions.length,
      'totalFocusMinutes': totalDuration,
      'completedTasks': completedTasks.length,
    };
  }

  // ==================== 資料庫管理 ====================

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'focus.db');
    await databaseFactory.deleteDatabase(path);
  }
}
