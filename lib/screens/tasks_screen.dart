import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/timer_provider.dart';
import '../widgets/task_form_dialog.dart';
import '../widgets/dialogs/delete_confirmation_dialog.dart';
import '../utils/snackbar_util.dart';
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
            // Content area with task list
            Expanded(
              child: taskNotifier.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Active timer task card (pinned at top)
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

                          // In-progress tasks
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

                          // Pending tasks
                          _buildSectionHeader(l10n.pending, theme),
                          const SizedBox(height: 15),

                          // AI breakdown card (only shown when there are no pending tasks)
                          if (taskNotifier.pendingTasks.isEmpty) ...[
                            _buildAIBreakdownCard(theme, context, l10n),
                            const SizedBox(height: 12),
                          ],

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

                          // Completed tasks
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
        icon: const Icon(Icons.auto_awesome),
        label: Text(l10n.add),
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
        SnackBarUtil.showSuccessSnackBar(
          context,
          message: l10n.taskAdded(result['title']),
        );
      }
    }
  }

  void _openAIChatScreen(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => const AIChatScreen(),
        fullscreenDialog: true,
      ),
    );
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
      // Check if this is a delete action
      if (result['action'] == 'delete') {
        _showDeleteConfirmDialog(context, ref, task);
        return;
      }

      // Update task with new values
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

  Future<void> _showDeleteConfirmDialog(
  BuildContext context,
  WidgetRef ref,
  Task task,
) async {
    final confirmed = await DeleteConfirmationDialog.show(
      context,
      title: task.title,
    );
    
    if (confirmed == true) {
      ref.read(taskProvider.notifier).deleteTask(task.id);
    }
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
                  // Start pomodoro button
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
                ],
              ),
              if (task.status != TaskStatus.completed) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref.read(taskProvider.notifier).toggleTaskStatus(task.id);
                    },
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: Text(l10n.markComplete),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
              ],
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
                      task.priorityText(l10n),
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

  void _startPomodoroForTask(
    BuildContext context,
    WidgetRef ref,
    Task task,
    AppLocalizations l10n,
  ) {
    final taskNotifier = ref.read(taskProvider.notifier);
    final timerNotifier = ref.read(timerProvider.notifier);
    final isCurrentTask = ref.read(taskProvider).currentTaskId == task.id;

// Set as current task
    taskNotifier.setCurrentTask(task.id);

    // If not current task or timer is stopped, reset and start
    if (!isCurrentTask || ref.read(timerProvider).isStopped) {
      // Switch to timer screen
      context.go('/timer');

      // Auto-start timer
      Future.delayed(const Duration(milliseconds: 300), () {
        timerNotifier.startTimer();
      });

      // Show notification message
      SnackBarUtil.showInfoSnackBar(
        context,
        message: l10n.startFocus(task.title),
      );
    } else {
      // Already current task, just switch screens
      context.go('/timer');

      SnackBarUtil.showInfoSnackBar(
        context,
        message: l10n.continueTask(task.title),
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
