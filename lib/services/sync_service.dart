import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import 'database_helper.dart';

/// Two-way sync service between sqflite (local) and Firestore (cloud).
///
/// Strategy:
///   User action → Provider → sqflite (immediate) → SyncService → Firestore (background)
///   Firestore snapshot listener → SyncService → sqflite (on remote change)
///
/// Conflict resolution: last-write-wins based on `updatedAt`.
class SyncService {
  final FirebaseFirestore _firestore;
  final DatabaseHelper _db;
  final String _uid;
  final List<StreamSubscription<dynamic>> _listeners = [];
  DateTime? _lastSyncTime;
  bool _isSyncing = false;

  /// Callback invoked after remote changes are applied locally.
  /// The AuthProvider sets this so it can refresh the task list in memory.
  VoidCallback? onRemoteTaskChange;

  /// Callback invoked when a sync error occurs.
  void Function(String error)? onSyncError;

  /// Callback invoked when lastSyncTime updates.
  VoidCallback? onSyncTimeUpdated;

  DateTime? get lastSyncTime => _lastSyncTime;
  bool get isSyncing => _isSyncing;

  SyncService({
    required String uid,
    DatabaseHelper? db,
    FirebaseFirestore? firestore,
  }) : _uid = uid,
       _db = db ?? DatabaseHelper.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  // ── Collection references ─────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _tasksRef =>
      _firestore.collection('users/$_uid/tasks');

  CollectionReference<Map<String, dynamic>> get _sessionsRef =>
      _firestore.collection('users/$_uid/pomodoro_sessions');

  DocumentReference<Map<String, dynamic>> get _settingsRef =>
      _firestore.doc('users/$_uid/settings/user_settings');

  // ── Listeners ─────────────────────────────────────────────────────

  /// Start listening to Firestore changes and applying them locally.
  void startListeners() {
    debugPrint('☁️ [Sync] Starting listeners for user $_uid');

    // Tasks listener
    _listeners.add(
      _tasksRef.snapshots().listen(
        _onTasksChanged,
        onError: (Object e) => debugPrint('☁️ [Sync] Tasks listener error: $e'),
      ),
    );

    // Pomodoro sessions listener
    _listeners.add(
      _sessionsRef.snapshots().listen(
        _onSessionsChanged,
        onError: (Object e) =>
            debugPrint('☁️ [Sync] Sessions listener error: $e'),
      ),
    );

    // Settings listener
    _listeners.add(
      _settingsRef.snapshots().listen(
        _onSettingsChanged,
        onError: (Object e) =>
            debugPrint('☁️ [Sync] Settings listener error: $e'),
      ),
    );
  }

  /// Stop all Firestore listeners.
  void stopListeners() {
    for (final sub in _listeners) {
      sub.cancel();
    }
    _listeners.clear();
    debugPrint('☁️ [Sync] Stopped all listeners');
  }

  // ── Push (local → Firestore) ──────────────────────────────────────

  /// Push a task change to Firestore.
  Future<void> pushTask(Task task) async {
    try {
      await _tasksRef
          .doc(task.id)
          .set(_taskToFirestore(task), SetOptions(merge: true));
      _lastSyncTime = DateTime.now();
      onSyncTimeUpdated?.call();
      debugPrint('☁️ [Sync] Pushed task ${task.id}');
    } catch (e) {
      debugPrint('☁️ [Sync] Failed to push task ${task.id}: $e');
      onSyncError?.call(e.toString());
    }
  }

  /// Push a pomodoro session to Firestore.
  Future<void> pushPomodoroSession({
    required String sessionId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _sessionsRef.doc(sessionId).set(data, SetOptions(merge: true));
      debugPrint('☁️ [Sync] Pushed pomodoro session $sessionId');
    } catch (e) {
      debugPrint('☁️ [Sync] Failed to push session $sessionId: $e');
    }
  }

  /// Push settings to Firestore.
  Future<void> pushSettings(Map<String, dynamic> settings) async {
    try {
      settings['updatedAt'] = FieldValue.serverTimestamp();
      await _settingsRef.set(settings, SetOptions(merge: true));
      debugPrint('☁️ [Sync] Pushed settings');
    } catch (e) {
      debugPrint('☁️ [Sync] Failed to push settings: $e');
    }
  }

  // ── Initial Sync ──────────────────────────────────────────────────

