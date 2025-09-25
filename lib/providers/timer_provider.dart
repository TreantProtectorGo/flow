import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'task_provider.dart';

// Riverpod provider
final timerProvider = ChangeNotifierProvider<TimerProvider>((ref) {
  return TimerProvider(ref);
});

enum TimerState {
  stopped,
  running,
  paused,
}

enum TimerMode {
  focus,   // 專注時間 25分鐘
  shortBreak, // 短休息 5分鐘
  longBreak,  // 長休息 15分鐘
}

class TimerProvider with ChangeNotifier {
  final Ref _ref;
  Timer? _timer;
  
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
  
  bool get isRunning => _state == TimerState.running;
  bool get isPaused => _state == TimerState.paused;
  bool get isStopped => _state == TimerState.stopped;
  bool get isFocusMode => _mode == TimerMode.focus;
  bool get isBreakMode => _mode == TimerMode.shortBreak || _mode == TimerMode.longBreak;
  
  double get progress => _totalTimeInSeconds > 0 
      ? (_totalTimeInSeconds - _timeLeftInSeconds) / _totalTimeInSeconds 
      : 0.0;

  String get timeDisplayString {
    final minutes = _timeLeftInSeconds ~/ 60;
    final seconds = _timeLeftInSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get modeDisplayString {
    switch (_mode) {
      case TimerMode.focus:
        return '專注時間';
      case TimerMode.shortBreak:
        return '短休息';
      case TimerMode.longBreak:
        return '長休息';
    }
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
      debugPrint('載入番茄鐘設定時發生錯誤: $e');
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
      debugPrint('保存番茄鐘設定時發生錯誤: $e');
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

  void stopTimer() {
    _timer?.cancel();
    _state = TimerState.stopped;
    _updateTimeForCurrentMode();
    notifyListeners();
  }

  void skipTimer() {
    _onTimerComplete();
  }

  void _onTimerComplete() {
    _timer?.cancel();
    _state = TimerState.stopped;
    
    if (_mode == TimerMode.focus) {
      _completedSessions++;
      _totalFocusSessions++;
      
      // 通知任務提供者完成了一個番茄鐘
      _ref.read(taskProvider.notifier).completePomodoroForCurrentTask();
      
      // 決定下一階段：短休息還是長休息
      if (_completedSessions % 4 == 0) {
        _mode = TimerMode.longBreak;
      } else {
        _mode = TimerMode.shortBreak;
      }
    } else {
      // 休息結束，回到專注模式
      _mode = TimerMode.focus;
      _currentSession++;
    }
    
    _updateTimeForCurrentMode();
    _saveSettings();
    notifyListeners();
  }

  void switchToFocusMode() {
    if (_mode == TimerMode.focus) return;
    
    stopTimer();
    _mode = TimerMode.focus;
    _updateTimeForCurrentMode();
    notifyListeners();
  }

  void switchToBreakMode() {
    if (isBreakMode) return;
    
    stopTimer();
    _mode = TimerMode.shortBreak;
    _updateTimeForCurrentMode();
    notifyListeners();
  }

  // 設置時間（分鐘）
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
