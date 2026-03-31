import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskCompletionEvent {
  final String eventId;
  final String taskId;
  final String taskTitle;

  const TaskCompletionEvent({
    required this.eventId,
    required this.taskId,
    required this.taskTitle,
  });
}

final StateProvider<TaskCompletionEvent?> taskCompletionEventProvider =
    StateProvider<TaskCompletionEvent?>((Ref ref) {
      return null;
    });
