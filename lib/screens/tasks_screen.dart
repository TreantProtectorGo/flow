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
import '../services/calendar_service.dart';
import 'ai_chat_screen.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});
  static const CalendarService _calendarService = CalendarService();
  static const Duration _aiSessionGap = Duration(minutes: 2);

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

                          // In-progress tasks (exclude the currently running task to avoid duplicate)
                          if (taskNotifier.inProgressTasks
                              .where(
                                (task) =>
                                    !(currentTask != null &&
                                        isTimerRunning &&
                                        task.id == currentTask.id),
                              )
                              .isNotEmpty) ...[
                            _buildSectionHeader(l10n.inProgress, theme),
                            const SizedBox(height: 15),
                            ...taskNotifier.inProgressTasks
                                .where(
                                  (task) =>
                                      !(currentTask != null &&
                                          isTimerRunning &&
                                          task.id == currentTask.id),
                                )
                                .map(
                                  (task) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
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

                          if (taskNotifier.pendingTasks.isEmpty)
                            _buildEmptyState(l10n.emptyPendingTasks, theme)
                          else
                            ..._buildPendingTaskWidgets(
                              tasks: taskNotifier.pendingTasks,
                              theme: theme,
                              context: context,
                              ref: ref,
                              l10n: l10n,
                            ),

                          const SizedBox(height: 30),

                          // Completed tasks
                          if (taskNotifier.completedTasks.isNotEmpty) ...[
                            _buildSectionHeader(l10n.completed, theme),
                            const SizedBox(height: 15),
                            ...taskNotifier.completedTasks.map(
                              (task) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
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

      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // AI Chat FAB - always visible
          FloatingActionButton(
            onPressed: () => _openAIChatScreen(context),
            heroTag: "aiChatButton",
            backgroundColor: theme.colorScheme.secondaryContainer,
            foregroundColor: theme.colorScheme.onSecondaryContainer,
            shape: const CircleBorder(),
            child: const Icon(Icons.auto_awesome),
          ),
          const SizedBox(height: 15),
          // Add Task FAB
          FloatingActionButton.extended(
            onPressed: () => _showAddTaskDialog(context, ref),
            heroTag: "addTaskButton",
            icon: const Icon(Icons.add),
            label: Text(l10n.add),
          ),
          const SizedBox(height: 10),
        ],
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

    if (result != null && context.mounted) {
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
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
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
                                  .withValues(alpha: 0.7),
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
                const SizedBox(height: 8),
                // Pomodoro progress display
                Row(
                  children: [
                    Text(
                      l10n.pomodoroProgress(
                        task.completedPomodoros,
                        task.pomodoroCount,
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer.withValues(
                          alpha: 0.8,
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (task.completedPomodoros >= task.pomodoroCount)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.check_circle,
                          size: 14,
                          color: theme.colorScheme.tertiary,
                        ),
                      ),
                  ],
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
                          backgroundColor: theme.colorScheme.surface.withValues(
                            alpha: 0.3,
                          ),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.tonalIcon(
                      onPressed: () => _quickAddTaskToCalendar(
                        context,
                        task,
                        timerNotifier.focusTimeInMinutes,
                        l10n,
                      ),
                      icon: const Icon(Icons.calendar_month, size: 16),
                      label: Text(l10n.addToCalendar),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
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
    AppLocalizations l10n, {
    bool showCalendarButton = true,
  }) {
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

    // Calculate pomodoro progress
    final pomodoroProgress = task.completedPomodoros / task.pomodoroCount;
    final progressColor = pomodoroProgress >= 1.0
        ? theme.colorScheme.tertiary
        : theme.colorScheme.primary;

    return Dismissible(
      key: Key(task.id),
      direction: task.status != TaskStatus.completed
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          Icons.check,
          color: theme.colorScheme.onTertiaryContainer,
          size: 32,
        ),
      ),
      confirmDismiss: (direction) async {
        // Mark as completed directly
        await ref.read(taskProvider.notifier).markTaskAsCompleted(task.id);
        return false; // Don't actually dismiss, just update state
      },
      child: Card(
        elevation: isCurrentTask ? 4 : 2,
        margin: EdgeInsets.zero,
        surfaceTintColor: theme.colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isCurrentTask
              ? BorderSide(color: theme.colorScheme.primary, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: () => _showEditTaskDialog(context, ref, task),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: task.status == TaskStatus.completed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    if (task.status != TaskStatus.completed) ...[
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () =>
                            _startPomodoroForTask(context, ref, task, l10n),
                        icon: Icon(
                          isCurrentTask ? Icons.play_arrow : Icons.timer,
                          size: 16,
                        ),
                        label: Text(
                          isCurrentTask ? l10n.continueButton : l10n.start,
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 28),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          backgroundColor: isCurrentTask
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primaryContainer,
                          foregroundColor: isCurrentTask
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ],
                ),
                if (task.description != null &&
                    task.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    task.description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (isTimerRunning ||
                    (task.status != TaskStatus.completed &&
                        (!task.isAIGenerated || showCalendarButton))) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isTimerRunning)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.timer,
                                  size: 13,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${l10n.focusingNow} ${timerNotifier.timeDisplayString}',
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          theme.colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w700,
                                      fontFeatures: [
                                        const FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (task.status != TaskStatus.completed &&
                          !isTimerRunning &&
                          showCalendarButton) ...[
                        if (isTimerRunning) const SizedBox(width: 6),
                        IconButton.filledTonal(
                          onPressed: () => _quickAddTaskToCalendar(
                            context,
                            task,
                            timerNotifier.focusTimeInMinutes,
                            l10n,
                          ),
                          icon: const Icon(Icons.calendar_month, size: 16),
                          tooltip: l10n.addToCalendar,
                          style: IconButton.styleFrom(
                            minimumSize: const Size(28, 28),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                      if (task.status != TaskStatus.completed &&
                          !task.isAIGenerated) ...[
                        if (isTimerRunning ||
                            (!isTimerRunning && showCalendarButton))
                          const SizedBox(width: 4),
                        IconButton(
                          onPressed: () => _openAIChatWithTask(context, task),
                          icon: Icon(
                            Icons.auto_awesome,
                            size: 18,
                            color: theme.colorScheme.secondary,
                          ),
                          tooltip: l10n.breakdownWithAI,
                          style: IconButton.styleFrom(
                            minimumSize: const Size(28, 28),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            l10n.pomodoroProgress(
                              task.completedPomodoros,
                              task.pomodoroCount,
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: progressColor,
                            ),
                          ),
                          if (task.completedPomodoros >= task.pomodoroCount)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.check_circle,
                                size: 14,
                                color: theme.colorScheme.tertiary,
                              ),
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pomodoroProgress.clamp(0.0, 1.0),
                                minHeight: 3,
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  progressColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      labelPadding: const EdgeInsets.symmetric(
                        horizontal: 1,
                        vertical: -2,
                      ),
                      padding: EdgeInsets.zero,
                      backgroundColor: priorityBackgroundColor,
                      label: Text(
                        task.priorityText(l10n),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: priorityColor,
                          fontSize: 9,
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
      ),
    );
  }

  void _openAIChatWithTask(BuildContext context, Task task) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => AIChatScreen(
          initialMessage:
              '請幫我拆解這個任務：${task.title}${task.description != null ? '\n描述：${task.description}' : ''}',
        ),
        fullscreenDialog: true,
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

  Future<void> _quickAddTaskToCalendar(
    BuildContext context,
    Task task,
    int focusMinutes,
    AppLocalizations l10n,
  ) async {
    try {
      final added = await _calendarService.quickAddTask(
        task,
        focusMinutes: focusMinutes,
      );
      if (!context.mounted) {
        return;
      }

      switch (added) {
        case CalendarAddResult.saved:
          SnackBarUtil.showSuccessSnackBar(
            context,
            message: l10n.calendarAdded(task.title),
          );
          break;
        case CalendarAddResult.opened:
          SnackBarUtil.showInfoSnackBar(
            context,
            message: l10n.calendarOpened(task.title),
          );
          break;
        case CalendarAddResult.canceled:
          SnackBarUtil.showInfoSnackBar(
            context,
            message: l10n.calendarAddCancelled,
          );
          break;
        case CalendarAddResult.duplicate:
          SnackBarUtil.showInfoSnackBar(
            context,
            message: l10n.calendarAlreadyAdded,
          );
          break;
        case CalendarAddResult.failed:
          SnackBarUtil.showErrorSnackBar(
            context,
            message: l10n.calendarAddFailed,
          );
          break;
      }
    } catch (_) {
      if (context.mounted) {
        SnackBarUtil.showErrorSnackBar(
          context,
          message: l10n.calendarAddFailed,
        );
      }
    }
  }

  List<Widget> _buildPendingTaskWidgets({
    required List<Task> tasks,
    required ThemeData theme,
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
  }) {
    final groups = _groupPendingTasks(tasks);
    final focusMinutes = ref.watch(timerProvider).focusTimeInMinutes;
    final widgets = <Widget>[];

    for (final group in groups) {
      if (group.isAiSessionGroup) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildAiSessionToggleCard(
              group: group,
              theme: theme,
              context: context,
              ref: ref,
              l10n: l10n,
              onAddToCalendar: () => _quickAddTaskGroupToCalendar(
                context,
                group,
                focusMinutes,
                l10n,
              ),
              onDeleteSession: () => _deleteTaskGroup(context, ref, group),
            ),
          ),
        );
      } else {
        for (final task in group.tasks) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildTaskCard(
                task,
                theme,
                context,
                ref,
                l10n,
                showCalendarButton: true,
              ),
            ),
          );
        }
      }
    }

    return widgets;
  }

  List<_TaskGroup> _groupPendingTasks(List<Task> tasks) {
    final groups = <_TaskGroup>[];
    var index = 0;

    while (index < tasks.length) {
      final task = tasks[index];
      if (!task.isAIGenerated) {
        groups.add(
          _TaskGroup(
            tasks: [task],
            isAiSessionGroup: false,
            sessionTitle: null,
            sessionId: null,
          ),
        );
        index += 1;
        continue;
      }

      final aiTasks = <Task>[task];
      var cursor = index + 1;
      var previous = task;
      final seedSessionId = task.aiSessionId;

      while (cursor < tasks.length) {
        final candidate = tasks[cursor];
        if (!candidate.isAIGenerated) {
          break;
        }

        if (seedSessionId != null && seedSessionId.isNotEmpty) {
          if (candidate.aiSessionId != seedSessionId) {
            break;
          }
        } else {
          final gap = previous.createdAt.difference(candidate.createdAt).abs();
          if (gap > _aiSessionGap) {
            break;
          }
        }

        aiTasks.add(candidate);
        previous = candidate;
        cursor += 1;
      }

      final aiTitle = task.aiSessionTitle?.trim();
      groups.add(
        _TaskGroup(
          tasks: aiTasks,
          isAiSessionGroup: aiTasks.length > 1,
          sessionTitle: (aiTitle != null && aiTitle.isNotEmpty)
              ? aiTitle
              : null,
          sessionId: seedSessionId,
        ),
      );
      index = cursor;
    }

    return groups;
  }

  Widget _buildAiSessionToggleCard({
    required _TaskGroup group,
    required ThemeData theme,
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
    required VoidCallback onAddToCalendar,
    required VoidCallback onDeleteSession,
  }) {
    final tasks = group.tasks;
    final groupTitle = group.sessionTitle ?? l10n.aiSessionGroup(tasks.length);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      surfaceTintColor: theme.colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          collapsedIconColor: theme.colorScheme.onSecondaryContainer,
          iconColor: theme.colorScheme.onSecondaryContainer,
          backgroundColor: theme.colorScheme.surface,
          collapsedBackgroundColor: theme.colorScheme.secondaryContainer
              .withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 18,
                color: theme.colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  groupTitle,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Text(
            l10n.aiSessionToggleHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.filledTonal(
                onPressed: onAddToCalendar,
                icon: const Icon(Icons.calendar_month, size: 18),
                tooltip: l10n.addToCalendar,
                style: IconButton.styleFrom(
                  minimumSize: const Size(36, 36),
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: onDeleteSession,
                icon: const Icon(Icons.delete_outline, size: 18),
                tooltip: l10n.delete,
                style: IconButton.styleFrom(
                  minimumSize: const Size(36, 36),
                  padding: EdgeInsets.zero,
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
            ],
          ),
          children: tasks
              .map(
                (task) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _buildTaskCard(
                    task,
                    theme,
                    context,
                    ref,
                    l10n,
                    showCalendarButton: false,
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Future<void> _quickAddTaskGroupToCalendar(
    BuildContext context,
    _TaskGroup group,
    int focusMinutes,
    AppLocalizations l10n,
  ) async {
    final tasks = group.tasks;
    if (tasks.isEmpty) {
      return;
    }

    try {
      final entries = tasks
          .map(
            (task) => CalendarPlanEntry(
              title: task.title,
              description: task.description?.trim() ?? '',
              pomodoroCount: task.pomodoroCount,
            ),
          )
          .toList();

      final startFrom = DateTime.now();
      final looksMultiDay = tasks.length > 1;
      final groupTitle =
          group.sessionTitle ?? l10n.aiSessionGroup(tasks.length);
      final added = await _calendarService.quickAddPlanEntries(
        planTitle: groupTitle,
        entries: entries,
        focusMinutes: focusMinutes,
        startFrom: startFrom,
        scheduleMode: looksMultiDay
            ? CalendarPlanScheduleMode.spreadByDay
            : CalendarPlanScheduleMode.singleDay,
        spreadDays: looksMultiDay ? tasks.length : 1,
      );

      if (!context.mounted) {
        return;
      }

      switch (added) {
        case CalendarAddResult.saved:
          SnackBarUtil.showSuccessSnackBar(
            context,
            message: l10n.calendarAdded(groupTitle),
          );
          break;
        case CalendarAddResult.opened:
          SnackBarUtil.showInfoSnackBar(
            context,
            message: l10n.calendarOpened(groupTitle),
          );
          break;
        case CalendarAddResult.canceled:
          SnackBarUtil.showInfoSnackBar(
            context,
            message: l10n.calendarAddCancelled,
          );
          break;
        case CalendarAddResult.duplicate:
          SnackBarUtil.showInfoSnackBar(
            context,
            message: l10n.calendarAlreadyAdded,
          );
          break;
        case CalendarAddResult.failed:
          SnackBarUtil.showErrorSnackBar(
            context,
            message: l10n.calendarAddFailed,
          );
          break;
      }
    } catch (_) {
      if (context.mounted) {
        SnackBarUtil.showErrorSnackBar(
          context,
          message: l10n.calendarAddFailed,
        );
      }
    }
  }

  Future<void> _deleteTaskGroup(
    BuildContext context,
    WidgetRef ref,
    _TaskGroup group,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final title = group.sessionTitle ?? l10n.aiSessionGroup(group.tasks.length);
    final confirmed = await DeleteConfirmationDialog.show(
      context,
      title: title,
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    final notifier = ref.read(taskProvider.notifier);
    final currentTaskId = ref.read(taskProvider).currentTaskId;
    final containsCurrent = group.tasks.any((task) => task.id == currentTaskId);
    if (containsCurrent) {
      await notifier.setCurrentTask(null);
    }

    for (final task in group.tasks) {
      await notifier.deleteTask(task.id);
    }
  }
}

class _TaskGroup {
  final List<Task> tasks;
  final bool isAiSessionGroup;
  final String? sessionTitle;
  final String? sessionId;

  const _TaskGroup({
    required this.tasks,
    required this.isAiSessionGroup,
    required this.sessionTitle,
    required this.sessionId,
  });
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
