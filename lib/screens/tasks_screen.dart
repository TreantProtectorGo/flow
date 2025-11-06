import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/timer_provider.dart';
import '../widgets/task_form_dialog.dart';
import 'ai_chat_screen.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
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
                            ),

                          if (currentTask != null && isTimerRunning)
                            const SizedBox(height: 20),

                          // 进行中任务
                          if (taskNotifier.inProgressTasks.isNotEmpty) ...[
                            _buildSectionHeader('進行中', theme),
                            const SizedBox(height: 15),
                            ...taskNotifier.inProgressTasks.map(
                              (task) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildTaskCard(
                                  task,
                                  theme,
                                  context,
                                  ref,
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                          ],

                          // 待办事项
                          _buildSectionHeader('待辦事項', theme),
                          const SizedBox(height: 15),

                          // AI 拆解卡片
                          _buildAIBreakdownCard(theme, context),
                          const SizedBox(height: 12),

                          if (taskNotifier.pendingTasks.isEmpty)
                            _buildEmptyState('暫無待辦任務', theme)
                          else
                            ...taskNotifier.pendingTasks.map(
                              (task) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildTaskCard(
                                  task,
                                  theme,
                                  context,
                                  ref,
                                ),
                              ),
                            ),

                          const SizedBox(height: 30),

                          // 已完成
                          if (taskNotifier.completedTasks.isNotEmpty) ...[
                            _buildSectionHeader('已完成', theme),
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
        label: const Text('新增任務'),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, WidgetRef ref) async {
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
            content: Text('已新增任務：${result['title']}'),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除任務'),
        content: Text('確定要刪除「${task.title}」嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(taskProvider.notifier).deleteTask(task.id);
            },
            child: const Text('刪除'),
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
                            '正在專注',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            timerNotifier.modeDisplayString,
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
                      label: const Text('查看'),
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
                            decoration: task.status == TaskStatus.completed
                                ? TextDecoration.lineThrough
                                : null,
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
                                '計時中 ${timerNotifier.timeDisplayString}',
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
                          _startPomodoroForTask(context, ref, task),
                      icon: Icon(
                        isCurrentTask ? Icons.play_arrow : Icons.timer,
                        size: 18,
                      ),
                      label: Text(isCurrentTask ? '繼續' : '開始'),
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
                          _showAIAnalysisDialog(context, task, theme);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('編輯'),
                          ],
                        ),
                      ),
                      if (task.status != TaskStatus.completed)
                        const PopupMenuItem(
                          value: 'complete',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle),
                              SizedBox(width: 8),
                              Text('標記完成'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'ai_analysis',
                        child: Row(
                          children: [
                            Icon(Icons.psychology),
                            SizedBox(width: 8),
                            Text('AI 分析'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('刪除', style: TextStyle(color: Colors.red)),
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
                        '${task.pomodoroCount} 個番茄鐘',
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

  void _showAIAnalysisDialog(BuildContext context, Task task, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.psychology, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text('AI 任務分析', style: theme.textTheme.titleLarge),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('任務名稱: ${task.title}'),
            const SizedBox(height: 10),
            Text(
              '預估時間: ${task.pomodoroCount} 個番茄鐘（${task.pomodoroCount * 25} 分鐘）',
            ),
            const SizedBox(height: 10),
            Text('優先級: ${task.priorityText}'),
            const SizedBox(height: 10),
            Text('狀態: ${task.statusText}'),
            const SizedBox(height: 15),
            Text('AI 建議:', style: theme.textTheme.titleMedium),
            const SizedBox(height: 5),
            const Text('• 將任務分成小步驟以提高完成率'),
            const Text('• 每個番茄鐘後記得休息 5 分鐘'),
            const Text('• 設定明確的完成標準'),
            if (task.priority == TaskPriority.high)
              const Text('• 高優先級任務建議優先處理'),
            if (task.pomodoroCount > 4) const Text('• 長時間任務建議分階段執行'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }

  void _startPomodoroForTask(BuildContext context, WidgetRef ref, Task task) {
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
          content: Text('🍅 開始專注：${task.title}'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // 已經是當前任務，只切換畫面
      context.go('/timer');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('繼續任務：${task.title}'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildAIBreakdownCard(ThemeData theme, BuildContext context) {
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
                  '讓 AI 幫你拆解大任務',
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
