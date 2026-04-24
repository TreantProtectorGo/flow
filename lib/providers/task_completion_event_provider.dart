import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskCompletionEvent {
  final String eventId;
  final String taskId;
  final String taskTitle;
  final String? nextTaskId;
  final String? nextTaskTitle;

  const TaskCompletionEvent({
    required this.eventId,
    required this.taskId,
    required this.taskTitle,
    this.nextTaskId,
    this.nextTaskTitle,
  });
}

final StateProvider<TaskCompletionEvent?> taskCompletionEventProvider =
    StateProvider<TaskCompletionEvent?>((Ref ref) {
      return null;
    });

class PendingNextTaskPrompt {
  final String completedTaskId;
  final String nextTaskId;

  const PendingNextTaskPrompt({
    required this.completedTaskId,
    required this.nextTaskId,
  });
}

final StateProvider<PendingNextTaskPrompt?> pendingNextTaskPromptProvider =
    StateProvider<PendingNextTaskPrompt?>((Ref ref) {
      return null;
    });
