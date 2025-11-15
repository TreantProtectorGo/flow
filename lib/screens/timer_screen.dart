import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../providers/timer_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/task_selection_dialog.dart';
import '../models/task.dart';
import '../l10n/app_localizations.dart';

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _progressController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final timerNotifier = ref.watch(timerProvider);
    final taskNotifier = ref.watch(taskProvider);
    final currentTask = taskNotifier.currentTask;

    // Update animations based on timer state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _progressController.animateTo(timerNotifier.progress);

      if (timerNotifier.isRunning) {
        if (!_pulseController.isAnimating) {
          _pulseController.repeat(reverse: true);
        }
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    });

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // 主要内容區域
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Center(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                          maxWidth: 400,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 當前任務區域
                              _buildCurrentTaskSection(
                                theme,
                                currentTask,
                                l10n,
                              ),

                              const SizedBox(height: 40),

                              // 計時器區域 - Pass constraints for responsive sizing
                              _buildTimerSection(
                                theme,
                                timerNotifier,
                                constraints,
                                l10n,
                              ),

                              const SizedBox(height: 40),

                              // 控制按鈕區域
                              _buildControlButtons(theme, timerNotifier, l10n),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTaskSection(
    ThemeData theme,
    Task? currentTask,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.task_alt, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.currentTask,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _showTaskSelectionDialog,
                icon: const Icon(Icons.change_circle, size: 16),
                label: Text(l10n.switchTask),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (currentTask != null) ...[
            Text(
              currentTask.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            if (currentTask.description != null &&
                currentTask.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                currentTask.description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '${l10n.estimated} ${currentTask.pomodoroCount} ${l10n.pomodoros}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(
                      currentTask.priority,
                      theme,
                    ).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    currentTask.priorityText(l10n),
                    style: TextStyle(
                      fontSize: 10,
                      color: _getPriorityColor(currentTask.priority, theme),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              l10n.noTaskSelected,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildTimerSection(
    ThemeData theme,
    TimerProvider timerNotifier,
    BoxConstraints constraints,
    AppLocalizations l10n,
  ) {
    // Calculate responsive timer size
    final screenWidth = constraints.maxWidth;
    final availableWidth = screenWidth - 40; // Account for padding
    final maxSize = math.min(
      280.0,
      availableWidth * 0.8,
    ); // Max 80% of available width
    final timerSize = math.max(200.0, maxSize); // Minimum size of 200

    // Adjust font size based on timer size
    final fontSize = (timerSize / 280) * 48; // Scale font proportionally

    return Column(
      children: [
        // 圓形進度和時間顯示
        SizedBox(
          width: timerSize,
          height: timerSize,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: timerNotifier.isRunning ? _pulseAnimation.value : 1.0,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background circle
                    Container(
                      width: timerSize,
                      height: timerSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                      ),
                    ),

                    // Progress circle
                    SizedBox(
                      width: timerSize,
                      height: timerSize,
                      child: AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: CircularProgressPainter(
                              progress: _progressController.value,
                              color: timerNotifier.isFocusMode
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.secondary,
                              strokeWidth:
                                  (timerSize / 280) * 8, // Scale stroke width
                            ),
                          );
                        },
                      ),
                    ),

                    // Time display
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          timerNotifier.timeDisplayString,
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.w300,
                            fontSize: fontSize,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: timerNotifier.isFocusMode
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getModeDisplay(timerNotifier.mode, l10n),
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: timerNotifier.isFocusMode
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 24),

        // Session info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 20),
              Text(
                l10n.completedSessions(timerNotifier.completedSessions),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlButtons(
    ThemeData theme,
    TimerProvider timerNotifier,
    AppLocalizations l10n,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Stop/Reset button
        FilledButton.tonal(
          onPressed: timerNotifier.isStopped
              ? null
              : () {
                  ref.read(timerProvider.notifier).stopTimer();
                },
          style: FilledButton.styleFrom(minimumSize: const Size(80, 48)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.stop, size: 20),
              const SizedBox(width: 8),
              Text(l10n.reset),
            ],
          ),
        ),

        // Play/Pause button
        FilledButton(
          onPressed: () {
            if (timerNotifier.isRunning) {
              ref.read(timerProvider.notifier).pauseTimer();
            } else {
              ref.read(timerProvider.notifier).startTimer();
            }
          },
          style: FilledButton.styleFrom(minimumSize: const Size(120, 56)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                timerNotifier.isRunning ? Icons.pause : Icons.play_arrow,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                timerNotifier.isRunning ? l10n.pause : l10n.start,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),

        // Skip button
        FilledButton.tonal(
          onPressed: () {
            ref.read(timerProvider.notifier).skipTimer();
          },
          style: FilledButton.styleFrom(minimumSize: const Size(80, 48)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.skip_next, size: 20),
              const SizedBox(width: 8),
              Text(l10n.skip),
            ],
          ),
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

  void _showTaskSelectionDialog() async {
    final result = await showDialog<dynamic>(
      context: context,
      builder: (context) => const TaskSelectionDialog(),
    );

    if (result != null) {
      if (result == 'clear') {
        // 清除當前任務選擇
        ref.read(taskProvider.notifier).setCurrentTask(null);
      } else if (result is Task) {
        // 設置新的當前任務
        ref.read(taskProvider.notifier).setCurrentTask(result.id);
      }
    }
  }
}

// Custom painter for circular progress
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
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
