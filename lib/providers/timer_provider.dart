import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'task_provider.dart';
import 'statistics_provider.dart';
import '../services/database_helper.dart';

// Riverpod provider
final timerProvider = ChangeNotifierProvider<TimerProvider>((ref) {
  return TimerProvider(ref);
});

enum TimerState { stopped, running, paused }

enum TimerMode {
  focus, // Focus time: 25 minutes
  shortBreak, // Short break: 5 minutes
  longBreak, // Long break: 15 minutes
}

class TimerProvider with ChangeNotifier {
  final Ref _ref;
  Timer? _timer;
  final DatabaseHelper _db = DatabaseHelper.instance;

  // Timer settings
  int _focusTimeInMinutes = 25;
  int _shortBreakTimeInMinutes = 5;
  int _longBreakTimeInMinutes = 15;

  // Current timer state
  TimerState _state = TimerState.stopped;
  TimerMode _mode = TimerMode.focus;
  int _timeLeftInSeconds = 25 * 60;
  int _totalTimeInSeconds = 25 * 60;

  // Session tracking
  int _currentSession = 1;
  int _completedSessions = 0;
  int _totalFocusSessions = 0;

  // Track current pomodoro session start time and ID
  DateTime? _currentSessionStartTime;
  String? _currentSessionId;

  TimerProvider(this._ref) {
    _loadSettings();
  }

  // Getters
  TimerState get state => _state;
  TimerMode get mode => _mode;
  int get timeLeftInSeconds => _timeLeftInSeconds;
  int get totalTimeInSeconds => _totalTimeInSeconds;
  int get currentSession => _currentSession;
  int get completedSessions => _completedSessions;
  int get totalFocusSessions => _totalFocusSessions;
  int get focusTimeInMinutes => _focusTimeInMinutes;
  int get shortBreakTimeInMinutes => _shortBreakTimeInMinutes;
  int get longBreakTimeInMinutes => _longBreakTimeInMinutes;

  bool get isRunning => _state == TimerState.running;
  bool get isPaused => _state == TimerState.paused;
  bool get isStopped => _state == TimerState.stopped;
  bool get isFocusMode => _mode == TimerMode.focus;
  bool get isBreakMode =>
      _mode == TimerMode.shortBreak || _mode == TimerMode.longBreak;

  double get progress => _totalTimeInSeconds > 0
      ? (_totalTimeInSeconds - _timeLeftInSeconds) / _totalTimeInSeconds
      : 0.0;

  String get timeDisplayString {
    final minutes = _timeLeftInSeconds ~/ 60;
    final seconds = _timeLeftInSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String getModeDisplayString(String Function(TimerMode) translator) {
    return translator(_mode);
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _focusTimeInMinutes = prefs.getInt('focusTime') ?? 25;
      _shortBreakTimeInMinutes = prefs.getInt('shortBreakTime') ?? 5;
      _longBreakTimeInMinutes = prefs.getInt('longBreakTime') ?? 15;
      _totalFocusSessions = prefs.getInt('totalFocusSessions') ?? 0;

      _updateTimeForCurrentMode();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading pomodoro settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('focusTime', _focusTimeInMinutes);
      await prefs.setInt('shortBreakTime', _shortBreakTimeInMinutes);
      await prefs.setInt('longBreakTime', _longBreakTimeInMinutes);
      await prefs.setInt('totalFocusSessions', _totalFocusSessions);
    } catch (e) {
      debugPrint('Error saving pomodoro settings: $e');
    }
  }

  void _updateTimeForCurrentMode() {
    switch (_mode) {
      case TimerMode.focus:
        _timeLeftInSeconds = _focusTimeInMinutes * 60;
        _totalTimeInSeconds = _focusTimeInMinutes * 60;
        break;
      case TimerMode.shortBreak:
        _timeLeftInSeconds = _shortBreakTimeInMinutes * 60;
        _totalTimeInSeconds = _shortBreakTimeInMinutes * 60;
        break;
      case TimerMode.longBreak:
        _timeLeftInSeconds = _longBreakTimeInMinutes * 60;
        _totalTimeInSeconds = _longBreakTimeInMinutes * 60;
        break;
    }
  }

