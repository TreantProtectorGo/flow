// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Flow';

  @override
  String get taskPlan => '任务计划';

  @override
  String estimatedCompletionTime(String time) {
    return '预估完成时间：$time';
  }

  @override
  String get tasks => '任務';

  @override
  String get timer => '計時器';

  @override
  String get statistics => '統計';

  @override
  String get settings => '設定';

  @override
  String get addTask => '新增任務';

  @override
  String get editTask => '編輯任務';

  @override
  String get deleteTask => '刪除任務';

  @override
  String get update => '更新';

  @override
  String get add => '新增';

  @override
  String get taskTitle => '任務標題';

  @override
  String get taskDescription => '任務描述';

  @override
  String get taskDescriptionOptional => '任務描述（選填）';

  @override
  String get enterTaskTitle => '請輸入任務標題';

  @override
  String get estimatedPomodoros => '預估番茄鐘數量';

  @override
  String get estimated => '預估';

  @override
  String get enterPomodoroCount => '請輸入番茄鐘數量';

  @override
  String pomodoroCount(int count) {
    return '$count 個番茄鐘';
  }

  @override
  String get priority => '優先級';

  @override
  String get status => '狀態';

  @override
  String get priorityHigh => '高';

  @override
  String get priorityMedium => '中';

  @override
  String get priorityLow => '低';

  @override
  String get highPriority => '高優先級';

  @override
  String get mediumPriority => '中優先級';

  @override
  String get lowPriority => '低優先級';

  @override
  String get statusPending => '待辦';

  @override
  String get statusInProgress => '進行中';

  @override
  String get statusCompleted => '已完成';

  @override
  String get inProgress => '進行中';

  @override
  String get completed => '完成';

  @override
  String get noTasks => '暫無待辦任務';

  @override
  String get noTasksMessage => '暫無待辦任務';

  @override
  String get start => '開始';

  @override
  String get continueButton => '繼續';

  @override
  String get pause => '暫停';

  @override
  String get resume => '繼續';

  @override
  String get stop => '停止';

  @override
  String get reset => '重置';

  @override
  String get skip => '跳過';

  @override
  String get focusTime => '專注時間';

  @override
  String get shortBreak => '短休息';

  @override
  String get longBreak => '長休息';

  @override
  String get breakTime => '休息時間';

  @override
  String get pomodoroMode => '番茄鐘';

  @override
  String get shortBreakMode => '短休息';

  @override
  String get longBreakMode => '長休息';

  @override
  String get selectTask => '選擇任務';

  @override
  String get clearSelection => '清除選擇';

  @override
  String get noAvailableTasks => '暫無可選擇的任務';

  @override
  String get addTasksFirst => '請先在任務頁面添加一些任務';

  @override
  String get noTaskSelected => '尚未選擇任務';

  @override
  String get tapToSelect => '點擊選擇任務';

  @override
  String get currentTask => '當前任務';

  @override
  String get switchTask => '切換';

  @override
  String completedSessions(int count) {
    return '已完成 $count 個專注時段';
  }

  @override
  String startFocus(String taskTitle) {
    return '開始專注：$taskTitle';
  }

  @override
  String continueTask(String taskTitle) {
    return '繼續任務：$taskTitle';
  }

  @override
  String taskAdded(String taskTitle) {
    return '已新增任務：$taskTitle';
  }

  @override
  String confirmDelete(String taskTitle) {
    return '確定要刪除「$taskTitle」嗎？';
  }

  @override
  String get cancel => '取消';

  @override
  String get delete => '刪除';

  @override
  String get save => '儲存';

  @override
  String get confirm => '確定';

  @override
  String get close => '關閉';

  @override
  String get retry => '重試';

  @override
  String get edit => '編輯';

  @override
  String get markComplete => '標記完成';

  @override
  String get aiAnalysis => 'AI 分析';

  @override
  String get aiBreakdownCard => '讓 AI 幫你拆解大任務';

  @override
  String get view => '查看';

  @override
  String timerRunning(String time) {
    return '計時中 $time';
  }

  @override
  String pomodoroCountText(int count) {
    return '$count 個番茄鐘';
  }

  @override
  String get aiTaskAnalysis => 'AI 任務分析';

  @override
  String get taskName => '任務名稱';

  @override
  String get estimatedTime => '預估時間';

  @override
  String get aiSuggestions => 'AI 建議';

  @override
  String get breakIntoSteps => '• 將任務分成小步驟以提高完成率';

  @override
  String get takeBreaks => '• 每個番茄鐘後記得休息 5 分鐘';

  @override
  String get setClearStandards => '• 設定明確的完成標準';

  @override
  String get highPrioritySuggestion => '• 高優先級任務建議優先處理';

  @override
  String get longTaskSuggestion => '• 長時間任務建議分階段執行';

  @override
  String minutesUnit(int count) {
    return '$count 分鐘';
  }

  @override
  String get todayStats => '今日';

  @override
  String get weekStats => '本週';

  @override
  String get monthStats => '本月';

  @override
  String get streakDays => '連續天數';

  @override
  String get days => '天';

  @override
  String get completedToday => '今日完成';

  @override
  String get completedPomodoros => '完成番茄鐘';

  @override
  String get completedTasks => '完成任務';

  @override
  String get completionRate => '完成率';

  @override
  String get dailyAverage => '日均完成';

  @override
  String get progress => '進度';

  @override
  String get remaining => '還需';

  @override
  String get completeOnePomodoroToStartStreak => '完成一個番茄鐘開始連續！';

  @override
  String get startNewStreakToday => '今天開始新的連續記錄！';

  @override
  String get goodStart => '好的開始！';

  @override
  String get keepGoing => '繼續保持！';

  @override
  String get awesome => '太棒了！';

  @override
  String get focusMaster => '你是專注大師！';

  @override
  String get legendaryStreak => '傳奇級連續記錄！';

  @override
  String get todayGoal => '今日目標';

  @override
  String get weekGoal => '本週目標';

  @override
  String get todayOverview => '今日概覽';

  @override
  String get weekOverview => '本週概覽';

  @override
  String get monthOverview => '本月概覽';

  @override
  String get todayTimeDistribution => '今日時間分布';

  @override
  String get weeklyTrend => '本週趨勢';

  @override
  String get incomplete => '未完成';

  @override
  String get noPomodorosToday => '今天還沒有完成任何番茄鐘';

  @override
  String get noPomodorosThisWeek => '本週還沒有完成任何番茄鐘';

  @override
  String get noPomodorosThisMonth => '本月還沒有完成任何番茄鐘';

  @override
  String get pomodoros => '個番茄鐘';

  @override
  String get dailyGoal => '每日目標';

  @override
  String get weeklyGoal => '每週目標';

  @override
  String get focusHours => '專注時數';

  @override
  String get pomodoroSettings => '番茄鐘設定';

  @override
  String get goalSettings => '目標設定';

  @override
  String get notificationSettings => '通知設定';

  @override
  String get appearanceSettings => '外觀設定';

  @override
  String get aiSettings => 'AI 設定';

  @override
  String get dataAndSync => '數據與同步';

  @override
  String get dangerZone => '危險區域';

  @override
  String get focusDuration => '專注時間';

  @override
  String get focusDurationSubtitle => '每個番茄鐘的專注時長';

  @override
  String get shortBreakDuration => '短休息';

  @override
  String get shortBreakSubtitle => '完成一個番茄鐘後的休息時間';

  @override
  String get longBreakDuration => '長休息';

  @override
  String get longBreakSubtitle => '完成4個番茄鐘後的休息時間';

  @override
  String get longBreakFrequency => '長休息頻率';

  @override
  String get longBreakFrequencySubtitle => '每幾個番茄鐘後進行長休息';

  @override
  String minutes(int count) {
    return '$count 分鐘';
  }

  @override
  String items(int count) {
    return '個';
  }

  @override
  String get dailyGoalTitle => '每日目標';

  @override
  String get dailyGoalSubtitle => '每天想要完成的番茄鐘數量';

  @override
  String get weeklyGoalTitle => '每週目標';

  @override
  String get weeklyGoalSubtitle => '每週想要完成的番茄鐘數量';

  @override
  String get pushNotifications => '推播通知';

  @override
  String get pushNotificationsSubtitle => '時間結束時發送通知';

  @override
  String get soundEffect => '提示音效';

  @override
  String get soundEffectSubtitle => '選擇計時器結束時的音效';

  @override
  String get vibration => '震動提醒';

  @override
  String get vibrationSubtitle => '時間結束時震動提醒';

  @override
  String get soundBell => '鈴鐺';

  @override
  String get soundBird => '鳥鳴';

  @override
  String get soundWave => '海浪';

  @override
  String get soundNone => '無音效';

  @override
  String get themeMode => '主題模式';

  @override
  String get themeModeSubtitle => '選擇應用程式的主題模式';

  @override
  String get themeSystem => '跟隨系統';

  @override
  String get themeLight => '淺色模式';

  @override
  String get themeDark => '深色模式';

  @override
  String get language => '語言';

  @override
  String get languageSubtitle => '選擇應用程式語言';

  @override
  String get aiTaskBreakdown => 'AI 任務拆解';

  @override
  String get aiTaskBreakdownSubtitle => '允許 AI 幫助拆解複雜任務';

  @override
  String get smartSuggestions => '智慧建議';

  @override
  String get smartSuggestionsSubtitle => '根據使用習慣提供個人化建議';

  @override
  String get dataAnalysis => '數據分析';

  @override
  String get dataAnalysisSubtitle => '允許分析使用數據以改善服務';

  @override
  String get cloudSync => '雲端同步';

  @override
  String get cloudSyncSubtitle => '自動同步數據到雲端';

  @override
  String get exportData => '匯出數據';

  @override
  String get exportDataSubtitle => '下載您的統計數據';

  @override
  String get exportCSV => '匯出 CSV';

  @override
  String get clearAllData => '清除所有數據';

  @override
  String get clearAllDataSubtitle => '刪除所有統計數據和設定';

  @override
  String get clearData => '清除數據';

  @override
  String get deleteAccount => '刪除帳號';

  @override
  String get deleteAccountSubtitle => '永久刪除您的帳號和所有資料';

  @override
  String get version => 'Flow v1.0.0';

  @override
  String get copyright => '© 2024 Flow Team';

  @override
  String get pending => '待辦事項';

  @override
  String get activeTimer => '進行中的計時';

  @override
  String get focusingNow => '正在專注';

  @override
  String get tapToViewTimer => '點擊查看計時器';

  @override
  String get emptyPendingTasks => '暫無待辦任務';

  @override
  String get aiBreakdownDescription => '讓 AI 幫你拆解大任務';

  @override
  String get aiChatTitle => 'AI 助手';

  @override
  String get thinking => '正在思考...';

  @override
  String get clearConversation => '清空對話';

  @override
  String get confirmClearConversation => '確定要清空所有對話記錄嗎？';

  @override
  String get clearConversationButton => '清空';

  @override
  String get sendMessage => '發送訊息';

  @override
  String get typeMessage => '輸入訊息...';

  @override
  String get askAiHelper => '問問 AI 助手...';

  @override
  String get creatingTasks => '正在創建...';

  @override
  String get createTasks => '創建任務';

  @override
  String get editPlan => '編輯計畫';

  @override
  String get createDirectly => '直接創建';

  @override
  String get editTaskPlan => '編輯任務計畫';

  @override
  String get saveAndCreate => '儲存並創建';

  @override
  String get creating => '創建中...';

  @override
  String get mainGoal => '主要目標';

  @override
  String get enterMainGoal => '輸入主要目標';

  @override
  String totalTasks(int count) {
    return '總共 $count 個任務';
  }

  @override
  String totalPomodoros(int count) {
    return '總共 $count 個番茄鐘';
  }

  @override
  String get noTasksInPlan => '計畫中還沒有任務';

  @override
  String get newTask => '新任務';

  @override
  String get mainGoalRequired => '主要目標不能為空';

  @override
  String get atLeastOneTaskRequired => '至少需要一個任務';

  @override
  String get enterTaskDescription => '輸入任務描述';

  @override
  String get description => '描述';

  @override
  String get cannotExtractTasks => '無法從對話中提取任務，請嘗試更明確地描述任務';

  @override
  String get aiResponseFailed => 'AI 回復失敗';

  @override
  String tasksCreatedSuccess(int count) {
    return '成功創建 $count 個任務！';
  }

  @override
  String get failedToCreateTasks => '創建任務失敗';

  @override
  String taskCreationFailed(String error) {
    return '創建任務失敗: $error';
  }

  @override
  String confirmAction(String action) {
    return '確認$action';
  }

  @override
  String confirmActionMessage(String action) {
    return '確定要執行$action操作嗎？此操作無法復原。';
  }

  @override
  String featureComingSoon(String action) {
    return '$action功能將在正式版本中實現';
  }

  @override
  String get hourShort => '時';

  @override
  String get minuteShort => '分';

  @override
  String get secondShort => '秒';

  @override
  String get hour => '小時';

  @override
  String get minute => '分鐘';

  @override
  String get second => '秒';

  @override
  String get focusMode => '專注時間';

  @override
  String get thisWeekOverview => '本週概覽';

  @override
  String get thisMonthOverview => '本月概覽';

  @override
  String hours(String count) {
    return '$count 小時';
  }

  @override
  String get thisWeekGoal => '本週目標';

  @override
  String get workDays => '工作天數';

  @override
  String get bestDay => '最佳單日';

  @override
  String get monthlyHeatmap => '月度專注熱力圖';

  @override
  String get thisMonthTrend => '本月趨勢';

  @override
  String get noPomodoros => '今天還沒有完成任何番茄鐘';

  @override
  String get thisWeekTrend => '本週趨勢';

  @override
  String get noWeekStats => '本週還沒有統計資料';

  @override
  String get bestFocusTime => '最佳專注時段（最近 30 天）';

  @override
  String get noMonthStats => '本月還沒有統計資料';

  @override
  String count(int count) {
    return '$count 個';
  }

  @override
  String get consecutiveFocus => '連續專注';

  @override
  String get notEnoughData => '還沒有足夠的資料';

  @override
  String get yourBestFocusTime => '您的最佳專注時段';

  @override
  String get morning => '早上';

  @override
  String get afternoon => '下午';

  @override
  String get evening => '傍晚';

  @override
  String get night => '深夜';

  @override
  String get morningTime => '6:00-12:00';

  @override
  String get afternoonTime => '12:00-18:00';

  @override
  String get eveningTime => '18:00-22:00';

  @override
  String get nightTime => '22:00-6:00';

  @override
  String completedPomodorosCount(int count) {
    return '已完成 $count 個番茄鐘';
  }

  @override
  String get copiedToClipboard => '已複製到剪貼簿';

  @override
  String get justNow => '剛剛';

  @override
  String minutesAgo(int count) {
    return '$count 分鐘前';
  }

  @override
  String hoursAgo(int count) {
    return '$count 小時前';
  }

  @override
  String get mondayShort => '週一';

  @override
  String get tuesdayShort => '週二';

  @override
  String get wednesdayShort => '週三';

  @override
  String get thursdayShort => '週四';

  @override
  String get fridayShort => '週五';

  @override
  String get saturdayShort => '週六';

  @override
  String get sundayShort => '週日';

  @override
  String pomodoroCountShort(int count) {
    return '$count 個番茄鐘';
  }

  @override
  String get less => '少';

  @override
  String get more => '多';

  @override
  String get helloAI => '你好！我是 AI 助手';

  @override
  String get aiDescription => '我是您的專注助手，可以幫您分析任務、提供建議';

  @override
  String get noTasksToSelect => '暫無可選擇的任務';

  @override
  String get pleaseAddTasksFirst => '請先在任務頁面添加一些任務';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get appTitle => 'Flow';

  @override
  String get taskPlan => '任務計劃';

  @override
  String estimatedCompletionTime(String time) {
    return '預估完成時間：$time';
  }

  @override
  String get tasks => '任務';

  @override
  String get timer => '計時器';

  @override
  String get statistics => '統計';

  @override
  String get settings => '設定';

  @override
  String get addTask => '新增任務';

  @override
  String get editTask => '編輯任務';

  @override
  String get deleteTask => '刪除任務';

  @override
  String get update => '更新';

  @override
  String get add => '新增';

  @override
  String get taskTitle => '任務標題';

  @override
  String get taskDescription => '任務描述';

  @override
  String get taskDescriptionOptional => '任務描述（選填）';

  @override
  String get enterTaskTitle => '請輸入任務標題';

  @override
  String get estimatedPomodoros => '預估番茄鐘數量';

  @override
  String get estimated => '預估';

  @override
  String get enterPomodoroCount => '請輸入番茄鐘數量';

  @override
  String pomodoroCount(int count) {
    return '$count 個番茄鐘';
  }

  @override
  String get priority => '優先級';

  @override
  String get status => '狀態';

  @override
  String get priorityHigh => '高';

  @override
  String get priorityMedium => '中';

  @override
  String get priorityLow => '低';

  @override
  String get highPriority => '高優先級';

  @override
  String get mediumPriority => '中優先級';

  @override
  String get lowPriority => '低優先級';

  @override
  String get statusPending => '待辦';

  @override
  String get statusInProgress => '進行中';

  @override
  String get statusCompleted => '已完成';

  @override
  String get inProgress => '進行中';

  @override
  String get completed => '完成';

  @override
  String get noTasks => '暫無待辦任務';

  @override
  String get noTasksMessage => '暫無待辦任務';

  @override
  String get start => '開始';

  @override
  String get continueButton => '繼續';

  @override
  String get pause => '暫停';

  @override
  String get resume => '繼續';

  @override
  String get stop => '停止';

  @override
  String get reset => '重置';

  @override
  String get skip => '跳過';

  @override
  String get focusTime => '專注時間';

  @override
  String get shortBreak => '短休息';

  @override
  String get longBreak => '長休息';

  @override
  String get breakTime => '休息時間';

  @override
  String get pomodoroMode => '番茄鐘';

  @override
  String get shortBreakMode => '短休息';

  @override
  String get longBreakMode => '長休息';

  @override
  String get selectTask => '選擇任務';

  @override
  String get clearSelection => '清除選擇';

  @override
  String get noAvailableTasks => '暫無可選擇的任務';

  @override
  String get addTasksFirst => '請先在任務頁面添加一些任務';

  @override
  String get noTaskSelected => '尚未選擇任務';

  @override
  String get tapToSelect => '點擊選擇任務';

  @override
  String get currentTask => '當前任務';

  @override
  String get switchTask => '切換';

  @override
  String completedSessions(int count) {
    return '已完成 $count 個專注時段';
  }

  @override
  String startFocus(String taskTitle) {
    return '開始專注：$taskTitle';
  }

  @override
  String continueTask(String taskTitle) {
    return '繼續任務：$taskTitle';
  }

  @override
  String taskAdded(String taskTitle) {
    return '已新增任務：$taskTitle';
  }

  @override
  String confirmDelete(String taskTitle) {
    return '確定要刪除「$taskTitle」嗎？';
  }

  @override
  String get cancel => '取消';

  @override
  String get delete => '刪除';

  @override
  String get save => '儲存';

  @override
  String get confirm => '確定';

  @override
  String get close => '關閉';

  @override
  String get retry => '重試';

  @override
  String get edit => '編輯';

  @override
  String get markComplete => '標記完成';

  @override
  String get aiAnalysis => 'AI 分析';

  @override
  String get aiBreakdownCard => '讓 AI 幫你拆解大任務';

  @override
  String get view => '查看';

  @override
  String timerRunning(String time) {
    return '計時中 $time';
  }

  @override
  String pomodoroCountText(int count) {
    return '$count 個番茄鐘';
  }

  @override
  String get aiTaskAnalysis => 'AI 任務分析';

  @override
  String get taskName => '任務名稱';

  @override
  String get estimatedTime => '預估時間';

  @override
  String get aiSuggestions => 'AI 建議';

  @override
  String get breakIntoSteps => '• 將任務分成小步驟以提高完成率';

  @override
  String get takeBreaks => '• 每個番茄鐘後記得休息 5 分鐘';

  @override
  String get setClearStandards => '• 設定明確的完成標準';

  @override
  String get highPrioritySuggestion => '• 高優先級任務建議優先處理';

  @override
  String get longTaskSuggestion => '• 長時間任務建議分階段執行';

  @override
  String minutesUnit(int count) {
    return '$count 分鐘';
  }

  @override
  String get todayStats => '今日';

  @override
  String get weekStats => '本週';

  @override
  String get monthStats => '本月';

  @override
  String get streakDays => '連續專注';

  @override
  String get days => '天';

  @override
  String get completedToday => '今日完成';

  @override
  String get completedPomodoros => '完成番茄鐘';

  @override
  String get completedTasks => '完成任務';

  @override
  String get completionRate => '完成率';

  @override
  String get dailyAverage => '日均完成';

  @override
  String get progress => '進度';

  @override
  String get remaining => '還需';

  @override
  String get completeOnePomodoroToStartStreak => '完成一個番茄鐘開始連續！';

  @override
  String get startNewStreakToday => '今天開始新的連續記錄！';

  @override
  String get goodStart => '好的開始！';

  @override
  String get keepGoing => '繼續保持！';

  @override
  String get awesome => '太棒了！';

  @override
  String get focusMaster => '你是專注大師！';

  @override
  String get legendaryStreak => '傳奇級連續記錄！';

  @override
  String get todayGoal => '今日目標';

  @override
  String get weekGoal => '本週目標';

  @override
  String get todayOverview => '今日概覽';

  @override
  String get weekOverview => '本週概覽';

  @override
  String get monthOverview => '本月概覽';

  @override
  String get todayTimeDistribution => '今日時間分布';

  @override
  String get weeklyTrend => '本週趨勢';

  @override
  String get incomplete => '未完成';

  @override
  String get noPomodorosToday => '今天還沒有完成任何番茄鐘';

  @override
  String get noPomodorosThisWeek => '本週還沒有完成任何番茄鐘';

  @override
  String get noPomodorosThisMonth => '本月還沒有完成任何番茄鐘';

  @override
  String get pomodoros => '個番茄鐘';

  @override
  String get dailyGoal => '每日目標';

  @override
  String get weeklyGoal => '每週目標';

  @override
  String get focusHours => '專注時數';

  @override
  String get pomodoroSettings => '番茄鐘設定';

  @override
  String get goalSettings => '目標設定';

  @override
  String get notificationSettings => '通知設定';

  @override
  String get appearanceSettings => '外觀設定';

  @override
  String get aiSettings => 'AI 設定';

  @override
  String get dataAndSync => '數據與同步';

  @override
  String get dangerZone => '危險區域';

  @override
  String get focusDuration => '專注時間';

  @override
  String get focusDurationSubtitle => '每個番茄鐘的專注時長';

  @override
  String get shortBreakDuration => '短休息';

  @override
  String get shortBreakSubtitle => '完成一個番茄鐘後的休息時間';

  @override
  String get longBreakDuration => '長休息';

  @override
  String get longBreakSubtitle => '完成4個番茄鐘後的休息時間';

  @override
  String get longBreakFrequency => '長休息頻率';

  @override
  String get longBreakFrequencySubtitle => '每幾個番茄鐘後進行長休息';

  @override
  String minutes(int count) {
    return '$count 分鐘';
  }

  @override
  String items(int count) {
    return '$count';
  }

  @override
  String get dailyGoalTitle => '每日目標';

  @override
  String get dailyGoalSubtitle => '每天想要完成的番茄鐘數量';

  @override
  String get weeklyGoalTitle => '每週目標';

  @override
  String get weeklyGoalSubtitle => '每週想要完成的番茄鐘數量';

  @override
  String get pushNotifications => '推播通知';

  @override
  String get pushNotificationsSubtitle => '時間結束時發送通知';

  @override
  String get soundEffect => '提示音效';

  @override
  String get soundEffectSubtitle => '選擇計時器結束時的音效';

  @override
  String get vibration => '震動提醒';

  @override
  String get vibrationSubtitle => '時間結束時震動提醒';

  @override
  String get soundBell => '鈴鐺';

  @override
  String get soundBird => '鳥鳴';

  @override
  String get soundWave => '海浪';

  @override
  String get soundNone => '無音效';

  @override
  String get themeMode => '主題模式';

  @override
  String get themeModeSubtitle => '選擇應用程式的主題模式';

  @override
  String get themeSystem => '跟隨系統';

  @override
  String get themeLight => '淺色模式';

  @override
  String get themeDark => '深色模式';

  @override
  String get language => '語言';

  @override
  String get languageSubtitle => '選擇應用程式語言';

  @override
  String get aiTaskBreakdown => 'AI 任務拆解';

  @override
  String get aiTaskBreakdownSubtitle => '允許 AI 幫助拆解複雜任務';

  @override
  String get smartSuggestions => '智慧建議';

  @override
  String get smartSuggestionsSubtitle => '根據使用習慣提供個人化建議';

  @override
  String get dataAnalysis => '數據分析';

  @override
  String get dataAnalysisSubtitle => '允許分析使用數據以改善服務';

  @override
  String get cloudSync => '雲端同步';

  @override
  String get cloudSyncSubtitle => '自動同步數據到雲端';

  @override
  String get exportData => '匯出數據';

  @override
  String get exportDataSubtitle => '下載您的統計數據';

  @override
  String get exportCSV => '匯出 CSV';

  @override
  String get clearAllData => '清除所有數據';

  @override
  String get clearAllDataSubtitle => '刪除所有統計數據和設定';

  @override
  String get clearData => '清除數據';

  @override
  String get deleteAccount => '刪除帳號';

  @override
  String get deleteAccountSubtitle => '永久刪除您的帳號和所有資料';

  @override
  String get version => 'Flow v1.0.0';

  @override
  String get copyright => '© 2024 Flow Team';

  @override
  String get pending => '待辦事項';

  @override
  String get activeTimer => '進行中的計時';

  @override
  String get focusingNow => '正在專注';

  @override
  String get tapToViewTimer => '點擊查看計時器';

  @override
  String get emptyPendingTasks => '暫無待辦任務';

  @override
  String get aiBreakdownDescription => '讓 AI 幫你拆解大任務';

  @override
  String get aiChatTitle => 'AI 助手';

  @override
  String get thinking => '正在思考...';

  @override
  String get clearConversation => '清空對話';

  @override
  String get confirmClearConversation => '確定要清空所有對話記錄嗎？';

  @override
  String get clearConversationButton => '清空';

  @override
  String get sendMessage => '發送訊息';

  @override
  String get typeMessage => '輸入訊息...';

  @override
  String get askAiHelper => '問問 AI 助手...';

  @override
  String get creatingTasks => '正在創建...';

  @override
  String get createTasks => '創建任務';

  @override
  String get editPlan => '編輯計畫';

  @override
  String get createDirectly => '直接創建';

  @override
  String get editTaskPlan => '編輯任務計畫';

  @override
  String get saveAndCreate => '儲存並創建';

  @override
  String get creating => '創建中...';

  @override
  String get mainGoal => '主要目標';

  @override
  String get enterMainGoal => '輸入主要目標';

  @override
  String totalTasks(int count) {
    return '總共 $count 個任務';
  }

  @override
  String totalPomodoros(int count) {
    return '總共 $count 個番茄鐘';
  }

  @override
  String get noTasksInPlan => '計畫中還沒有任務';

  @override
  String get newTask => '新任務';

  @override
  String get mainGoalRequired => '主要目標不能為空';

  @override
  String get atLeastOneTaskRequired => '至少需要一個任務';

  @override
  String get enterTaskDescription => '輸入任務描述';

  @override
  String get description => '描述';

  @override
  String get cannotExtractTasks => '無法從對話中提取任務，請嘗試更明確地描述任務';

  @override
  String get aiResponseFailed => 'AI 回覆失敗';

  @override
  String tasksCreatedSuccess(int count) {
    return '成功創建 $count 個任務！';
  }

  @override
  String get failedToCreateTasks => '創建任務失敗';

  @override
  String taskCreationFailed(String error) {
    return '創建任務失敗: $error';
  }

  @override
  String confirmAction(String action) {
    return '確認$action';
  }

  @override
  String confirmActionMessage(String action) {
    return '確定要執行$action操作嗎？此操作無法復原。';
  }

  @override
  String featureComingSoon(String action) {
    return '$action功能將在正式版本中實現';
  }

  @override
  String get hourShort => '時';

  @override
  String get minuteShort => '分';

  @override
  String get secondShort => '秒';

  @override
  String get hour => '小時';

  @override
  String get minute => '分鐘';

  @override
  String get second => '秒';

  @override
  String get focusMode => '專注時間';

  @override
  String get thisWeekOverview => '本週概覽';

  @override
  String get thisMonthOverview => '本月概覽';

  @override
  String hours(String count) {
    return '$count 小時';
  }

  @override
  String get thisWeekGoal => '本週目標';

  @override
  String get workDays => '工作天數';

  @override
  String get bestDay => '最佳單日';

  @override
  String get monthlyHeatmap => '月度專注熱力圖';

  @override
  String get thisMonthTrend => '本月趨勢';

  @override
  String get noPomodoros => '今天還沒有完成任何番茄鐘';

  @override
  String get thisWeekTrend => '本週趨勢';

  @override
  String get noWeekStats => '本週還沒有統計資料';

  @override
  String get bestFocusTime => '最佳專注時段（最近 30 天）';

  @override
  String get noMonthStats => '本月還沒有統計資料';

  @override
  String count(int count) {
    return '$count 個';
  }

  @override
  String get consecutiveFocus => '連續專注';

  @override
  String get notEnoughData => '還沒有足夠的資料';

  @override
  String get yourBestFocusTime => '您的最佳專注時段';

  @override
  String get morning => '早上';

  @override
  String get afternoon => '下午';

  @override
  String get evening => '傍晚';

  @override
  String get night => '深夜';

  @override
  String get morningTime => '6:00-12:00';

  @override
  String get afternoonTime => '12:00-18:00';

  @override
  String get eveningTime => '18:00-22:00';

  @override
  String get nightTime => '22:00-6:00';

  @override
  String completedPomodorosCount(int count) {
    return '已完成 $count 個番茄鐘';
  }

  @override
  String get copiedToClipboard => '已複製到剪貼簿';

  @override
  String get justNow => '剛剛';

  @override
  String minutesAgo(int count) {
    return '$count 分鐘前';
  }

  @override
  String hoursAgo(int count) {
    return '$count 小時前';
  }

  @override
  String get mondayShort => '週一';

  @override
  String get tuesdayShort => '週二';

  @override
  String get wednesdayShort => '週三';

  @override
  String get thursdayShort => '週四';

  @override
  String get fridayShort => '週五';

  @override
  String get saturdayShort => '週六';

  @override
  String get sundayShort => '週日';

  @override
  String pomodoroCountShort(int count) {
    return '$count 個番茄鐘';
  }

  @override
  String get less => '少';

  @override
  String get more => '多';

  @override
  String get helloAI => '你好！我是 AI 助手';

  @override
  String get aiDescription => '我是您的專注助手，可以幫您分析任務、提供建議';

  @override
  String get noTasksToSelect => '暫無可選擇的任務';

  @override
  String get pleaseAddTasksFirst => '請先在任務頁面添加一些任務';
}
