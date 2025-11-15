import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';

// Riverpod provider
final statisticsProvider = ChangeNotifierProvider<StatisticsNotifier>((ref) {
  return StatisticsNotifier();
});

class StatisticsState {
  // 今日統計
  final int todayCompleted;
  final int todayIncomplete;
  final int todayFocusMinutes;
  final int todayCompletedTasks;
  final double todayCompletionRate;

  // 本週統計
  final int weekCompleted;
  final int weekIncomplete;
  final int weekFocusMinutes;
  final int streakDays;
  final Map<String, int> weeklyData; // 每日數據

  // 本月統計
  final int monthCompleted;
  final int monthIncomplete;
  final int monthFocusMinutes;
  final int monthActiveDays;
  final int monthBestDay;
  final Map<int, int> monthlyData; // 每日數據 (day -> count)

  // 新增：目標設定
  final int dailyGoal; // 每日目標番茄鐘數
  final int weeklyGoal; // 每週目標番茄鐘數

  // 新增：最佳專注時段分析
  final Map<String, int>
  timeOfDayStats; // 'morning', 'afternoon', 'evening', 'night'

  // 新增：熱力圖資料（最近 90 天）
  final Map<String, int> heatmapData; // 'YYYY-MM-DD' -> count

  final bool isLoading;
  final String? error;

  StatisticsState({
    this.todayCompleted = 0,
    this.todayIncomplete = 0,
    this.todayFocusMinutes = 0,
    this.todayCompletedTasks = 0,
    this.todayCompletionRate = 0.0,
    this.weekCompleted = 0,
    this.weekIncomplete = 0,
    this.weekFocusMinutes = 0,
    this.streakDays = 0,
    this.weeklyData = const {},
    this.monthCompleted = 0,
    this.monthIncomplete = 0,
    this.monthFocusMinutes = 0,
    this.monthActiveDays = 0,
    this.monthBestDay = 0,
    this.monthlyData = const {},
    this.dailyGoal = 8,
    this.weeklyGoal = 40,
    this.timeOfDayStats = const {},
    this.heatmapData = const {},
    this.isLoading = false,
    this.error,
  });

