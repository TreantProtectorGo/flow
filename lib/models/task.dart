enum TaskPriority {
  low,
  medium,
  high,
}

enum TaskStatus {
  pending,
  inProgress,
  completed,
}

class Task {
  final String id;
  final String title;
  final String? description;
  final int pomodoroCount;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.pomodoroCount,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.completedAt,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    int? pomodoroCount,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      pomodoroCount: pomodoroCount ?? this.pomodoroCount,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'pomodoroCount': pomodoroCount,
      'priority': priority.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      pomodoroCount: json['pomodoroCount'],
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == json['priority'],
      ),
      status: TaskStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
    );
  }

  String get priorityText {
    switch (priority) {
      case TaskPriority.high:
        return '高優先級';
      case TaskPriority.medium:
        return '中優先級';
      case TaskPriority.low:
        return '低優先級';
    }
  }

  String get statusText {
    switch (status) {
      case TaskStatus.pending:
        return '待辦事項';
      case TaskStatus.inProgress:
        return '進行中';
      case TaskStatus.completed:
        return '已完成';
    }
  }
}
