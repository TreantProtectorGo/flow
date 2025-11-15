import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/timer_provider.dart';
import '../widgets/task_form_dialog.dart';
import '../l10n/app_localizations.dart';
import 'ai_chat_screen.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final taskNotifier = ref.watch(taskProvider);
    final timerNotifier = ref.watch(timerProvider);
    final currentTask = taskNotifier.currentTask;
    final isTimerRunning = timerNotifier.isRunning;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // 内容区域
            Expanded(
              child: taskNotifier.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 當前計時任務卡片（置頂顯示）
                          if (currentTask != null && isTimerRunning)
                            _buildActiveTimerCard(
                              currentTask,
                              timerNotifier,
                              theme,
                              context,
                              ref,
                              l10n,
                            ),

                          if (currentTask != null && isTimerRunning)
                            const SizedBox(height: 20),

                          // 进行中任务
                          if (taskNotifier.inProgressTasks.isNotEmpty) ...[
                            _buildSectionHeader(l10n.inProgress, theme),
                            const SizedBox(height: 15),
                            ...taskNotifier.inProgressTasks.map(
                              (task) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildTaskCard(
                                  task,
                                  theme,
                                  context,
                                  ref,
                                  l10n,
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                          ],

                          // 待办事项
                          _buildSectionHeader(l10n.pending, theme),
                          const SizedBox(height: 15),

                          // AI 拆解卡片
                          _buildAIBreakdownCard(theme, context, l10n),
                          const SizedBox(height: 12),

                          if (taskNotifier.pendingTasks.isEmpty)
                            _buildEmptyState(l10n.emptyPendingTasks, theme)
                          else
                            ...taskNotifier.pendingTasks.map(
                              (task) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildTaskCard(
                                  task,
                                  theme,
                                  context,
                                  ref,
                                  l10n,
                                ),
                              ),
                            ),

                          const SizedBox(height: 30),

                          // 已完成
                          if (taskNotifier.completedTasks.isNotEmpty) ...[
                            _buildSectionHeader(l10n.completed, theme),
                            const SizedBox(height: 15),
                            ...taskNotifier.completedTasks.map(
                              (task) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Opacity(
                                  opacity: 0.6,
                                  child: _buildTaskCard(
                                    task,
                                    theme,
                                    context,
                                    ref,
                                    l10n,
                                  ),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(
                            height: 100,
                          ), // Add bottom padding for FAB
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskDialog(context, ref),
        heroTag: "addTaskButton",
        icon: const Icon(Icons.add),
        label: Text(l10n.addTask),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const TaskFormDialog(),
    );

    if (result != null) {
      await ref
          .read(taskProvider.notifier)
          .addTask(
            title: result['title'],
            description: result['description'],
            pomodoroCount: result['pomodoroCount'],
            priority: result['priority'],
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.taskAdded(result['title'])),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _openAIChatScreen(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AIChatScreen()));
  }

  void _showEditTaskDialog(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => TaskFormDialog(task: task),
    );

    if (result != null) {
      final updatedTask = task.copyWith(
        title: result['title'],
        description: result['description'],
        pomodoroCount: result['pomodoroCount'],
        priority: result['priority'],
        status: result['status'],
      );

      await ref.read(taskProvider.notifier).updateTask(updatedTask);
    }
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteTask),
        content: Text(l10n.confirmDelete(task.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(taskProvider.notifier).deleteTask(task.id);
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.task_alt, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveTimerCard(
    Task task,
    TimerProvider timerNotifier,
    ThemeData theme,
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go('/timer'),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.timer,
                        color: theme.colorScheme.onPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.focusingNow,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _getModeDisplay(timerNotifier.mode, l10n),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer
                                  .withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      timerNotifier.timeDisplayString,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  task.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: timerNotifier.progress,
                          minHeight: 8,
                          backgroundColor: theme.colorScheme.surface
                              .withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () => context.go('/timer'),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: Text(l10n.view),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(
    Task task,
    ThemeData theme,
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final taskNotifier = ref.watch(taskProvider);
    final timerNotifier = ref.watch(timerProvider);
    final isCurrentTask = taskNotifier.currentTaskId == task.id;
    final isTimerRunning = timerNotifier.isRunning && isCurrentTask;

    Color priorityColor;
    Color priorityBackgroundColor;

    switch (task.priority) {
      case TaskPriority.high:
        priorityColor = theme.colorScheme.error;
        priorityBackgroundColor = theme.colorScheme.errorContainer;
        break;
      case TaskPriority.medium:
        priorityColor = theme.colorScheme.tertiary;
        priorityBackgroundColor = theme.colorScheme.tertiaryContainer;
        break;
      case TaskPriority.low:
        priorityColor = theme.colorScheme.primary;
        priorityBackgroundColor = theme.colorScheme.primaryContainer;
        break;
    }

    return Card(
      elevation: isCurrentTask ? 4 : 2,
      margin: EdgeInsets.zero,
      surfaceTintColor: theme.colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCurrentTask
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showEditTaskDialog(context, ref, task),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (isTimerRunning) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.timer,
                                size: 14,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n.timerRunning(
                                  timerNotifier.timeDisplayString,
                                ),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // 開始番茄鐘按鈕
                  if (task.status != TaskStatus.completed)
                    FilledButton.icon(
                      onPressed: () =>
                          _startPomodoroForTask(context, ref, task, l10n),
                      icon: Icon(
                        isCurrentTask ? Icons.play_arrow : Icons.timer,
                        size: 18,
                      ),
                      label: Text(
                        isCurrentTask ? l10n.continueButton : l10n.start,
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        backgroundColor: isCurrentTask
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primaryContainer,
                        foregroundColor: isCurrentTask
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showEditTaskDialog(context, ref, task);
                          break;
                        case 'complete':
                          ref
                              .read(taskProvider.notifier)
                              .toggleTaskStatus(task.id);
                          break;
                        case 'delete':
                          _showDeleteConfirmDialog(context, ref, task);
                          break;
                        case 'ai_analysis':
                          _showAIAnalysisDialog(context, task, theme, l10n);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit),
                            const SizedBox(width: 8),
                            Text(l10n.edit),
                          ],
                        ),
                      ),
                      if (task.status != TaskStatus.completed)
                        PopupMenuItem(
                          value: 'complete',
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle),
                              const SizedBox(width: 8),
                              Text(l10n.markComplete),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'ai_analysis',
                        child: Row(
                          children: [
                            const Icon(Icons.psychology),
                            const SizedBox(width: 8),
                            Text(l10n.aiAnalysis),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(
                              l10n.delete,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.pomodoroCountText(task.pomodoroCount),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(width: 15),
                  Chip(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    labelPadding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: -2,
                    ),
                    padding: EdgeInsets.zero,
                    backgroundColor: priorityBackgroundColor,
                    label: Text(
                      task.priorityText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: priorityColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAIAnalysisDialog(
    BuildContext context,
    Task task,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.psychology, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(l10n.aiTaskAnalysis, style: theme.textTheme.titleLarge),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${l10n.taskName}: ${task.title}'),
            const SizedBox(height: 10),
            Text(
              '${l10n.estimatedTime}: ${task.pomodoroCount} ${l10n.items}（${task.pomodoroCount * 25} ${l10n.minuteShort}）',
            ),
            const SizedBox(height: 10),
            Text('${l10n.priority}: ${task.priorityText}'),
            const SizedBox(height: 10),
            Text('${l10n.status}: ${task.statusText}'),
            const SizedBox(height: 15),
            Text('${l10n.aiSuggestions}:', style: theme.textTheme.titleMedium),
            const SizedBox(height: 5),
            Text(l10n.breakIntoSteps),
            Text(l10n.takeBreaks),
            Text(l10n.setClearStandards),
            if (task.priority == TaskPriority.high)
              Text(l10n.highPrioritySuggestion),
            if (task.pomodoroCount > 4) Text(l10n.longTaskSuggestion),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  void _startPomodoroForTask(
    BuildContext context,
    WidgetRef ref,
    Task task,
    AppLocalizations l10n,
  ) {
    final taskNotifier = ref.read(taskProvider.notifier);
    final timerNotifier = ref.read(timerProvider.notifier);
    final isCurrentTask = ref.read(taskProvider).currentTaskId == task.id;

    // 設置為當前任務
    taskNotifier.setCurrentTask(task.id);

    // 如果不是當前任務，或計時器已停止，則重置並開始
    if (!isCurrentTask || ref.read(timerProvider).isStopped) {
      // 切換到番茄鐘畫面
      context.go('/timer');

      // 自動開始計時
      Future.delayed(const Duration(milliseconds: 300), () {
        timerNotifier.startTimer();
      });

      // 顯示提示訊息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.startFocus(task.title)),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // 已經是當前任務，只切換畫面
      context.go('/timer');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.continueTask(task.title)),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildAIBreakdownCard(
    ThemeData theme,
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          _openAIChatScreen(context);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.aiBreakdownDescription,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _getModeDisplay(TimerMode mode, AppLocalizations l10n) {
  switch (mode) {
    case TimerMode.focus:
      return l10n.focusMode;
    case TimerMode.shortBreak:
      return l10n.shortBreakMode;
    case TimerMode.longBreak:
      return l10n.longBreakMode;
  }
}
