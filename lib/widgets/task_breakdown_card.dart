import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../l10n/app_localizations.dart';
import 'task_plan_editor.dart';


class TaskBreakdownCard extends ConsumerStatefulWidget {
  final TaskPlan taskPlan;

  const TaskBreakdownCard({super.key, required this.taskPlan});

  @override
  ConsumerState<TaskBreakdownCard> createState() => _TaskBreakdownCardState();
}

class _TaskBreakdownCardState extends ConsumerState<TaskBreakdownCard> {
  final Set<int> _expandedTasks = {};
  bool _isCreatingTasks = false;
  bool _tasksCreated = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // 如果任務已創建，不顯示卡片
    if (_tasksCreated) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withOpacity(0.3),
            theme.colorScheme.secondaryContainer.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題區域
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.taskPlan,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.taskPlan.mainGoal,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          // 任務列表
          ...widget.taskPlan.tasks.asMap().entries.map((entry) {
            final index = entry.key;
            final task = entry.value;
            final isExpanded = _expandedTasks.contains(index);

            return _buildTaskItem(theme, task, index, isExpanded);
          }).toList(),

          // 底部資訊和按鈕
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 預估時間
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.estimatedCompletionTime(
                          widget.taskPlan.estimatedTime,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
                if (!_tasksCreated) ...[
                  const SizedBox(height: 16),
                  // 創建任務按鈕組
                  Row(
                    children: [
                      // 編輯計畫按鈕
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: _isCreatingTasks ? null : _openEditor,
                          icon: const Icon(Icons.edit_outlined),
                          label: Text(l10n.editPlan),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 直接創建按鈕
                      Expanded(
                        child: FilledButton.icon(
                          onPressed:
                              _isCreatingTasks ? null : _createTasksFromPlan,
                          icon: _isCreatingTasks
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add_task),
                          label: Text(
                            _isCreatingTasks
                                ? l10n.creatingTasks
                                : l10n.createDirectly,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openEditor() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TaskPlanEditor(
          initialPlan: widget.taskPlan,
        ),
      ),
    );
  }

  Future<void> _createTasksFromPlan() async {
    setState(() {
      _isCreatingTasks = true;
    });

    try {
      final taskNotifier = ref.read(taskProvider);

      // 反轉順序創建，確保第一個任務在最前面
      for (final taskItem in widget.taskPlan.tasks.reversed) {
        // 將 priority 字串轉換為 TaskPriority 枚舉
        TaskPriority priority;
        switch (taskItem.priority.toLowerCase()) {
          case 'high':
            priority = TaskPriority.high;
            break;
          case 'low':
            priority = TaskPriority.low;
            break;
          default:
            priority = TaskPriority.medium;
        }

        // 組合描述：包含原始描述和步驟
        String? description = taskItem.description;
        if (taskItem.steps.isNotEmpty) {
          final stepsText = taskItem.steps
              .asMap()
              .entries
              .map((e) => '${e.key + 1}. ${e.value}')
              .join('\n');
          description = description.isEmpty
              ? stepsText
              : '$description\n\n$stepsText';
        }

        await taskNotifier.addTask(
          title: taskItem.title,
          description: description,
          pomodoroCount: taskItem.pomodoroCount,
          priority: priority,
        );

        // 添加微小延遲確保每個任務有唯一的時間戳
        await Future.delayed(const Duration(milliseconds: 10));
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _tasksCreated = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.tasksCreatedSuccess(widget.taskPlan.tasks.length),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // 返回到任務頁面
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedToCreateTasks),
            showCloseIcon: true,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingTasks = false;
        });
      }
    }
  }

  Widget _buildTaskItem(
    ThemeData theme,
    TaskPlanItem task,
    int index,
    bool isExpanded,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final iconMap = {
      0: Icons.search,
      1: Icons.analytics,
      2: Icons.description,
      3: Icons.code,
      4: Icons.check_circle,
    };

    final icon = iconMap[index % iconMap.length] ?? Icons.task_alt;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedTasks.remove(index);
                } else {
                  _expandedTasks.add(index);
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // 圖示
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 標題和資訊
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.timer,
                                  size: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.pomodoroCountText(task.pomodoroCount),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            _buildPriorityChip(theme, task.priority),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 展開圖示
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          // 展開的步驟詳情
          if (isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(52, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (task.description.isNotEmpty) ...[
                    Text(
                      task.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (task.steps.isNotEmpty) ...[
                    ...task.steps.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${entry.key + 1}.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPriorityChip(ThemeData theme, String priority) {
    final l10n = AppLocalizations.of(context)!;
    Color color;
    String label;

    switch (priority.toLowerCase()) {
      case 'high':
        color = theme.colorScheme.error;
        label = l10n.priorityHigh;
        break;
      case 'low':
        color = theme.colorScheme.primary;
        label = l10n.priorityLow;
        break;
      default:
        color = theme.colorScheme.tertiary;
        label = l10n.priorityMedium;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}
