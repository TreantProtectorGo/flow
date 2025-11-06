import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';

class TaskSelectionDialog extends ConsumerWidget {
  const TaskSelectionDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskNotifier = ref.watch(taskProvider);
    final theme = Theme.of(context);

    // 可選擇的任務：待辦和進行中的任務
    final availableTasks = [
      ...taskNotifier.inProgressTasks,
      ...taskNotifier.pendingTasks,
    ];

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.task_alt, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('選擇任務'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: availableTasks.isEmpty
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('暫無可選擇的任務'),
                  Text('請先在任務頁面添加一些任務', style: TextStyle(color: Colors.grey)),
                ],
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: availableTasks.length,
                itemBuilder: (context, index) {
                  final task = availableTasks[index];
                  final isCurrentTask = taskNotifier.currentTaskId == task.id;

                  return Card(
                    elevation: isCurrentTask ? 4 : 1,
                    color: isCurrentTask
                        ? theme.colorScheme.primaryContainer
                        : null,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getPriorityColor(
                          task.priority,
                          theme,
                        ),
                        child: Icon(
                          task.status == TaskStatus.inProgress
                              ? Icons.play_circle
                              : Icons.pending_actions,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        task.title,
                        style: TextStyle(
                          fontWeight: isCurrentTask
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (task.description != null &&
                              task.description!.isNotEmpty)
                            Text(
                              task.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                flex: 2,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      size: 16,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        '${task.pomodoroCount} 個',
                                        style: theme.textTheme.bodySmall,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                flex: 1,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getPriorityColor(
                                      task.priority,
                                      theme,
                                    ).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _getPriorityShortText(task.priority),
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: _getPriorityColor(
                                        task.priority,
                                        theme,
                                      ),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: isCurrentTask
                          ? Icon(
                              Icons.check_circle,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                      onTap: () {
                        Navigator.of(context).pop(task);
                      },
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        if (taskNotifier.currentTaskId != null)
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop('clear');
            },
            child: const Text('清除選擇'),
          ),
      ],
    );
  }

  Color _getPriorityColor(TaskPriority priority, ThemeData theme) {
    switch (priority) {
      case TaskPriority.high:
        return theme.colorScheme.error;
      case TaskPriority.medium:
        return theme.colorScheme.tertiary;
      case TaskPriority.low:
        return theme.colorScheme.primary;
    }
  }

  String _getPriorityShortText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return '高';
      case TaskPriority.medium:
        return '中';
      case TaskPriority.low:
        return '低';
    }
  }
}
