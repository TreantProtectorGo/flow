import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';

/// 熱力圖 Widget（類似 GitHub contributions）
class StatsHeatmap extends StatelessWidget {
  final Map<String, int> data; // 'YYYY-MM-DD' -> count
  final Color baseColor;

  const StatsHeatmap({
    super.key,
    required this.data,
    this.baseColor = Colors.green,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // 計算最大值用於顏色分級
    final maxCount = data.values.isEmpty
        ? 0
        : data.values.reduce((a, b) => a > b ? a : b);

    // 取得最近 12 週的資料
    final now = DateTime.now();
    final weeks = <List<DateTime>>[];

    for (int week = 11; week >= 0; week--) {
      final weekDays = <DateTime>[];
      for (int day = 0; day < 7; day++) {
        final date = now.subtract(Duration(days: week * 7 + (6 - day)));
        weekDays.add(date);
      }
      weeks.add(weekDays);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 月份標籤
        Row(
          children: [
            const SizedBox(width: 40), // 空間給星期標籤
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _buildMonthLabels(weeks, theme),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 熱力圖
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 星期標籤
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildDayLabel(l10n.mondayShort, theme),
                _buildDayLabel(l10n.tuesdayShort, theme),
                _buildDayLabel(l10n.wednesdayShort, theme),
                _buildDayLabel(l10n.thursdayShort, theme),
                _buildDayLabel(l10n.fridayShort, theme),
                _buildDayLabel(l10n.saturdayShort, theme),
                _buildDayLabel(l10n.sundayShort, theme),
              ],
            ),
            const SizedBox(width: 8),
            // 熱力圖格子
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: weeks.map((week) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Column(
                        children: week.map((date) {
                          final dateStr = DateFormat('yyyy-MM-dd').format(date);
                          final count = data[dateStr] ?? 0;
                          final intensity = maxCount > 0
                              ? count / maxCount
                              : 0.0;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Tooltip(
                              message:
                                  '$dateStr\n${l10n.pomodoroCountShort(count)}',
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: _getColorForIntensity(
                                    intensity,
                                    theme,
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(
                                    color: theme.colorScheme.outline
                                        .withOpacity(0.2),
                                    width: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 圖例
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.less,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            ...[0.0, 0.25, 0.5, 0.75, 1.0].map((intensity) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _getColorForIntensity(intensity, theme),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                      width: 0.5,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(width: 8),
            Text(
              l10n.more,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDayLabel(String day, ThemeData theme) {
    return SizedBox(
      height: 20,
      width: 32,
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          day,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMonthLabels(List<List<DateTime>> weeks, ThemeData theme) {
    final labels = <Widget>[];
    String? lastMonth;

    for (final week in weeks) {
      final month = DateFormat('MMM').format(week.first);
      if (month != lastMonth) {
        labels.add(
          Text(
            month,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        );
        lastMonth = month;
      }
    }

    return labels;
  }

  Color _getColorForIntensity(double intensity, ThemeData theme) {
    if (intensity == 0) {
      return theme.colorScheme.surfaceContainer;
    } else if (intensity < 0.25) {
      return baseColor.withOpacity(0.3);
    } else if (intensity < 0.5) {
      return baseColor.withOpacity(0.5);
    } else if (intensity < 0.75) {
      return baseColor.withOpacity(0.7);
    } else {
      return baseColor;
    }
  }
}