  void startTimer() {
    if (_state == TimerState.running) return;

    _state = TimerState.running;

    // Record session start time (only on first start, resume after pause doesn't restart)
    if (_currentSessionStartTime == null && _mode == TimerMode.focus) {
      _currentSessionStartTime = DateTime.now();
      _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      debugPrint(
        '⏱️ [TIMER] Starting new pomodoro session (ID: $_currentSessionId)',
      );
    }

    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeftInSeconds <= 0) {
        _onTimerComplete();
      } else {
        _timeLeftInSeconds--;
        notifyListeners();
      }
    });
  }

  void pauseTimer() {
    if (_state != TimerState.running) return;

    _timer?.cancel();
    _state = TimerState.paused;
    notifyListeners();
  }

  Future<void> stopTimer() async {
    _timer?.cancel();
    _state = TimerState.stopped;

    // If in focus mode and has start time, record as incomplete session
    if (_mode == TimerMode.focus && _currentSessionStartTime != null) {
      await _recordPomodoroSession(completed: false);
    }

    _updateTimeForCurrentMode();
    notifyListeners();
  }

  void skipTimer() {
    _onTimerComplete();
  }

  Future<void> _onTimerComplete() async {
    _timer?.cancel();
    _state = TimerState.stopped;

    if (_mode == TimerMode.focus) {
      _completedSessions++;
      _totalFocusSessions++;

      // Record completed pomodoro session to database
      await _recordPomodoroSession(completed: true);

      // Notify task provider that a pomodoro was completed
      _ref.read(taskProvider.notifier).completePomodoroForCurrentTask();

      // Update statistics data
      _ref.read(statisticsProvider.notifier).loadStatistics();

      // Decide next phase: short break or long break
      if (_completedSessions % 4 == 0) {
        _mode = TimerMode.longBreak;
      } else {
        _mode = TimerMode.shortBreak;
      }
    } else {
      // Break ended, return to focus mode
      _mode = TimerMode.focus;
      _currentSession++;
    }

    _updateTimeForCurrentMode();
    _saveSettings();
    notifyListeners();
  }

  /// Record pomodoro session to database
  Future<void> _recordPomodoroSession({required bool completed}) async {
    if (_currentSessionStartTime == null) {
      debugPrint('⚠️ [TIMER] Cannot record session: no start time');
      return;
    }

    try {
      final endTime = DateTime.now();
      final duration = endTime.difference(_currentSessionStartTime!).inMinutes;
      final currentTask = _ref.read(taskProvider.notifier).currentTask;

      await _db.insertPomodoroSession(
        taskId: currentTask?.id,
        startTime: _currentSessionStartTime!,
        endTime: endTime,
        duration: duration,
        completed: completed,
        sessionType: _mode.name,
      );

      debugPrint('✅ [TIMER] Pomodoro session recorded to database');
      debugPrint('   - Task: ${currentTask?.title ?? "No associated task"}');
      debugPrint('   - Duration: $duration minutes');
      debugPrint('   - Completed: $completed');

      // Reset session tracking
      _currentSessionStartTime = null;
      _currentSessionId = null;
    } catch (e) {
      debugPrint('❌ [TIMER] Failed to record pomodoro session: $e');
    }
  }

  Future<void> switchToFocusMode() async {
    if (_mode == TimerMode.focus) return;

    // If a focus timer is running, record the incomplete session first
    if (_state == TimerState.running && _currentSessionStartTime != null) {
      await _recordPomodoroSession(completed: false);
    }

    await stopTimer();
    _mode = TimerMode.focus;
    _updateTimeForCurrentMode();
    notifyListeners();
  }

  Future<void> switchToBreakMode() async {
    if (isBreakMode) return;

    await stopTimer();
    _mode = TimerMode.shortBreak;
    _updateTimeForCurrentMode();
    notifyListeners();
  }

  // Set timer duration (in minutes)
  void setFocusTime(int minutes) {
    _focusTimeInMinutes = minutes;
    if (_mode == TimerMode.focus) {
      _updateTimeForCurrentMode();
    }
    _saveSettings();
    notifyListeners();
  }

  void setShortBreakTime(int minutes) {
    _shortBreakTimeInMinutes = minutes;
    if (_mode == TimerMode.shortBreak) {
      _updateTimeForCurrentMode();
    }
    _saveSettings();
    notifyListeners();
  }

  void setLongBreakTime(int minutes) {
    _longBreakTimeInMinutes = minutes;
    if (_mode == TimerMode.longBreak) {
      _updateTimeForCurrentMode();
    }
    _saveSettings();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
