import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// 最佳專注時段圖表 Widget
class StatsTimeOfDayChart extends StatelessWidget {
  final Map<String, int> data; // 'morning', 'afternoon', 'evening', 'night'

  const StatsTimeOfDayChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final morning = data['morning'] ?? 0;
    final afternoon = data['afternoon'] ?? 0;
    final evening = data['evening'] ?? 0;
    final night = data['night'] ?? 0;

    final total = morning + afternoon + evening + night;

    if (total == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(
                Icons.access_time,
                size: 48,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                '還沒有足夠的資料',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 找出最佳時段
    final timeSlots = [
      {
        'name': '早上',
        'value': morning,
        'time': '6:00-12:00',
        'icon': Icons.wb_sunny,
      },
      {
        'name': '下午',
        'value': afternoon,
        'time': '12:00-18:00',
        'icon': Icons.wb_twilight,
      },
      {
        'name': '傍晚',
        'value': evening,
        'time': '18:00-22:00',
        'icon': Icons.nightlight,
      },
      {
        'name': '深夜',
        'value': night,
        'time': '22:00-6:00',
        'icon': Icons.bedtime,
      },
    ];

    timeSlots.sort((a, b) => (b['value'] as int).compareTo(a['value'] as int));
    final bestTime = timeSlots.first;

    return Column(
      children: [
        // 最佳時段提示
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                bestTime['icon'] as IconData,
                color: theme.colorScheme.onPrimaryContainer,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '您的最佳專注時段',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer.withOpacity(
                          0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${bestTime['name']} ${bestTime['time']}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '已完成 ${bestTime['value']} 個番茄鐘',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer.withOpacity(
                          0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // 條形圖
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (timeSlots.first['value'] as int).toDouble() * 1.2,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final timeSlot = timeSlots[group.x.toInt()];
                    return BarTooltipItem(
                      '${timeSlot['name']}\n${timeSlot['value']} 個番茄鐘',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final timeSlot = timeSlots[value.toInt()];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          children: [
                            Icon(
                              timeSlot['icon'] as IconData,
                              size: 20,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeSlot['name'] as String,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 5,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: theme.colorScheme.outline.withOpacity(0.1),
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(4, (index) {
                final timeSlot = timeSlots[index];
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: (timeSlot['value'] as int).toDouble(),
                      color: index == 0
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primaryContainer,
                      width: 40,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}