  StatisticsState copyWith({
    int? todayCompleted,
    int? todayIncomplete,
    int? todayFocusMinutes,
    int? todayCompletedTasks,
    double? todayCompletionRate,
    int? weekCompleted,
    int? weekIncomplete,
    int? weekFocusMinutes,
    int? streakDays,
    Map<String, int>? weeklyData,
    int? monthCompleted,
    int? monthIncomplete,
    int? monthFocusMinutes,
    int? monthActiveDays,
    int? monthBestDay,
    Map<int, int>? monthlyData,
    int? dailyGoal,
    int? weeklyGoal,
    Map<String, int>? timeOfDayStats,
    Map<String, int>? heatmapData,
    bool? isLoading,
    String? error,
  }) {
    return StatisticsState(
      todayCompleted: todayCompleted ?? this.todayCompleted,
      todayIncomplete: todayIncomplete ?? this.todayIncomplete,
      todayFocusMinutes: todayFocusMinutes ?? this.todayFocusMinutes,
      todayCompletedTasks: todayCompletedTasks ?? this.todayCompletedTasks,
      todayCompletionRate: todayCompletionRate ?? this.todayCompletionRate,
      weekCompleted: weekCompleted ?? this.weekCompleted,
      weekIncomplete: weekIncomplete ?? this.weekIncomplete,
      weekFocusMinutes: weekFocusMinutes ?? this.weekFocusMinutes,
      streakDays: streakDays ?? this.streakDays,
      weeklyData: weeklyData ?? this.weeklyData,
      monthCompleted: monthCompleted ?? this.monthCompleted,
      monthIncomplete: monthIncomplete ?? this.monthIncomplete,
      monthFocusMinutes: monthFocusMinutes ?? this.monthFocusMinutes,
      monthActiveDays: monthActiveDays ?? this.monthActiveDays,
      monthBestDay: monthBestDay ?? this.monthBestDay,
      monthlyData: monthlyData ?? this.monthlyData,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      weeklyGoal: weeklyGoal ?? this.weeklyGoal,
      timeOfDayStats: timeOfDayStats ?? this.timeOfDayStats,
      heatmapData: heatmapData ?? this.heatmapData,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class StatisticsNotifier with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  StatisticsState _state = StatisticsState();
  bool _disposed = false;

  StatisticsState get state => _state;

  StatisticsNotifier() {
    // 延遲初始化，避免在構造函數中進行異步操作
    Future.microtask(() {
      if (!_disposed) {
        loadStatistics();
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed && hasListeners) {
      super.notifyListeners();
    }
  }

  // 暴露狀態屬性供 ref.watch 使用
  bool get isLoading => _state.isLoading;
  int get todayCompleted => _state.todayCompleted;
  int get todayIncomplete => _state.todayIncomplete;
  int get todayFocusMinutes => _state.todayFocusMinutes;
  int get todayCompletedTasks => _state.todayCompletedTasks;
  double get todayCompletionRate => _state.todayCompletionRate;
  int get weekCompleted => _state.weekCompleted;
  int get weekIncomplete => _state.weekIncomplete;
  int get weekFocusMinutes => _state.weekFocusMinutes;
  int get streakDays => _state.streakDays;
  Map<String, int> get weeklyData => _state.weeklyData;
  int get monthCompleted => _state.monthCompleted;
  int get monthIncomplete => _state.monthIncomplete;
  int get monthFocusMinutes => _state.monthFocusMinutes;
  int get monthActiveDays => _state.monthActiveDays;
  int get monthBestDay => _state.monthBestDay;
  Map<int, int> get monthlyData => _state.monthlyData;
  int get dailyGoal => _state.dailyGoal;
  int get weeklyGoal => _state.weeklyGoal;
  Map<String, int> get timeOfDayStats => _state.timeOfDayStats;
  Map<String, int> get heatmapData => _state.heatmapData;

  Future<void> loadStatistics() async {
    if (_disposed) return;

    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      debugPrint('📊 [STATS] 開始載入統計資料...');

      // 先載入目標設定
      await _loadGoals();

      if (_disposed) return;

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);

      // 載入今日統計
      final todayStats = await _loadTodayStatistics(todayStart);
      if (_disposed) return;

      // 載入本週統計
      final weekStats = await _loadWeekStatistics(weekStart);
      if (_disposed) return;

      // 載入本月統計
      final monthStats = await _loadMonthStatistics(monthStart);
      if (_disposed) return;

      // 計算連續天數
      final streak = await _calculateStreak();
      if (_disposed) return;

      // 新增：計算最佳專注時段
      final timeOfDay = await _calculateTimeOfDayStats();
      if (_disposed) return;

      // 新增：載入熱力圖資料（最近 90 天）
      final heatmap = await _calculateHeatmapData();
      if (_disposed) return;

      _state = _state.copyWith(
        // 今日
        todayCompleted: todayStats['completed'] as int,
        todayIncomplete: todayStats['incomplete'] as int,
        todayFocusMinutes: todayStats['focusMinutes'] as int,
        todayCompletedTasks: todayStats['completedTasks'] as int,
        todayCompletionRate: todayStats['completionRate'] as double,
        // 本週
        weekCompleted: weekStats['completed'] as int,
        weekIncomplete: weekStats['incomplete'] as int,
        weekFocusMinutes: weekStats['focusMinutes'] as int,
        weeklyData: weekStats['dailyData'] as Map<String, int>,
        streakDays: streak,
        // 本月
        monthCompleted: monthStats['completed'] as int,
        monthIncomplete: monthStats['incomplete'] as int,
        monthFocusMinutes: monthStats['focusMinutes'] as int,
        monthActiveDays: monthStats['activeDays'] as int,
        monthBestDay: monthStats['bestDay'] as int,
        monthlyData: monthStats['dailyData'] as Map<int, int>,
        timeOfDayStats: timeOfDay,
        heatmapData: heatmap,
        isLoading: false,
      );

      debugPrint('✅ [STATS] 統計資料載入完成');
      debugPrint('   - 今日完成: ${_state.todayCompleted} 個');
      debugPrint('   - 本週完成: ${_state.weekCompleted} 個');
      debugPrint('   - 本月完成: ${_state.monthCompleted} 個');
      debugPrint('   - 連續天數: ${_state.streakDays} 天');

      notifyListeners();
    } catch (e) {
      debugPrint('❌ [STATS] 載入統計資料失敗: $e');
      if (!_disposed) {
        _state = _state.copyWith(isLoading: false, error: e.toString());
        notifyListeners();
      }
    }
  }

  Future<Map<String, dynamic>> _loadTodayStatistics(DateTime todayStart) async {
    final sessions = await _db.getPomodoroSessions(
      startDate: todayStart,
      endDate: todayStart.add(const Duration(days: 1)),
    );

    final completedSessions = sessions
        .where((s) => s['completed'] == 1)
        .toList();
    final incompleteSessions = sessions
        .where((s) => s['completed'] == 0)
        .toList();

    final focusMinutes = completedSessions.fold<int>(
      0,
      (sum, s) => sum + (s['duration'] as int),
    );

    // 獲取今日完成的任務數
    final completedTasks = await _db.getTasksByStatus(
      'completed',
      startDate: todayStart,
    );

    // 計算完成率
    final total = sessions.length;
    final completed = completedSessions.length;
    final completionRate = total > 0 ? (completed / total * 100) : 0.0;

    return {
      'completed': completed,
      'incomplete': incompleteSessions.length,
      'focusMinutes': focusMinutes,
      'completedTasks': completedTasks.length,
      'completionRate': completionRate,
    };
  }

  Future<Map<String, dynamic>> _loadWeekStatistics(DateTime weekStart) async {
    final weekEnd = weekStart.add(const Duration(days: 7));
    final sessions = await _db.getPomodoroSessions(
      startDate: weekStart,
      endDate: weekEnd,
    );

    final completedSessions = sessions
        .where((s) => s['completed'] == 1)
        .toList();
    final incompleteSessions = sessions
        .where((s) => s['completed'] == 0)
        .toList();

    final focusMinutes = completedSessions.fold<int>(
      0,
      (sum, s) => sum + (s['duration'] as int),
    );

    // 建立每日數據
    final dailyData = <String, int>{};
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final daySessions = completedSessions.where((s) {
        final startTime = DateTime.parse(s['start_time'] as String);
        return startTime.isAfter(dayStart) && startTime.isBefore(dayEnd);
      }).length;

      dailyData[weekDays[i]] = daySessions;
    }

    return {
      'completed': completedSessions.length,
      'incomplete': incompleteSessions.length,
      'focusMinutes': focusMinutes,
      'dailyData': dailyData,
    };
  }

  Future<Map<String, dynamic>> _loadMonthStatistics(DateTime monthStart) async {
    final now = DateTime.now();
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    final sessions = await _db.getPomodoroSessions(
      startDate: monthStart,
      endDate: monthEnd.add(const Duration(days: 1)),
    );

    final completedSessions = sessions
        .where((s) => s['completed'] == 1)
        .toList();
    final incompleteSessions = sessions
        .where((s) => s['completed'] == 0)
        .toList();

    final focusMinutes = completedSessions.fold<int>(
      0,
      (sum, s) => sum + (s['duration'] as int),
    );

    // 建立每日數據
    final dailyData = <int, int>{};
    final activeDaysSet = <int>{};
    int bestDay = 0;

    for (int day = 1; day <= monthEnd.day; day++) {
      final dayStart = DateTime(now.year, now.month, day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final daySessions = completedSessions.where((s) {
        final startTime = DateTime.parse(s['start_time'] as String);
        return startTime.isAfter(dayStart) && startTime.isBefore(dayEnd);
      }).length;

      dailyData[day] = daySessions;

      if (daySessions > 0) {
        activeDaysSet.add(day);
      }

      if (daySessions > bestDay) {
        bestDay = daySessions;
      }
    }

    return {
      'completed': completedSessions.length,
      'incomplete': incompleteSessions.length,
      'focusMinutes': focusMinutes,
      'activeDays': activeDaysSet.length,
      'bestDay': bestDay,
      'dailyData': dailyData,
    };
  }

  Future<int> _calculateStreak() async {
    int streak = 0;
    final now = DateTime.now();
    var checkDate = DateTime(now.year, now.month, now.day);

    while (true) {
      final dayStart = checkDate;
      final dayEnd = checkDate.add(const Duration(days: 1));

      final sessions = await _db.getPomodoroSessions(
        startDate: dayStart,
        endDate: dayEnd,
      );

      final completedSessions = sessions
          .where((s) => s['completed'] == 1)
          .toList();

      if (completedSessions.isEmpty) {
        break;
      }

      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));

      // 最多檢查 365 天
      if (streak >= 365) break;
    }

    return streak;
  }

