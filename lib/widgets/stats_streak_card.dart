import 'package:flutter/material.dart';

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

    // 根據連續天數顯示不同的火焰
    String getFlameEmoji() {
      if (streakDays == 0) return '🌱';
      if (streakDays < 3) return '🔥';
      if (streakDays < 7) return '🔥🔥';
      if (streakDays < 30) return '🔥🔥🔥';
      return '🔥🔥🔥🔥';
    }

    String getStreakMessage() {
      if (streakDays == 0) {
        return todayCompleted > 0 ? '今天開始新的連續記錄！' : '完成一個番茄鐘開始連續！';
      }
      if (streakDays == 1) return '好的開始！';
      if (streakDays < 7) return '繼續保持！';
      if (streakDays < 30) return '太棒了！';
      if (streakDays < 100) return '你是專注大師！';
      return '傳奇級連續記錄！';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: streakDays > 0
              ? [
                  Colors.orange.withOpacity(0.2),
                  Colors.deepOrange.withOpacity(0.1),
                ]
              : [
                  theme.colorScheme.surfaceContainerHighest,
                  theme.colorScheme.surfaceContainer,
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: streakDays > 0
              ? Colors.orange.withOpacity(0.3)
              : theme.colorScheme.outline.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // 左側：火焰 Emoji 和連續天數
          Text(getFlameEmoji(), style: const TextStyle(fontSize: 48)),
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
                            ? Colors.orange
                            : theme.colorScheme.onSurface,
                        fontSize: 36,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '天',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: streakDays > 0
                              ? Colors.orange.withOpacity(0.8)
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '連續專注',
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
                    color: theme.colorScheme.surface.withOpacity(0.5),
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
