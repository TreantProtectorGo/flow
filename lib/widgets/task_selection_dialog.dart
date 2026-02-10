import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../l10n/app_localizations.dart';

class TaskSelectionDialog extends ConsumerWidget {
  const TaskSelectionDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskNotifier = ref.watch(taskProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

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
          Text(l10n.selectTask),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: availableTasks.isEmpty
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inbox,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.noTasksToSelect),
                  Text(
                    l10n.pleaseAddTasksFirst,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
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
                                        '${task.pomodoroCount}${l10n.items}',
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
                                    _getPriorityShortText(task.priority, l10n),
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
          child: Text(l10n.cancel),
        ),
        if (taskNotifier.currentTaskId != null)
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop('clear');
            },
            child: Text(l10n.clearSelection),
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

  String _getPriorityShortText(TaskPriority priority, AppLocalizations l10n) {
    switch (priority) {
      case TaskPriority.high:
        return l10n.priorityHigh;
      case TaskPriority.medium:
        return l10n.priorityMedium;
      case TaskPriority.low:
        return l10n.priorityLow;
    }
  }
}
