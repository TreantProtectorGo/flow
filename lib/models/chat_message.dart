enum MessageRole { user, assistant, system }

MessageRole messageRoleFromString(String value) {
  return MessageRole.values.firstWhere(
    (role) => role.name == value,
    orElse: () => MessageRole.assistant,
  );
}

class TaskPlan {
  final String mainGoal;
  final String? sessionTitle;
  final String estimatedTime;
  final List<TaskPlanItem> tasks;

  TaskPlan({
    required this.mainGoal,
    this.sessionTitle,
    required this.estimatedTime,
    required this.tasks,
  });

  factory TaskPlan.fromJson(Map<String, dynamic> json) {
    return TaskPlan(
      mainGoal: json['mainGoal'] as String,
      sessionTitle: json['sessionTitle'] as String?,
      estimatedTime: json['estimatedTime'] as String,
      tasks: (json['tasks'] as List<dynamic>)
          .map((task) => TaskPlanItem.fromJson(task as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mainGoal': mainGoal,
      'sessionTitle': sessionTitle,
      'estimatedTime': estimatedTime,
      'tasks': tasks.map((task) => task.toJson()).toList(),
    };
  }

  /// Creates a modified copy of this TaskPlan
  TaskPlan copyWith({
    String? mainGoal,
    String? sessionTitle,
    String? estimatedTime,
    List<TaskPlanItem>? tasks,
  }) {
    return TaskPlan(
      mainGoal: mainGoal ?? this.mainGoal,
      sessionTitle: sessionTitle ?? this.sessionTitle,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      tasks: tasks ?? this.tasks,
    );
  }
}

class TaskPlanItem {
  final String title;
  final String description;
  final List<String> steps;
  final int pomodoroCount;
  final String priority;

  TaskPlanItem({
    required this.title,
    required this.description,
    required this.steps,
    required this.pomodoroCount,
    required this.priority,
  });

  factory TaskPlanItem.fromJson(Map<String, dynamic> json) {
    return TaskPlanItem(
      title: json['title'] as String,
      description: json['description'] as String,
      steps: (json['steps'] as List<dynamic>).map((s) => s as String).toList(),
      pomodoroCount: json['pomodoroCount'] as int,
      priority: json['priority'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'steps': steps,
      'pomodoroCount': pomodoroCount,
      'priority': priority,
    };
  }

  /// Creates a modified copy of this TaskPlanItem
  TaskPlanItem copyWith({
    String? title,
    String? description,
    List<String>? steps,
    int? pomodoroCount,
    String? priority,
  }) {
    return TaskPlanItem(
      title: title ?? this.title,
      description: description ?? this.description,
      steps: steps ?? this.steps,
      pomodoroCount: pomodoroCount ?? this.pomodoroCount,
      priority: priority ?? this.priority,
    );
  }
}

class ChatMessage {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final bool isStreaming;
  final TaskPlan? taskPlan; // Task plan data from AI

  ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.isStreaming = false,
    this.taskPlan,
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    MessageRole? role,
    DateTime? timestamp,
    bool? isStreaming,
    TaskPlan? taskPlan,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
      taskPlan: taskPlan ?? this.taskPlan,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'role': role.name,
      'timestamp': timestamp.toIso8601String(),
      'isStreaming': isStreaming,
      'taskPlan': taskPlan?.toJson(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      role: messageRoleFromString(json['role'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      isStreaming: json['isStreaming'] as bool? ?? false,
      taskPlan: json['taskPlan'] != null
          ? TaskPlan.fromJson(json['taskPlan'] as Map<String, dynamic>)
          : null,
    );
  }
}
