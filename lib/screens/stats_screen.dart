import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/statistics_provider.dart';
import '../widgets/stats_goal_card.dart';
import '../widgets/stats_streak_card.dart';
import '../widgets/stats_heatmap.dart';
import '../widgets/stats_time_of_day_chart.dart';
import '../widgets/stats_achievement_card.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = ref.watch(statisticsProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // 頭部
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('統計數據', style: theme.textTheme.headlineLarge),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      if (mounted) {
                        ref.read(statisticsProvider.notifier).loadStatistics();
                      }
                    },
                    tooltip: '重新整理',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Tab Bar
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: '今日'),
                Tab(text: '本週'),
                Tab(text: '本月'),
              ],
            ),

            // 內容
            Expanded(
              child: stats.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTodayView(context, theme, stats.state),
                        _buildWeekView(context, theme, stats.state),
                        _buildMonthView(context, theme, stats.state),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayView(
    BuildContext context,
    ThemeData theme,
    StatisticsState stats,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 連續天數卡片
          StatsStreakCard(
            streakDays: stats.streakDays,
            todayCompleted: stats.todayCompleted,
          ),

          const SizedBox(height: 20),

          // 每日目標進度
          StatsGoalCard(
            title: '今日目標',
            current: stats.todayCompleted,
            goal: stats.dailyGoal,
            icon: Icons.today,
            color: theme.colorScheme.primary,
          ),

          const SizedBox(height: 20),

          // 今日概覽卡片
          _buildSummaryCard(
            theme: theme,
            title: '今日概覽',
            stats: [
              _StatItem(
                icon: Icons.timer,
                label: '完成番茄鐘',
                value: '${stats.todayCompleted}',
                color: theme.colorScheme.primary,
              ),
              _StatItem(
                icon: Icons.schedule,
                label: '專注時間',
                value: '${stats.todayFocusMinutes} 分鐘',
                color: theme.colorScheme.secondary,
              ),
              _StatItem(
                icon: Icons.task_alt,
                label: '完成任務',
                value: '${stats.todayCompletedTasks}',
                color: theme.colorScheme.tertiary,
              ),
              _StatItem(
                icon: Icons.percent,
                label: '完成率',
                value: '${stats.todayCompletionRate.toStringAsFixed(0)}%',
                color: stats.todayCompletionRate >= 70
                    ? Colors.green
                    : stats.todayCompletionRate >= 40
                    ? Colors.orange
                    : Colors.red,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 今日時間分布
          _buildChartCard(
            theme: theme,
            title: '今日時間分布',
            child: SizedBox(
              height: 200,
              child: stats.todayCompleted > 0
                  ? PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: stats.todayCompleted.toDouble(),
                            title: '完成\n${stats.todayCompleted}',
                            color: theme.colorScheme.primary,
                            radius: 80,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (stats.todayIncomplete > 0)
                            PieChartSectionData(
                              value: stats.todayIncomplete.toDouble(),
                              title: '未完成\n${stats.todayIncomplete}',
                              color: theme.colorScheme.errorContainer,
                              radius: 70,
                              titleStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                        ],
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    )
                  : _buildEmptyState('今天還沒有完成任何番茄鐘', theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekView(
    BuildContext context,
    ThemeData theme,
    StatisticsState stats,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 本週概覽
          _buildSummaryCard(
            theme: theme,
            title: '本週概覽',
            stats: [
              _StatItem(
                icon: Icons.timer,
                label: '完成番茄鐘',
                value: '${stats.weekCompleted}',
                color: theme.colorScheme.primary,
              ),
              _StatItem(
                icon: Icons.schedule,
                label: '專注時間',
                value: '${(stats.weekFocusMinutes / 60).toStringAsFixed(1)} 小時',
                color: theme.colorScheme.secondary,
              ),
              _StatItem(
                icon: Icons.local_fire_department,
                label: '連續天數',
                value: '${stats.streakDays}',
                color: Colors.orange,
              ),
              _StatItem(
                icon: Icons.trending_up,
                label: '日均完成',
                value: '${(stats.weekCompleted / 7).toStringAsFixed(1)}',
                color: theme.colorScheme.tertiary,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 每週目標進度
          StatsGoalCard(
            title: '本週目標',
            current: stats.weekCompleted,
            goal: stats.weeklyGoal,
            icon: Icons.calendar_today,
            color: theme.colorScheme.secondary,
          ),

          const SizedBox(height: 20),

          // 最佳專注時段分析
          _buildChartCard(
            theme: theme,
            title: '最佳專注時段（最近 30 天）',
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StatsTimeOfDayChart(data: stats.timeOfDayStats),
            ),
          ),

          const SizedBox(height: 20),

          // 本週趨勢圖
          _buildChartCard(
            theme: theme,
            title: '本週趨勢',
            child: SizedBox(
              height: 250,
              child: stats.weeklyData.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(right: 20, top: 20),
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY:
                              (stats.weeklyData.values.reduce(
                                        (a, b) => a > b ? a : b,
                                      ) +
                                      2)
                                  .toDouble(),
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem:
                                  (group, groupIndex, rod, rodIndex) {
                                    final day = stats.weeklyData.keys.elementAt(
                                      group.x.toInt(),
                                    );
                                    return BarTooltipItem(
                                      '$day\n${rod.toY.toInt()} 個番茄鐘',
                                      const TextStyle(color: Colors.white),
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
                                  if (value.toInt() >= 0 &&
                                      value.toInt() < stats.weeklyData.length) {
                                    final day = stats.weeklyData.keys.elementAt(
                                      value.toInt(),
                                    );
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        day,
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    );
                                  }
                                  return const Text('');
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
                                    style: theme.textTheme.bodySmall,
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
                            horizontalInterval: 2,
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(
                            stats.weeklyData.length,
                            (index) => BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: stats.weeklyData.values
                                      .elementAt(index)
                                      .toDouble(),
                                  color: theme.colorScheme.primary,
                                  width: 30,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  : _buildEmptyState('本週還沒有統計資料', theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthView(
    BuildContext context,
    ThemeData theme,
    StatisticsState stats,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 本月概覽
          _buildSummaryCard(
            theme: theme,
            title: '本月概覽',
            stats: [
              _StatItem(
                icon: Icons.timer,
                label: '完成番茄鐘',
                value: '${stats.monthCompleted}',
                color: theme.colorScheme.primary,
              ),
              _StatItem(
                icon: Icons.schedule,
                label: '專注時間',
                value:
                    '${(stats.monthFocusMinutes / 60).toStringAsFixed(1)} 小時',
                color: theme.colorScheme.secondary,
              ),
              _StatItem(
                icon: Icons.calendar_today,
                label: '工作天數',
                value: '${stats.monthActiveDays}',
                color: theme.colorScheme.tertiary,
              ),
              _StatItem(
                icon: Icons.star,
                label: '最佳單日',
                value: '${stats.monthBestDay}',
                color: Colors.amber,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 月度熱力圖
          _buildChartCard(
            theme: theme,
            title: '月度專注熱力圖',
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StatsHeatmap(
                data: stats.heatmapData,
                baseColor: theme.colorScheme.primary,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 成就列表
          _buildChartCard(
            theme: theme,
            title: '成就與里程碑',
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StatsAchievementsSection(
                totalPomodoros: stats.monthCompleted + stats.weekCompleted,
                streakDays: stats.streakDays,
                todayCompleted: stats.todayCompleted,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 本月趨勢
          _buildChartCard(
            theme: theme,
            title: '本月趨勢',
            child: SizedBox(
              height: 250,
              child: stats.monthlyData.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(right: 10, top: 20),
                      child: LineChart(
                        LineChartData(
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {
                                  return LineTooltipItem(
                                    '${spot.y.toInt()} 個',
                                    const TextStyle(color: Colors.white),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                          ),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 5,
                                getTitlesWidget: (value, meta) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      value.toInt().toString(),
                                      style: theme.textTheme.bodySmall,
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
                                    style: theme.textTheme.bodySmall,
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
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: stats.monthlyData.entries
                                  .map(
                                    (e) => FlSpot(
                                      e.key.toDouble(),
                                      e.value.toDouble(),
                                    ),
                                  )
                                  .toList(),
                              isCurved: true,
                              color: theme.colorScheme.primary,
                              barWidth: 3,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: theme.colorScheme.primary.withOpacity(
                                  0.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _buildEmptyState('本月還沒有統計資料', theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required ThemeData theme,
    required String title,
    required List<_StatItem> stats,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: stats
                  .map((stat) => _buildStatItem(stat, theme))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(_StatItem stat, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: stat.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(stat.icon, color: stat.color, size: 22),
          const SizedBox(height: 6),
          Text(
            stat.value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: stat.color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            stat.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard({
    required ThemeData theme,
    required String title,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}