  // 計算最佳專注時段統計
  Future<Map<String, int>> _calculateTimeOfDayStats() async {
    final now = DateTime.now();
    final last30Days = now.subtract(const Duration(days: 30));

    final sessions = await _db.getPomodoroSessions(
      startDate: last30Days,
      endDate: now,
    );

    final completedSessions = sessions
        .where((s) => s['completed'] == 1)
        .toList();

    final stats = <String, int>{
      'morning': 0, // 6:00 - 12:00
      'afternoon': 0, // 12:00 - 18:00
      'evening': 0, // 18:00 - 22:00
      'night': 0, // 22:00 - 6:00
    };

    for (final session in completedSessions) {
      final startTime = DateTime.parse(session['start_time'] as String);
      final hour = startTime.hour;

      if (hour >= 6 && hour < 12) {
        stats['morning'] = stats['morning']! + 1;
      } else if (hour >= 12 && hour < 18) {
        stats['afternoon'] = stats['afternoon']! + 1;
      } else if (hour >= 18 && hour < 22) {
        stats['evening'] = stats['evening']! + 1;
      } else {
        stats['night'] = stats['night']! + 1;
      }
    }

    return stats;
  }

  // 計算熱力圖資料（最近 90 天）
  Future<Map<String, int>> _calculateHeatmapData() async {
    final now = DateTime.now();
    final last90Days = now.subtract(const Duration(days: 90));

    final sessions = await _db.getPomodoroSessions(
      startDate: last90Days,
      endDate: now,
    );

    final completedSessions = sessions
        .where((s) => s['completed'] == 1)
        .toList();

    final heatmap = <String, int>{};

    // 初始化所有日期為 0
    for (int i = 0; i < 90; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      heatmap[dateStr] = 0;
    }

    // 計算每天的完成數
    for (final session in completedSessions) {
      final startTime = DateTime.parse(session['start_time'] as String);
      final dateStr =
          '${startTime.year}-${startTime.month.toString().padLeft(2, '0')}-${startTime.day.toString().padLeft(2, '0')}';

      if (heatmap.containsKey(dateStr)) {
        heatmap[dateStr] = heatmap[dateStr]! + 1;
      }
    }

    return heatmap;
  }

  // 設定每日目標
  Future<void> setDailyGoal(int goal) async {
    if (_disposed) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dailyGoal', goal);
    _state = _state.copyWith(dailyGoal: goal);
    notifyListeners();
  }

  // 設定每週目標
  Future<void> setWeeklyGoal(int goal) async {
    if (_disposed) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('weeklyGoal', goal);
    _state = _state.copyWith(weeklyGoal: goal);
    notifyListeners();
  }

  // 載入目標設定
  Future<void> _loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final dailyGoal = prefs.getInt('dailyGoal') ?? 8;
    final weeklyGoal = prefs.getInt('weeklyGoal') ?? 40;

    _state = _state.copyWith(dailyGoal: dailyGoal, weeklyGoal: weeklyGoal);
  }
}
