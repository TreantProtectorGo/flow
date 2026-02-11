import '../l10n/app_localizations.dart';

enum TaskPriority { low, medium, high }

enum TaskStatus { pending, inProgress, completed }

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
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    int? pomodoroCount,
    int? completedPomodoros,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    bool? isAIGenerated,
    String? aiSessionId,
    String? aiSessionTitle,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      pomodoroCount: pomodoroCount ?? this.pomodoroCount,
      completedPomodoros: completedPomodoros ?? this.completedPomodoros,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      isAIGenerated: isAIGenerated ?? this.isAIGenerated,
      aiSessionId: aiSessionId ?? this.aiSessionId,
      aiSessionTitle: aiSessionTitle ?? this.aiSessionTitle,
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