  /// Run on first sign-in: uploads all local data, then starts listeners.
  Future<void> initialSync() async {
    _isSyncing = true;
    debugPrint('☁️ [Sync] Running initial sync for user $_uid');

    try {
      // 1. Check if Firestore already has data for this user
      final existingTasks = await _tasksRef.limit(1).get();
      final hasRemoteData = existingTasks.docs.isNotEmpty;

      if (hasRemoteData) {
        // Second device — pull remote data, merge with local
        await _pullAndMerge();
      } else {
        // First device — seed Firestore from local sqflite
        await _seedFirestore();
      }

      startListeners();
      _lastSyncTime = DateTime.now();
      debugPrint('☁️ [Sync] Initial sync complete');
    } catch (e) {
      debugPrint('☁️ [Sync] Initial sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Upload all local data to Firestore (first device seed).
  Future<void> _seedFirestore() async {
    final tasks = await _db.getAllTasks();
    debugPrint('☁️ [Sync] Seeding ${tasks.length} tasks to Firestore');

    // Batch writes — max 500 per batch
    final batches = <WriteBatch>[];
    var currentBatch = _firestore.batch();
    var count = 0;

    for (final task in tasks) {
      currentBatch.set(_tasksRef.doc(task.id), _taskToFirestore(task));
      count++;
      if (count % 500 == 0) {
        batches.add(currentBatch);
        currentBatch = _firestore.batch();
      }
    }
    batches.add(currentBatch);

    for (final batch in batches) {
      await batch.commit();
    }
    debugPrint('☁️ [Sync] Seed complete');
  }

  /// Pull remote data and merge with local (second device).
  Future<void> _pullAndMerge() async {
    debugPrint('☁️ [Sync] Pulling remote data and merging');

    final remoteSnap = await _tasksRef.get();
    for (final doc in remoteSnap.docs) {
      final remoteTask = _taskFromFirestore(doc.id, doc.data());
      final localTask = await _db.getTask(doc.id);

      if (localTask == null) {
        // New remote task — insert locally
        if (remoteTask.deletedAt != null) continue; // skip deleted
        await _db.insertTask(remoteTask);
      } else {
        // Both exist — last-write-wins
        if (remoteTask.updatedAt.isAfter(localTask.updatedAt)) {
          await _db.updateTask(remoteTask);
        }
      }
    }

    // Also upload any local tasks that don't exist remotely
    final localTasks = await _db.getAllTasks();
    final remoteIds = remoteSnap.docs.map((d) => d.id).toSet();
    for (final local in localTasks) {
      if (!remoteIds.contains(local.id)) {
        await pushTask(local);
      }
    }

    onRemoteTaskChange?.call();
  }

  // ── Snapshot Handlers (remote → local) ────────────────────────────

  Future<void> _onTasksChanged(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) async {
    if (_isSyncing) return; // Don't react to our own initial sync writes
    var changed = false;

    for (final change in snapshot.docChanges) {
      final data = change.doc.data();
      if (data == null) continue;

      final remoteTask = _taskFromFirestore(change.doc.id, data);
      final localTask = await _db.getTask(change.doc.id);

      switch (change.type) {
        case DocumentChangeType.added:
        case DocumentChangeType.modified:
          if (remoteTask.deletedAt != null) {
            // Remote soft-delete → hard-delete locally
            if (localTask != null) {
              await _db.deleteTask(change.doc.id);
              changed = true;
            }
          } else if (localTask == null) {
            await _db.insertTask(remoteTask);
            changed = true;
          } else if (remoteTask.updatedAt.isAfter(localTask.updatedAt)) {
            await _db.updateTask(remoteTask);
            changed = true;
          }
        case DocumentChangeType.removed:
          if (localTask != null) {
            await _db.deleteTask(change.doc.id);
            changed = true;
          }
      }
    }

    if (changed) {
      _lastSyncTime = DateTime.now();
      onSyncTimeUpdated?.call();
      onRemoteTaskChange?.call();
      debugPrint('☁️ [Sync] Applied remote task changes');
    }
  }

  Future<void> _onSessionsChanged(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) async {
    // Pomodoro sessions are append-mostly; we listen but don't merge yet.
    // Full implementation would follow same pattern as tasks.
    if (snapshot.docChanges.isNotEmpty) {
      _lastSyncTime = DateTime.now();
      debugPrint(
        '☁️ [Sync] Received ${snapshot.docChanges.length} session changes',
      );
    }
  }

  Future<void> _onSettingsChanged(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) async {
    // Settings sync handled at the provider level.
    if (snapshot.exists) {
      _lastSyncTime = DateTime.now();
      debugPrint('☁️ [Sync] Received settings change');
    }
  }

  // ── Cleanup ───────────────────────────────────────────────────────

  /// Hard-delete soft-deleted tasks older than 30 days from local DB.
  Future<void> cleanupSyncedDeletes() async {
    await _db.cleanupDeletedTasks();
  }

  // ── Firestore ↔ Task mapping ──────────────────────────────────────

  Map<String, dynamic> _taskToFirestore(Task task) {
    return {
      'id': task.id,
      'title': task.title,
      'description': task.description,
      'pomodoroCount': task.pomodoroCount,
      'completedPomodoros': task.completedPomodoros,
      'priority': task.priority.name,
      'status': task.status.name,
      'createdAt': Timestamp.fromDate(task.createdAt),
      'completedAt': task.completedAt != null
          ? Timestamp.fromDate(task.completedAt!)
          : null,
      'isAIGenerated': task.isAIGenerated,
      'aiSessionId': task.aiSessionId,
      'aiSessionTitle': task.aiSessionTitle,
      'updatedAt': Timestamp.fromDate(task.updatedAt),
      'deletedAt': task.deletedAt != null
          ? Timestamp.fromDate(task.deletedAt!)
          : null,
    };
  }

  Task _taskFromFirestore(String docId, Map<String, dynamic> data) {
    return Task(
      id: docId,
      title: data['title'] as String? ?? '',
      description: data['description'] as String?,
      pomodoroCount: data['pomodoroCount'] as int? ?? 1,
      completedPomodoros: data['completedPomodoros'] as int? ?? 0,
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == data['priority'],
        orElse: () => TaskPriority.medium,
      ),
      status: TaskStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TaskStatus.pending,
      ),
      createdAt: _toDateTime(data['createdAt']),
      completedAt: data['completedAt'] != null
          ? _toDateTime(data['completedAt'])
          : null,
      isAIGenerated: data['isAIGenerated'] as bool? ?? false,
      aiSessionId: data['aiSessionId'] as String?,
      aiSessionTitle: data['aiSessionTitle'] as String?,
      updatedAt: data['updatedAt'] != null
          ? _toDateTime(data['updatedAt'])
          : null,
      deletedAt: data['deletedAt'] != null
          ? _toDateTime(data['deletedAt'])
          : null,
    );
  }

  /// Convert Firestore Timestamp or ISO string to DateTime.
  DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }
}
