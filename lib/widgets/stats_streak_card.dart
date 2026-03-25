import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// 連續天數顯示 Widget
class StatsStreakCard extends StatelessWidget {
  final int streakDays;
  final int todayCompleted;

  const StatsStreakCard({
    super.key,
    required this.streakDays,
    required this.todayCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final accent = theme.colorScheme.tertiary;
    final onAccent = theme.colorScheme.onTertiary;

    IconData getStreakIcon() {
      if (streakDays == 0) {
        return Icons.spa_rounded;
      }

      return Icons.local_fire_department_rounded;
    }

    String getStreakMessage() {
      if (streakDays == 0) {
        return todayCompleted > 0
            ? l10n.startNewStreakToday
            : l10n.completeOnePomodoroToStartStreak;
      }
      if (streakDays == 1) return l10n.goodStart;
      if (streakDays < 7) return l10n.keepGoing;
      if (streakDays < 30) return l10n.awesome;
      if (streakDays < 100) return l10n.focusMaster;
      return l10n.legendaryStreak;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: streakDays > 0
              ? [
                  theme.colorScheme.tertiaryContainer,
                  theme.colorScheme.surfaceContainerHigh,
                ]
              : [
                  theme.colorScheme.surfaceContainerHighest,
                  theme.colorScheme.surfaceContainer,
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: streakDays > 0
              ? accent.withValues(alpha: 0.4)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // 左側：連續天數圖示
          Icon(
            getStreakIcon(),
            size: 46,
            color: streakDays > 0 ? accent : theme.colorScheme.primary,
          ),
          const SizedBox(width: 16),
          // 中間：數字和標題
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$streakDays',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: streakDays > 0
                            ? accent
                            : theme.colorScheme.onSurface,
                        fontSize: 36,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        l10n.days,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: streakDays > 0
                              ? accent.withValues(alpha: 0.85)
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.consecutiveFocus,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                // 鼓勵訊息
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: streakDays > 0
                        ? onAccent.withValues(alpha: 0.12)
                        : theme.colorScheme.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    getStreakMessage(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
