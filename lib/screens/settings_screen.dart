import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../providers/timer_provider.dart';
import '../providers/statistics_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // 本地狀態（只用於 UI）
  bool _notifications = true;
  bool _vibration = false;
  bool _aiTaskBreakdown = true;
  bool _smartSuggestions = true;
  bool _dataAnalysis = false;
  bool _cloudSync = true;
  String _soundEffect = '鈴鐺';
  String _themeColor = '藍色 (預設)';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // TODO: 從 SharedPreferences 載入其他設定
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timerSettings = ref.watch(timerProvider);
    final statsProvider = ref.watch(statisticsProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          children: [
            // 用戶資訊
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    '王',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
                title: Text(
                  '王小明',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text('wang@example.com'),
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: theme.colorScheme.outline,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                tileColor: theme.colorScheme.primaryContainer,
              ),
            ),

            // 分組：番茄鐘設定
            _buildSectionTitle('番茄鐘設定'),
            _buildSettingTile(
              icon: Icons.timer,
              iconColor: theme.colorScheme.primary,
              title: '專注時間',
              subtitle: '每個番茄鐘的專注時長',
              trailing: _buildTimeSelector(
                timerSettings.focusTimeInMinutes,
                [15, 20, 25, 30, 45, 60],
                (value) {
                  ref.read(timerProvider.notifier).setFocusTime(value);
                },
              ),
            ),
            _buildSettingTile(
              icon: Icons.timer_outlined,
              iconColor: theme.colorScheme.primary,
              title: '短休息',
              subtitle: '完成一個番茄鐘後的休息時間',
              trailing: _buildTimeSelector(
                timerSettings.shortBreakTimeInMinutes,
                [5, 10, 15],
                (value) {
                  ref.read(timerProvider.notifier).setShortBreakTime(value);
                },
              ),
            ),
            _buildSettingTile(
              icon: Icons.timer_rounded,
              iconColor: theme.colorScheme.primary,
              title: '長休息',
              subtitle: '完成4個番茄鐘後的休息時間',
              trailing: _buildTimeSelector(
                timerSettings.longBreakTimeInMinutes,
                [15, 20, 25, 30],
                (value) {
                  ref.read(timerProvider.notifier).setLongBreakTime(value);
                },
              ),
            ),
            _buildSettingTile(
              icon: Icons.repeat,
              iconColor: theme.colorScheme.primary,
              title: '長休息頻率',
              subtitle: '每幾個番茄鐘後進行長休息',
              trailing: _buildDropdown<int>(4, [2, 3, 4, 5, 6], (value) {}),
            ),

            // 分組：目標設定
            _buildSectionTitle('目標設定'),
            _buildSettingTile(
              icon: Icons.flag,
              iconColor: theme.colorScheme.tertiary,
              title: '每日目標',
              subtitle: '每天想要完成的番茄鐘數量',
              trailing: _buildGoalSelector(
                statsProvider.dailyGoal,
                [4, 6, 8, 10, 12],
                (value) {
                  ref.read(statisticsProvider.notifier).setDailyGoal(value);
                },
              ),
            ),
            _buildSettingTile(
              icon: Icons.flag_outlined,
              iconColor: theme.colorScheme.tertiary,
              title: '每週目標',
              subtitle: '每週想要完成的番茄鐘數量',
              trailing: _buildGoalSelector(
                statsProvider.weeklyGoal,
                [20, 30, 40, 50, 60],
                (value) {
                  ref.read(statisticsProvider.notifier).setWeeklyGoal(value);
                },
              ),
            ),

            // 分組：通知設定
            _buildSectionTitle('通知設定'),
            _buildSettingTile(
              icon: Icons.notifications,
              iconColor: theme.colorScheme.secondary,
              title: '推播通知',
              subtitle: '時間結束時發送通知',
              trailing: Switch(
                value: _notifications,
                onChanged: (value) {
                  setState(() => _notifications = value);
                },
              ),
            ),
            _buildSettingTile(
              icon: Icons.music_note,
              iconColor: theme.colorScheme.secondary,
              title: '提示音效',
              subtitle: '選擇計時器結束時的音效',
              trailing: _buildDropdown<String>(_soundEffect, [
                '鈴鐺',
                '鳥鳴',
                '海浪',
                '無音效',
              ], (value) => setState(() => _soundEffect = value!)),
            ),
            _buildSettingTile(
              icon: Icons.vibration,
              iconColor: theme.colorScheme.secondary,
              title: '震動提醒',
              subtitle: '時間結束時震動提醒',
              trailing: Switch(
                value: _vibration,
                onChanged: (value) {
                  setState(() => _vibration = value);
                },
              ),
            ),

            // 分組：外觀設定
            _buildSectionTitle('外觀設定'),
            _buildSettingTile(
              icon: Icons.palette,
              iconColor: theme.colorScheme.primary,
              title: '主題模式',
              subtitle: '選擇應用程式的主題模式',
              trailing: _buildDropdown<String>(
                ref.read(themeModeProvider.notifier).getThemeModeString(),
                ['跟隨系統', '淺色模式', '深色模式'],
                (value) {
                  switch (value) {
                    case '跟隨系統':
                      ref.read(themeModeProvider.notifier).setSystemTheme();
                      break;
                    case '淺色模式':
                      ref.read(themeModeProvider.notifier).setLightTheme();
                      break;
                    case '深色模式':
                      ref.read(themeModeProvider.notifier).setDarkTheme();
                      break;
                  }
                },
              ),
            ),
            _buildSettingTile(
              icon: Icons.color_lens,
              iconColor: theme.colorScheme.primary,
              title: '主題色彩',
              subtitle: '選擇您喜歡的主題配色',
              trailing: _buildDropdown<String>(_themeColor, [
                '藍色 (預設)',
                '綠色',
                '紫色',
                '橙色',
              ], (value) => setState(() => _themeColor = value!)),
            ),

            // 分組：AI 設定
            _buildSectionTitle('AI 設定'),
            _buildSettingTile(
              icon: Icons.psychology,
              iconColor: theme.colorScheme.secondary,
              title: 'AI 任務拆解',
              subtitle: '允許 AI 幫助拆解複雜任務',
              trailing: Switch(
                value: _aiTaskBreakdown,
                onChanged: (value) {
                  setState(() => _aiTaskBreakdown = value);
                },
              ),
            ),
            _buildSettingTile(
              icon: Icons.lightbulb,
              iconColor: theme.colorScheme.secondary,
              title: '智慧建議',
              subtitle: '根據使用習慣提供個人化建議',
              trailing: Switch(
                value: _smartSuggestions,
                onChanged: (value) {
                  setState(() => _smartSuggestions = value);
                },
              ),
            ),
            _buildSettingTile(
              icon: Icons.analytics,
              iconColor: theme.colorScheme.secondary,
              title: '數據分析',
              subtitle: '允許分析使用數據以改善服務',
              trailing: Switch(
                value: _dataAnalysis,
                onChanged: (value) {
                  setState(() => _dataAnalysis = value);
                },
              ),
            ),

            // 分組：數據與同步
            _buildSectionTitle('數據與同步'),
            _buildSettingTile(
              icon: Icons.cloud,
              iconColor: theme.colorScheme.primary,
              title: '雲端同步',
              subtitle: '自動同步數據到雲端',
              trailing: Switch(
                value: _cloudSync,
                onChanged: (value) {
                  setState(() => _cloudSync = value);
                },
              ),
            ),
            _buildSettingTile(
              icon: Icons.download,
              iconColor: theme.colorScheme.primary,
              title: '匯出數據',
              subtitle: '下載您的統計數據',
              trailing: ElevatedButton(
                onPressed: () {},
                child: const Text('匯出 CSV'),
              ),
            ),

            // 分組：危險區域
            _buildSectionTitle('危險區域'),
            _buildSettingTile(
              icon: Icons.delete_forever,
              iconColor: theme.colorScheme.error,
              title: '清除所有數據',
              subtitle: '刪除所有統計數據和設定',
              trailing: ElevatedButton(
                onPressed: () => _showConfirmDialog('清除數據'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: Colors.white,
                ),
                child: const Text('清除數據'),
              ),
            ),
            _buildSettingTile(
              icon: Icons.person_off,
              iconColor: theme.colorScheme.error,
              title: '刪除帳號',
              subtitle: '永久刪除您的帳號和所有資料',
              trailing: ElevatedButton(
                onPressed: () => _showConfirmDialog('刪除帳號'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: Colors.white,
                ),
                child: const Text('刪除帳號'),
              ),
            ),

            // 版本信息
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      '專注番茄 v1.0.0',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '© 2024 Focus Tomato Team',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 分組標題
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 0, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // 設定項目 ListTile
  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withOpacity(0.15),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: trailing,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      minLeadingWidth: 36,
    );
  }

  Widget _buildTimeSelector(
    int currentValue,
    List<int> options,
    ValueChanged<int> onChanged,
  ) {
    return DropdownButton<int>(
      value: currentValue,
      items: options
          .map(
            (value) =>
                DropdownMenuItem<int>(value: value, child: Text('$value 分鐘')),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
      underline: Container(),
    );
  }

  Widget _buildGoalSelector(
    int currentValue,
    List<int> options,
    ValueChanged<int> onChanged,
  ) {
    return DropdownButton<int>(
      value: currentValue,
      items: options
          .map(
            (value) =>
                DropdownMenuItem<int>(value: value, child: Text('$value 個')),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
      underline: Container(),
    );
  }

  Widget _buildDropdown<T>(T value, List<T> items, ValueChanged<T?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButton<T>(
        value: value,
        items: items
            .map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Text(
                  item.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
        underline: Container(),
        borderRadius: BorderRadius.circular(16),
        dropdownColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );
  }

  void _showConfirmDialog(String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('確認$action'),
        content: Text('確定要執行$action操作嗎？此操作無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('$action功能將在正式版本中實現')));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }
}
