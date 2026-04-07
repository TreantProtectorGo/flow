import '../l10n/app_localizations.dart';

enum TaskPriority { low, medium, high }

enum TaskStatus { pending, inProgress, completed }

const Object _noTaskFieldChange = Object();

class Task {
  final String id;
  final String title;
  final String? description;
  final int pomodoroCount;
  final int completedPomodoros; // Actual completed pomodoros
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool isAIGenerated; // Whether this task was created by AI breakdown
  final String? aiSessionId;
  final String? aiSessionTitle;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? dailyReminderTime;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.pomodoroCount,
    this.completedPomodoros = 0,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.isAIGenerated = false,
    this.aiSessionId,
    this.aiSessionTitle,
    DateTime? updatedAt,
    this.deletedAt,
    this.dailyReminderTime,
  }) : updatedAt = updatedAt ?? createdAt;

  Task copyWith({
    String? id,
    String? title,
    Object? description = _noTaskFieldChange,
    int? pomodoroCount,
    int? completedPomodoros,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? createdAt,
    Object? completedAt = _noTaskFieldChange,
    bool? isAIGenerated,
    Object? aiSessionId = _noTaskFieldChange,
    Object? aiSessionTitle = _noTaskFieldChange,
    DateTime? updatedAt,
    Object? deletedAt = _noTaskFieldChange,
    Object? dailyReminderTime = _noTaskFieldChange,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: identical(description, _noTaskFieldChange)
          ? this.description
          : description as String?,
      pomodoroCount: pomodoroCount ?? this.pomodoroCount,
      completedPomodoros: completedPomodoros ?? this.completedPomodoros,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: identical(completedAt, _noTaskFieldChange)
          ? this.completedAt
          : completedAt as DateTime?,
      isAIGenerated: isAIGenerated ?? this.isAIGenerated,
      aiSessionId: identical(aiSessionId, _noTaskFieldChange)
          ? this.aiSessionId
          : aiSessionId as String?,
      aiSessionTitle: identical(aiSessionTitle, _noTaskFieldChange)
          ? this.aiSessionTitle
          : aiSessionTitle as String?,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: identical(deletedAt, _noTaskFieldChange)
          ? this.deletedAt
          : deletedAt as DateTime?,
      dailyReminderTime: identical(dailyReminderTime, _noTaskFieldChange)
          ? this.dailyReminderTime
          : dailyReminderTime as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'pomodoroCount': pomodoroCount,
      'completedPomodoros': completedPomodoros,
      'priority': priority.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'isAIGenerated': isAIGenerated,
      'aiSessionId': aiSessionId,
      'aiSessionTitle': aiSessionTitle,
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'dailyReminderTime': dailyReminderTime,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      pomodoroCount: json['pomodoroCount'],
      completedPomodoros: json['completedPomodoros'] ?? 0,
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == json['priority'],
      ),
      status: TaskStatus.values.firstWhere((e) => e.name == json['status']),
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      isAIGenerated: json['isAIGenerated'] ?? false,
      aiSessionId: json['aiSessionId'] as String?,
      aiSessionTitle: json['aiSessionTitle'] as String?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'])
          : null,
      dailyReminderTime: json['dailyReminderTime'] as String?,
    );
  }

  String priorityText(AppLocalizations l10n) {
    switch (priority) {
      case TaskPriority.high:
        return l10n.highPriority;
      case TaskPriority.medium:
        return l10n.mediumPriority;
      case TaskPriority.low:
        return l10n.lowPriority;
    }
  }

  String statusText(AppLocalizations l10n) {
    switch (status) {
      case TaskStatus.pending:
        return l10n.statusPending;
      case TaskStatus.inProgress:
        return l10n.statusInProgress;
      case TaskStatus.completed:
        return l10n.statusCompleted;
    }
  }
}
