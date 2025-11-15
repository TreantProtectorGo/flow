import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../providers/timer_provider.dart';
import '../providers/statistics_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';

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
  String _soundEffect = 'bell'; // 使用固定鍵值
  int _longBreakFrequency = 4;

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
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    // 將 ThemeMode 轉換為字串
    String getThemeModeString(ThemeMode mode) {
      switch (mode) {
        case ThemeMode.light:
          return AppLocalizations.of(context)!.themeLight;
        case ThemeMode.dark:
          return AppLocalizations.of(context)!.themeDark;
        case ThemeMode.system:
          return AppLocalizations.of(context)!.themeSystem;
      }
    }

    // 將 Locale 轉換為字串
    String getLocaleString(Locale locale) {
      return ref.read(localeProvider.notifier).getLocaleName(locale);
    }

    // 將音效鍵值轉換為顯示文字
    String getSoundEffectString(String key) {
      switch (key) {
        case 'bell':
          return AppLocalizations.of(context)!.soundBell;
        case 'bird':
          return AppLocalizations.of(context)!.soundBird;
        case 'wave':
          return AppLocalizations.of(context)!.soundWave;
        case 'none':
          return AppLocalizations.of(context)!.soundNone;
        default:
          return AppLocalizations.of(context)!.soundBell;
      }
    }

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
            _buildSectionTitle(AppLocalizations.of(context)!.pomodoroSettings),
            _buildSettingTile(
              icon: Icons.timer,
              iconColor: theme.colorScheme.primary,
              title: AppLocalizations.of(context)!.focusDuration,
              subtitle: AppLocalizations.of(context)!.focusDurationSubtitle,
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
              title: AppLocalizations.of(context)!.shortBreakDuration,
              subtitle: AppLocalizations.of(context)!.shortBreakSubtitle,
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
              title: AppLocalizations.of(context)!.longBreakDuration,
              subtitle: AppLocalizations.of(context)!.longBreakSubtitle,
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
              title: AppLocalizations.of(context)!.longBreakFrequency,
              subtitle: AppLocalizations.of(
                context,
              )!.longBreakFrequencySubtitle,
              trailing: DropdownButton<int>(
                value: _longBreakFrequency,
                items: [2, 3, 4, 5, 6]
                    .map(
                      (value) => DropdownMenuItem<int>(
                        value: value,
                        child: Text('$value'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _longBreakFrequency = value);
                  }
                },
                underline: Container(),
                borderRadius: BorderRadius.circular(16),
                dropdownColor: theme.colorScheme.surfaceContainerHighest,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),

            // 分組：目標設定
            _buildSectionTitle(AppLocalizations.of(context)!.goalSettings),
            _buildSettingTile(
              icon: Icons.flag,
              iconColor: theme.colorScheme.tertiary,
              title: AppLocalizations.of(context)!.dailyGoalTitle,
              subtitle: AppLocalizations.of(context)!.dailyGoalSubtitle,
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
              title: AppLocalizations.of(context)!.weeklyGoalTitle,
              subtitle: AppLocalizations.of(context)!.weeklyGoalSubtitle,
              trailing: _buildGoalSelector(
                statsProvider.weeklyGoal,
                [20, 30, 40, 50, 60],
                (value) {
                  ref.read(statisticsProvider.notifier).setWeeklyGoal(value);
                },
              ),
            ),

            // 分組：通知設定
            _buildSectionTitle(
              AppLocalizations.of(context)!.notificationSettings,
            ),
            _buildSettingTile(
              icon: Icons.notifications,
              iconColor: theme.colorScheme.secondary,
              title: AppLocalizations.of(context)!.pushNotifications,
              subtitle: AppLocalizations.of(context)!.pushNotificationsSubtitle,
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
              title: AppLocalizations.of(context)!.soundEffect,
              subtitle: AppLocalizations.of(context)!.soundEffectSubtitle,
              trailing: _buildDropdown<String>(
                getSoundEffectString(_soundEffect),
                [
                  AppLocalizations.of(context)!.soundBell,
                  AppLocalizations.of(context)!.soundBird,
                  AppLocalizations.of(context)!.soundWave,
                  AppLocalizations.of(context)!.soundNone,
                ],
                (value) {
                  String key = 'bell';
                  if (value == AppLocalizations.of(context)!.soundBell) {
                    key = 'bell';
                  } else if (value == AppLocalizations.of(context)!.soundBird) {
                    key = 'bird';
                  } else if (value == AppLocalizations.of(context)!.soundWave) {
                    key = 'wave';
                  } else if (value == AppLocalizations.of(context)!.soundNone) {
                    key = 'none';
                  }
                  setState(() => _soundEffect = key);
                },
              ),
            ),
            _buildSettingTile(
              icon: Icons.vibration,
              iconColor: theme.colorScheme.secondary,
              title: AppLocalizations.of(context)!.vibration,
              subtitle: AppLocalizations.of(context)!.vibrationSubtitle,
              trailing: Switch(
                value: _vibration,
                onChanged: (value) {
                  setState(() => _vibration = value);
                },
              ),
            ),

            // 分組：外觀設定
            _buildSectionTitle(
              AppLocalizations.of(context)!.appearanceSettings,
            ),
            _buildSettingTile(
              icon: Icons.palette,
              iconColor: theme.colorScheme.primary,
              title: AppLocalizations.of(context)!.themeMode,
              subtitle: AppLocalizations.of(context)!.themeModeSubtitle,
              trailing: _buildDropdown<String>(
                getThemeModeString(themeMode),
                [
                  AppLocalizations.of(context)!.themeSystem,
                  AppLocalizations.of(context)!.themeLight,
                  AppLocalizations.of(context)!.themeDark,
                ],
                (value) {
                  if (value == AppLocalizations.of(context)!.themeSystem) {
                    ref.read(themeModeProvider.notifier).setSystemTheme();
                  } else if (value ==
                      AppLocalizations.of(context)!.themeLight) {
                    ref.read(themeModeProvider.notifier).setLightTheme();
                  } else if (value == AppLocalizations.of(context)!.themeDark) {
                    ref.read(themeModeProvider.notifier).setDarkTheme();
                  }
                },
              ),
            ),
            _buildSettingTile(
              icon: Icons.language,
              iconColor: theme.colorScheme.primary,
              title: AppLocalizations.of(context)!.language,
              subtitle: AppLocalizations.of(context)!.languageSubtitle,
              trailing: _buildDropdown<String>(
                getLocaleString(locale),
                ['繁體中文', 'English'],
                (value) {
                  switch (value) {
                    case '繁體中文':
                      ref.read(localeProvider.notifier).setTraditionalChinese();
                      break;
                    case 'English':
                      ref.read(localeProvider.notifier).setEnglish();
                      break;
                  }
                },
              ),
            ),

            // 分組：AI 設定
            _buildSectionTitle(AppLocalizations.of(context)!.aiSettings),
            _buildSettingTile(
              icon: Icons.psychology,
              iconColor: theme.colorScheme.secondary,
              title: AppLocalizations.of(context)!.aiTaskBreakdown,
              subtitle: AppLocalizations.of(context)!.aiTaskBreakdownSubtitle,
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
              title: AppLocalizations.of(context)!.smartSuggestions,
              subtitle: AppLocalizations.of(context)!.smartSuggestionsSubtitle,
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
              title: AppLocalizations.of(context)!.dataAnalysis,
              subtitle: AppLocalizations.of(context)!.dataAnalysisSubtitle,
              trailing: Switch(
                value: _dataAnalysis,
                onChanged: (value) {
                  setState(() => _dataAnalysis = value);
                },
              ),
            ),

            // 分組：數據與同步
            _buildSectionTitle(AppLocalizations.of(context)!.dataAndSync),
            _buildSettingTile(
              icon: Icons.cloud,
              iconColor: theme.colorScheme.primary,
              title: AppLocalizations.of(context)!.cloudSync,
              subtitle: AppLocalizations.of(context)!.cloudSyncSubtitle,
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
              title: AppLocalizations.of(context)!.exportData,
              subtitle: AppLocalizations.of(context)!.exportDataSubtitle,
              trailing: ElevatedButton(
                onPressed: () {},
                child: Text(AppLocalizations.of(context)!.exportCSV),
              ),
            ),

            // 分組：危險區域
            _buildSectionTitle(AppLocalizations.of(context)!.dangerZone),
            _buildSettingTile(
              icon: Icons.delete_forever,
              iconColor: theme.colorScheme.error,
              title: AppLocalizations.of(context)!.clearAllData,
              subtitle: AppLocalizations.of(context)!.clearAllDataSubtitle,
              trailing: ElevatedButton(
                onPressed: () =>
                    _showConfirmDialog(AppLocalizations.of(context)!.clearData),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: Colors.white,
                ),
                child: Text(AppLocalizations.of(context)!.clearData),
              ),
            ),
            _buildSettingTile(
              icon: Icons.person_off,
              iconColor: theme.colorScheme.error,
              title: AppLocalizations.of(context)!.deleteAccount,
              subtitle: AppLocalizations.of(context)!.deleteAccountSubtitle,
              trailing: ElevatedButton(
                onPressed: () => _showConfirmDialog(
                  AppLocalizations.of(context)!.deleteAccount,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: Colors.white,
                ),
                child: Text(AppLocalizations.of(context)!.deleteAccount),
              ),
            ),

            // 版本信息
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.version,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.copyright,
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
    final theme = Theme.of(context);
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
      borderRadius: BorderRadius.circular(16),
      dropdownColor: theme.colorScheme.surfaceContainerHighest,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildGoalSelector(
    int currentValue,
    List<int> options,
    ValueChanged<int> onChanged,
  ) {
    final theme = Theme.of(context);
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
      borderRadius: BorderRadius.circular(16),
      dropdownColor: theme.colorScheme.surfaceContainerHighest,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildDropdown<T>(T value, List<T> items, ValueChanged<T?> onChanged) {
    final theme = Theme.of(context);
    return DropdownButton<T>(
      value: value,
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(
                item.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      underline: Container(),
      borderRadius: BorderRadius.circular(16),
      dropdownColor: theme.colorScheme.surfaceContainerHighest,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
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
