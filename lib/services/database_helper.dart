import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import '../models/chat_message.dart';
import '../models/task.dart';

/// DatabaseHelper - SQLite database access layer using singleton pattern
/// Manages all database operations for tasks, pomodoro sessions, and chat messages
/// Uses lazy initialization to ensure single database instance across the app
class DatabaseHelper {
  /// Singleton instance of DatabaseHelper
  static final DatabaseHelper instance = DatabaseHelper._init();

  /// Cached database instance to avoid multiple connections
  static Database? _database;
  bool _taskSchemaEnsured = false;
  bool _chatSchemaEnsured = false;

  /// Private constructor for singleton pattern
  DatabaseHelper._init();

  /// Lazily initializes and returns the database instance
  /// Returns cached instance if already initialized, otherwise initializes new connection
  Future<Database> get database async {
    if (_database != null) {
      await _ensureTaskSchema(_database!);
      await _ensureChatSchema(_database!);
      return _database!;
    }
    _database = await _initDB('focus.db');
    await _ensureTaskSchema(_database!);
    await _ensureChatSchema(_database!);
    return _database!;
  }

  /// Opens the SQLite database file and sets initial configuration
  /// [filePath]: Name of the database file (typically 'focus.db')
  /// Returns: Initialized Database instance with version 2 schema
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 6,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _ensureTaskSchema(Database db) async {
    if (_taskSchemaEnsured) {
      return;
    }

    final columns = await db.rawQuery('PRAGMA table_info(tasks)');
    final names = columns
        .map((column) => column['name'] as String?)
        .whereType<String>()
        .toSet();

    final missing = <String>[];
    if (!names.contains('ai_session_id')) {
      missing.add('ALTER TABLE tasks ADD COLUMN ai_session_id TEXT');
    }
    if (!names.contains('ai_session_title')) {
      missing.add('ALTER TABLE tasks ADD COLUMN ai_session_title TEXT');
    }

    for (final statement in missing) {
      await db.execute(statement);
    }

    if (missing.isNotEmpty) {
      debugPrint(
        '📦 [DB] Repaired tasks schema by adding missing ai_session columns',
      );
    }
    _taskSchemaEnsured = true;
  }

