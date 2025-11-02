import 'package:flutter/material.dart';

/// 快速成就卡片
class StatsAchievementCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUnlocked;
  final String? progress; // 例如 "8/10"

  const StatsAchievementCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.isUnlocked = false,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked
            ? color.withOpacity(0.1)
            : theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: isUnlocked
            ? Border.all(color: color.withOpacity(0.3), width: 2)
            : null,
      ),
      child: Row(
        children: [
          // 圖示
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? color.withOpacity(0.2)
                  : theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isUnlocked ? color : theme.colorScheme.outline,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          // 文字資訊
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isUnlocked
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (isUnlocked)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '✓',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isUnlocked
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.outline,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (progress != null && !isUnlocked) ...[
                  const SizedBox(height: 8),
                  Text(
                    progress!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 成就列表區塊
class StatsAchievementsSection extends StatelessWidget {
  final int totalPomodoros;
  final int streakDays;
  final int todayCompleted;

  const StatsAchievementsSection({
    super.key,
    required this.totalPomodoros,
    required this.streakDays,
    required this.todayCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final achievements = [
      {
        'title': '首次專注',
        'description': '完成第一個番茄鐘',
        'icon': Icons.star,
        'color': Colors.yellow.shade700,
        'isUnlocked': totalPomodoros >= 1,
      },
      {
        'title': '十全十美',
        'description': '累積完成 10 個番茄鐘',
        'icon': Icons.emoji_events,
        'color': Colors.orange,
        'isUnlocked': totalPomodoros >= 10,
        'progress': totalPomodoros < 10 ? '$totalPomodoros/10' : null,
      },
      {
        'title': '百里挑一',
        'description': '累積完成 100 個番茄鐘',
        'icon': Icons.military_tech,
        'color': Colors.purple,
        'isUnlocked': totalPomodoros >= 100,
        'progress': totalPomodoros < 100 ? '$totalPomodoros/100' : null,
      },
      {
        'title': '連續三天',
        'description': '連續三天完成番茄鐘',
        'icon': Icons.local_fire_department,
        'color': Colors.deepOrange,
        'isUnlocked': streakDays >= 3,
        'progress': streakDays < 3 ? '$streakDays/3 天' : null,
      },
      {
        'title': '一週挑戰',
        'description': '連續一週完成番茄鐘',
        'icon': Icons.whatshot,
        'color': Colors.red,
        'isUnlocked': streakDays >= 7,
        'progress': streakDays < 7 ? '$streakDays/7 天' : null,
      },
      {
        'title': '今日目標',
        'description': '今天完成 8 個番茄鐘',
        'icon': Icons.today,
        'color': Colors.blue,
        'isUnlocked': todayCompleted >= 8,
        'progress': todayCompleted < 8 ? '$todayCompleted/8' : null,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: achievements.map((achievement) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: StatsAchievementCard(
            title: achievement['title'] as String,
            description: achievement['description'] as String,
            icon: achievement['icon'] as IconData,
            color: achievement['color'] as Color,
            isUnlocked: achievement['isUnlocked'] as bool,
            progress: achievement['progress'] as String?,
          ),
        );
      }).toList(),
    );
  }
}
