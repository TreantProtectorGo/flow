enum MessageRole { user, assistant, system }

class TaskPlan {
  final String mainGoal;
  final String estimatedTime;
  final List<TaskPlanItem> tasks;

  TaskPlan({
    required this.mainGoal,
    required this.estimatedTime,
    required this.tasks,
  });

  factory TaskPlan.fromJson(Map<String, dynamic> json) {
    return TaskPlan(
      mainGoal: json['mainGoal'] as String,
      estimatedTime: json['estimatedTime'] as String,
      tasks: (json['tasks'] as List<dynamic>)
          .map((task) => TaskPlanItem.fromJson(task as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mainGoal': mainGoal,
      'estimatedTime': estimatedTime,
      'tasks': tasks.map((task) => task.toJson()).toList(),
    };
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
}

class ChatMessage {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final bool isStreaming;
  final TaskPlan? taskPlan; // 新增：任務計劃數據

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
}