  Future<void> _ensureChatSchema(Database db) async {
    if (_chatSchemaEnsured) {
      return;
    }

    await db.execute('''
      CREATE TABLE IF NOT EXISTS chat_sessions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    final columns = await db.rawQuery('PRAGMA table_info(chat_messages)');
    final names = columns
        .map((column) => column['name'] as String?)
        .whereType<String>()
        .toSet();

    if (!names.contains('task_plan_json')) {
      await db.execute(
        'ALTER TABLE chat_messages ADD COLUMN task_plan_json TEXT',
      );
      debugPrint('📦 [DB] Repaired chat_messages schema: added task_plan_json');
    }
    if (!names.contains('chat_session_id')) {
      await db.execute(
        'ALTER TABLE chat_messages ADD COLUMN chat_session_id TEXT',
      );
      debugPrint(
        '📦 [DB] Repaired chat_messages schema: added chat_session_id',
      );
    }

    final unassignedCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            "SELECT COUNT(*) FROM chat_messages WHERE chat_session_id IS NULL OR chat_session_id = ''",
          ),
        ) ??
        0;
    if (unassignedCount > 0) {
      final now = DateTime.now().toIso8601String();
      await db.insert('chat_sessions', {
        'id': 'legacy',
        'title': 'Previous Chat',
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      await db.rawUpdate(
        "UPDATE chat_messages SET chat_session_id = 'legacy' WHERE chat_session_id IS NULL OR chat_session_id = ''",
      );
    }
    _chatSchemaEnsured = true;
  }

  /// Handles database schema upgrades between versions
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add completed_pomodoros column to tasks table
      await db.execute(
        'ALTER TABLE tasks ADD COLUMN completed_pomodoros INTEGER NOT NULL DEFAULT 0',
      );
      debugPrint(
        '📦 [DB] Migrated to version 2: added completed_pomodoros column',
      );
    }
    if (oldVersion < 3) {
      // Add is_ai_generated column to tasks table
      await db.execute(
        'ALTER TABLE tasks ADD COLUMN is_ai_generated INTEGER NOT NULL DEFAULT 0',
      );
      debugPrint('📦 [DB] Migrated to version 3: added is_ai_generated column');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE tasks ADD COLUMN ai_session_id TEXT');
      await db.execute('ALTER TABLE tasks ADD COLUMN ai_session_title TEXT');
      debugPrint(
        '📦 [DB] Migrated to version 4: added ai_session_id and ai_session_title columns',
      );
    }
    if (oldVersion < 5) {
      await db.execute(
        'ALTER TABLE chat_messages ADD COLUMN task_plan_json TEXT',
      );
      debugPrint('📦 [DB] Migrated to version 5: added task_plan_json column');
    }
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS chat_sessions (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      await db.execute(
        'ALTER TABLE chat_messages ADD COLUMN chat_session_id TEXT',
      );
      final unassignedCount =
          Sqflite.firstIntValue(
            await db.rawQuery(
              "SELECT COUNT(*) FROM chat_messages WHERE chat_session_id IS NULL OR chat_session_id = ''",
            ),
          ) ??
          0;
      if (unassignedCount > 0) {
        final now = DateTime.now().toIso8601String();
        await db.insert('chat_sessions', {
          'id': 'legacy',
          'title': 'Previous Chat',
          'created_at': now,
          'updated_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
        await db.rawUpdate(
          "UPDATE chat_messages SET chat_session_id = 'legacy' WHERE chat_session_id IS NULL OR chat_session_id = ''",
        );
      }
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_chat_messages_session ON chat_messages(chat_session_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_chat_sessions_updated_at ON chat_sessions(updated_at)',
      );
      debugPrint(
        '📦 [DB] Migrated to version 6: added chat_sessions and chat_session_id',
      );
    }
  }

  /// Creates all database tables and indexes on first run
  /// Called automatically by openDatabase when version mismatch occurs
  /// [db]: Database instance to create tables in
  /// [version]: Schema version (currently 1, used for migrations)
  Future<void> _createDB(Database db, int version) async {
    // Tasks table: Stores all user tasks with priority, status, and timestamps
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        pomodoro_count INTEGER NOT NULL,
        completed_pomodoros INTEGER NOT NULL DEFAULT 0,
        priority TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        completed_at TEXT,
        is_ai_generated INTEGER NOT NULL DEFAULT 0,
        ai_session_id TEXT,
        ai_session_title TEXT
      )
    ''');

    // Pomodoro sessions table: Tracks focus sessions and break periods
    // Links sessions to tasks via task_id foreign key
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

    // Chat messages table: Stores AI conversation history
    // Supports streaming messages with role-based storage
    await db.execute('''
      CREATE TABLE chat_messages (
        id TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        role TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        is_streaming INTEGER NOT NULL,
        task_plan_json TEXT,
        chat_session_id TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE chat_sessions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create indexes to optimize query performance
    // Speeds up status-based task filtering
    await db.execute('CREATE INDEX idx_tasks_status ON tasks(status)');
    // Speeds up sorting tasks by creation time
    await db.execute('CREATE INDEX idx_tasks_created_at ON tasks(created_at)');
    // Speeds up querying sessions by date range
    await db.execute(
      'CREATE INDEX idx_pomodoro_sessions_start_time ON pomodoro_sessions(start_time)',
    );
    // Speeds up querying sessions for specific tasks
    await db.execute(
      'CREATE INDEX idx_pomodoro_sessions_task_id ON pomodoro_sessions(task_id)',
    );
    await db.execute(
      'CREATE INDEX idx_chat_messages_session ON chat_messages(chat_session_id)',
    );
    await db.execute(
      'CREATE INDEX idx_chat_sessions_updated_at ON chat_sessions(updated_at)',
    );
  }

  // ==================== Tasks CRUD Operations ====================

  /// Inserts a new task into the database
  /// [task]: Task object to insert with all required fields
  /// Returns: Number of rows affected (1 on success)
  /// Uses ConflictAlgorithm.replace to handle duplicate IDs
  Future<int> insertTask(Task task) async {
    final db = await database;
    debugPrint('📝 [DB] Inserting task: ${task.title} (ID: ${task.id})');
    final result = await db.insert('tasks', {
      'id': task.id,
      'title': task.title,
      'description': task.description,
      'pomodoro_count': task.pomodoroCount,
      'completed_pomodoros': task.completedPomodoros,
      'priority': task.priority.name,
      'status': task.status.name,
      'created_at': task.createdAt.toIso8601String(),
      'completed_at': task.completedAt?.toIso8601String(),
      'is_ai_generated': task.isAIGenerated ? 1 : 0,
      'ai_session_id': task.aiSessionId,
      'ai_session_title': task.aiSessionTitle,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    debugPrint('✅ [DB] Task insertion successful');
    return result;
  }

  /// Retrieves all tasks from the database
  /// Returns: List of all Task objects, ordered by most recently created first
  Future<List<Task>> getAllTasks() async {
    final db = await database;
    debugPrint('📚 [DB] Loading all tasks...');
    final result = await db.query('tasks', orderBy: 'created_at DESC');

    debugPrint('✅ [DB] Load complete, total ${result.length} tasks');
    return result
        .map(
          (json) => Task.fromJson({
            'id': json['id'],
            'title': json['title'],
            'description': json['description'],
            'pomodoroCount': json['pomodoro_count'],
            'completedPomodoros': json['completed_pomodoros'] ?? 0,
            'priority': json['priority'],
            'status': json['status'],
            'createdAt': json['created_at'],
            'completedAt': json['completed_at'],
            'isAIGenerated': (json['is_ai_generated'] ?? 0) == 1,
            'aiSessionId': json['ai_session_id'],
            'aiSessionTitle': json['ai_session_title'],
          }),
        )
        .toList();
  }

  /// Retrieves a single task by ID
  /// [id]: Unique task identifier
  /// Returns: Task object if found, null if not found
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
      'completedPomodoros': json['completed_pomodoros'] ?? 0,
      'priority': json['priority'],
      'status': json['status'],
      'createdAt': json['created_at'],
      'completedAt': json['completed_at'],
      'isAIGenerated': (json['is_ai_generated'] ?? 0) == 1,
      'aiSessionId': json['ai_session_id'],
      'aiSessionTitle': json['ai_session_title'],
    });
  }

  /// Updates an existing task in the database
  /// [task]: Task object with updated fields
  /// Returns: Number of rows affected (1 on success, 0 if not found)
  Future<int> updateTask(Task task) async {
    final db = await database;
    debugPrint(
      '✏️ [DB] Updating task: ${task.title} (ID: ${task.id}, Status: ${task.status.name})',
    );
    final result = await db.update(
      'tasks',
      {
        'title': task.title,
        'description': task.description,
        'pomodoro_count': task.pomodoroCount,
        'completed_pomodoros': task.completedPomodoros,
        'priority': task.priority.name,
        'status': task.status.name,
        'created_at': task.createdAt.toIso8601String(),
        'completed_at': task.completedAt?.toIso8601String(),
        'is_ai_generated': task.isAIGenerated ? 1 : 0,
        'ai_session_id': task.aiSessionId,
        'ai_session_title': task.aiSessionTitle,
      },
      where: 'id = ?',
      whereArgs: [task.id],
    );
    debugPrint('✅ [DB] Task update successful');
    return result;
  }

  /// Deletes a task by ID from the database
  /// [id]: Unique task identifier to delete
  /// Returns: Number of rows affected (1 on success, 0 if not found)
  /// Note: Deleting a task will cascade delete related pomodoro sessions
  Future<int> deleteTask(String id) async {
    final db = await database;
    debugPrint('🗑️ [DB] Deleting task ID: $id');
    final result = await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
    debugPrint('✅ [DB] Task deletion successful');
    return result;
  }

  /// Retrieves tasks filtered by status and optional date range
  /// [status]: Task status to filter by (e.g., 'pending', 'completed')
  /// [startDate]: Optional start date for filtering (inclusive)
  /// [endDate]: Optional end date for filtering (exclusive)
  /// Returns: List of Task objects matching the filters
  /// For completed tasks, uses completed_at; for others, uses created_at
  Future<List<Task>> getTasksByStatus(
    String status, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;

    String whereClause = 'status = ?';
    List<dynamic> whereArgs = [status];

    // Add date range filter if specified
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

    return result
        .map(
          (json) => Task.fromJson({
            'id': json['id'],
            'title': json['title'],
            'description': json['description'],
            'pomodoroCount': json['pomodoro_count'],
            'completedPomodoros': json['completed_pomodoros'] ?? 0,
            'priority': json['priority'],
            'status': json['status'],
            'createdAt': json['created_at'],
            'completedAt': json['completed_at'],
            'isAIGenerated': (json['is_ai_generated'] ?? 0) == 1,
            'aiSessionId': json['ai_session_id'],
            'aiSessionTitle': json['ai_session_title'],
          }),
        )
        .toList();
  }

  // ==================== Pomodoro Sessions Operations ====================

  // ==================== Chat Messages Operations ====================

  Future<int> insertChatMessage(
    ChatMessage message, {
    required String sessionId,
  }) async {
    final db = await database;
    return db.insert('chat_messages', {
      'id': message.id,
      'content': message.content,
      'role': message.role.name,
      'timestamp': message.timestamp.toIso8601String(),
      'is_streaming': message.isStreaming ? 1 : 0,
      'task_plan_json': message.taskPlan != null
          ? jsonEncode(message.taskPlan!.toJson())
          : null,
      'chat_session_id': sessionId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ChatMessage>> getChatMessages(String sessionId) async {
    final db = await database;
    final rows = await db.query(
      'chat_messages',
      where: 'chat_session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );
    return rows.map((row) {
      final rawTaskPlan = row['task_plan_json'] as String?;
      TaskPlan? taskPlan;
      if (rawTaskPlan != null && rawTaskPlan.isNotEmpty) {
        try {
          taskPlan = TaskPlan.fromJson(
            jsonDecode(rawTaskPlan) as Map<String, dynamic>,
          );
        } catch (_) {
          taskPlan = null;
        }
      }
      return ChatMessage(
        id: row['id'] as String,
        content: row['content'] as String,
        role: messageRoleFromString(row['role'] as String),
        timestamp: DateTime.parse(row['timestamp'] as String),
        isStreaming: (row['is_streaming'] as int? ?? 0) == 1,
        taskPlan: taskPlan,
      );
    }).toList();
  }

  Future<int> clearChatMessages() async {
    final db = await database;
    return db.delete('chat_messages');
  }

  Future<int> clearChatMessagesBySession(String sessionId) async {
    final db = await database;
    return db.delete(
      'chat_messages',
      where: 'chat_session_id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<List<ChatSession>> getChatSessions() async {
    final db = await database;
    final rows = await db.query('chat_sessions', orderBy: 'updated_at DESC');
    return rows
        .map(
          (row) => ChatSession(
            id: row['id'] as String,
            title: row['title'] as String,
            createdAt: DateTime.parse(row['created_at'] as String),
            updatedAt: DateTime.parse(row['updated_at'] as String),
          ),
        )
        .toList();
  }

  Future<ChatSession> createChatSession({required String title}) async {
    final db = await database;
    final now = DateTime.now();
    final id = 'chat_${now.microsecondsSinceEpoch}';
    final normalizedTitle = title.trim().isEmpty ? 'New Chat' : title.trim();
    await db.insert('chat_sessions', {
      'id': id,
      'title': normalizedTitle,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
    return ChatSession(
      id: id,
      title: normalizedTitle,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> touchChatSession(
    String sessionId, {
    String? title,
    DateTime? when,
  }) async {
    final db = await database;
    final values = <String, Object?>{
      'updated_at': (when ?? DateTime.now()).toIso8601String(),
    };
    if (title != null && title.trim().isNotEmpty) {
      values['title'] = title.trim();
    }
    await db.update(
      'chat_sessions',
      values,
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<int> deleteChatSession(String sessionId) async {
    final db = await database;
    await db.delete(
      'chat_messages',
      where: 'chat_session_id = ?',
      whereArgs: [sessionId],
    );
    return db.delete('chat_sessions', where: 'id = ?', whereArgs: [sessionId]);
  }

  // ==================== Pomodoro Sessions Operations ====================

  /// Inserts a new pomodoro session record into the database
  /// [taskId]: Optional ID of the associated task (null for break-only sessions)
  /// [startTime]: Session start timestamp
  /// [endTime]: Session end timestamp (null if still in progress)
  /// [duration]: Session duration in minutes
  /// [completed]: Whether the session was fully completed (1=yes, 0=no)
  /// [sessionType]: Type of session - 'focus' for work session or 'break' for break period
  /// Returns: Inserted session ID (auto-generated by database)
  Future<int> insertPomodoroSession({
    String? taskId,
    required DateTime startTime,
    DateTime? endTime,
    required int duration,
    required bool completed,
    required String sessionType, // 'focus' or 'break'
  }) async {
    final db = await database;
    debugPrint(
      '⏱️ [DB] Inserting pomodoro session: TaskID=$taskId, Duration=$duration min, Completed=$completed, Type=$sessionType',
    );
    final result = await db.insert('pomodoro_sessions', {
      'task_id': taskId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration': duration,
      'completed': completed ? 1 : 0,
      'session_type': sessionType,
    });
    debugPrint('✅ [DB] Pomodoro session insertion successful (ID: $result)');
    return result;
  }

  /// Retrieves pomodoro sessions with optional date range filtering
  /// [startDate]: Optional start date for filtering (inclusive)
  /// [endDate]: Optional end date for filtering (inclusive)
  /// Returns: List of session records ordered by most recent first
  /// Each record contains: id, task_id, start_time, end_time, duration, completed, session_type
  Future<List<Map<String, dynamic>>> getPomodoroSessions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String? whereClause;
    List<dynamic>? whereArgs;

    if (startDate != null && endDate != null) {
      whereClause = 'start_time >= ? AND start_time <= ?';
      whereArgs = [startDate.toIso8601String(), endDate.toIso8601String()];
    }

    return await db.query(
      'pomodoro_sessions',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'start_time DESC',
    );
  }

  /// Retrieves comprehensive statistics based on completed pomodoro sessions
  /// [startDate]: Optional start date for filtering (inclusive)
  /// [endDate]: Optional end date for filtering (inclusive)
  /// Returns: Map containing:
  ///   - completedPomodoros: Number of completed focus sessions
  ///   - totalFocusMinutes: Total minutes spent in focus sessions
  ///   - completedTasks: Total number of completed tasks
  /// Statistics only include completed sessions and tasks
  Future<Map<String, dynamic>> getStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;

    String? whereClause;
    List<dynamic>? whereArgs;

    if (startDate != null && endDate != null) {
      whereClause = 'start_time >= ? AND start_time <= ? AND completed = 1';
      whereArgs = [startDate.toIso8601String(), endDate.toIso8601String()];
    } else {
      whereClause = 'completed = 1';
    }

    // Count completed focus sessions
    final completedSessions = await db.query(
      'pomodoro_sessions',
      where: '$whereClause AND session_type = ?',
      whereArgs: whereArgs != null ? [...whereArgs, 'focus'] : ['focus'],
    );

    // Sum total duration of all focus sessions
    final totalDuration = completedSessions.fold<int>(
      0,
      (sum, session) => sum + (session['duration'] as int),
    );

    // Count total completed tasks
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

  // ==================== Database Management ====================

  /// Closes the database connection
  /// Should be called when the app is closing or when database access is no longer needed
  /// Ensures proper resource cleanup and data integrity
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    _taskSchemaEnsured = false;
    _chatSchemaEnsured = false;
  }

  /// Completely deletes the database file from device storage
  /// WARNING: This operation is irreversible and will delete all user data
  /// Use only for debugging, testing, or explicit user-requested data deletion
  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'focus.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
    _taskSchemaEnsured = false;
    _chatSchemaEnsured = false;
  }
}
