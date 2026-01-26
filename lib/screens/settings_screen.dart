import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../providers/timer_provider.dart';
import '../providers/statistics_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/snackbar_util.dart';
import '../l10n/app_localizations.dart';
import '../widgets/dialogs/confirmation_dialog.dart';
import 'settings_selection_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timerSettings = ref.watch(timerProvider);
    final statsProvider = ref.watch(statisticsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final appSettings = ref.watch(settingsProvider);

    // Convert ThemeMode to string
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

    // Convert Locale to string
    String getLocaleString(Locale locale) {
      return ref.read(localeProvider.notifier).getLocaleName(locale);
    }

    // Convert sound effect key value to display text
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
            // User information
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

            // Section: Pomodoro settings
            _buildSectionTitle(AppLocalizations.of(context)!.pomodoroSettings),
            _buildSettingTile(
              icon: Icons.timer,
              iconColor: theme.colorScheme.primary,
              title: AppLocalizations.of(context)!.focusDuration,
              subtitle: AppLocalizations.of(context)!.focusDurationSubtitle,
              valueText: AppLocalizations.of(
                context,
              )!.minutesUnit(timerSettings.focusTimeInMinutes),
              onTap: () => _navigateToSelectionScreen<int>(
                title: AppLocalizations.of(context)!.focusDuration,
                currentValue: timerSettings.focusTimeInMinutes,
                options: [15, 20, 25, 30, 45, 60],
                getLabel: (value) =>
                    AppLocalizations.of(context)!.minutesUnit(value),
                onSelected: (value) {
                  ref.read(timerProvider.notifier).setFocusTime(value);
                },
              ),
            ),
            _buildSettingTile(
              icon: Icons.timer_outlined,
              iconColor: theme.colorScheme.primary,
              title: AppLocalizations.of(context)!.shortBreakDuration,
              subtitle: AppLocalizations.of(context)!.shortBreakSubtitle,
              valueText: AppLocalizations.of(
                context,
              )!.minutesUnit(timerSettings.shortBreakTimeInMinutes),
              onTap: () => _navigateToSelectionScreen<int>(
                title: AppLocalizations.of(context)!.shortBreakDuration,
                currentValue: timerSettings.shortBreakTimeInMinutes,
                options: [5, 10, 15],
                getLabel: (value) =>
                    AppLocalizations.of(context)!.minutesUnit(value),
                onSelected: (value) {
                  ref.read(timerProvider.notifier).setShortBreakTime(value);
                },
              ),
            ),
            _buildSettingTile(
              icon: Icons.timer_rounded,
              iconColor: theme.colorScheme.primary,
              title: AppLocalizations.of(context)!.longBreakDuration,
              subtitle: AppLocalizations.of(context)!.longBreakSubtitle,
              valueText: AppLocalizations.of(
                context,
              )!.minutesUnit(timerSettings.longBreakTimeInMinutes),
              onTap: () => _navigateToSelectionScreen<int>(
                title: AppLocalizations.of(context)!.longBreakDuration,
                currentValue: timerSettings.longBreakTimeInMinutes,
                options: [15, 20, 25, 30],
                getLabel: (value) =>
                    AppLocalizations.of(context)!.minutesUnit(value),
                onSelected: (value) {
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
              valueText: '${appSettings.longBreakFrequency}',
              onTap: () => _navigateToSelectionScreen<int>(
                title: AppLocalizations.of(context)!.longBreakFrequency,
                currentValue: appSettings.longBreakFrequency,
                options: [2, 3, 4, 5, 6],
                getLabel: (value) => '$value',
                onSelected: (value) {
                  ref
                      .read(settingsProvider.notifier)
                      .setLongBreakFrequency(value);
                },
              ),
            ),

            // Section: Goal settings
            _buildSectionTitle(AppLocalizations.of(context)!.goalSettings),
            _buildSettingTile(
              icon: Icons.flag,
              iconColor: theme.colorScheme.tertiary,
              title: AppLocalizations.of(context)!.dailyGoalTitle,
              subtitle: AppLocalizations.of(context)!.dailyGoalSubtitle,
              valueText: '${statsProvider.dailyGoal}',
              onTap: () => _navigateToSelectionScreen<int>(
                title: AppLocalizations.of(context)!.dailyGoalTitle,
                currentValue: statsProvider.dailyGoal,
                options: [4, 6, 8, 10, 12],
                getLabel: (value) => '$value',
                onSelected: (value) {
                  ref.read(statisticsProvider.notifier).setDailyGoal(value);
                },
              ),
            ),
            _buildSettingTile(
              icon: Icons.flag_outlined,
              iconColor: theme.colorScheme.tertiary,
              title: AppLocalizations.of(context)!.weeklyGoalTitle,
              subtitle: AppLocalizations.of(context)!.weeklyGoalSubtitle,
              valueText: '${statsProvider.weeklyGoal}',
              onTap: () => _navigateToSelectionScreen<int>(
                title: AppLocalizations.of(context)!.weeklyGoalTitle,
                currentValue: statsProvider.weeklyGoal,
                options: [20, 30, 40, 50, 60],
                getLabel: (value) => '$value',
                onSelected: (value) {
                  ref.read(statisticsProvider.notifier).setWeeklyGoal(value);
                },
              ),
            ),

            // Section: Notification settings
            _buildSectionTitle(
              AppLocalizations.of(context)!.notificationSettings,
            ),
            _buildSettingTile(
              icon: Icons.notifications,
              iconColor: theme.colorScheme.secondary,
              title: AppLocalizations.of(context)!.pushNotifications,
              subtitle: AppLocalizations.of(context)!.pushNotificationsSubtitle,
              trailing: Switch(
                value: appSettings.notifications,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setNotifications(value);
                },
              ),
            ),
            _buildSettingTile(
              icon: Icons.music_note,
              iconColor: theme.colorScheme.secondary,
              title: AppLocalizations.of(context)!.soundEffect,
              subtitle: AppLocalizations.of(context)!.soundEffectSubtitle,
              valueText: getSoundEffectString(appSettings.soundEffect),
              onTap: () => _navigateToSelectionScreen<String>(
                title: AppLocalizations.of(context)!.soundEffect,
                currentValue: appSettings.soundEffect,
                options: ['bell', 'bird', 'wave', 'none'],
                getLabel: (value) => getSoundEffectString(value),
                onSelected: (value) {
                  ref.read(settingsProvider.notifier).setSoundEffect(value);
                },
              ),
            ),
            _buildSettingTile(
              icon: Icons.vibration,
              iconColor: theme.colorScheme.secondary,
              title: AppLocalizations.of(context)!.vibration,
              subtitle: AppLocalizations.of(context)!.vibrationSubtitle,
              trailing: Switch(
                value: appSettings.vibration,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setVibration(value);
                },
              ),
            ),

            // Section: Appearance settings
            _buildSectionTitle(
              AppLocalizations.of(context)!.appearanceSettings,
            ),
            _buildSettingTile(
              icon: Icons.palette,
              iconColor: theme.colorScheme.primary,
              title: AppLocalizations.of(context)!.themeMode,
              subtitle: AppLocalizations.of(context)!.themeModeSubtitle,
              valueText: getThemeModeString(themeMode),
              onTap: () => _navigateToSelectionScreen<ThemeMode>(
                title: AppLocalizations.of(context)!.themeMode,
                currentValue: themeMode,
                options: [ThemeMode.system, ThemeMode.light, ThemeMode.dark],
                getLabel: (value) => getThemeModeString(value),
                onSelected: (value) {
                  if (value == ThemeMode.system) {
                    ref.read(themeModeProvider.notifier).setSystemTheme();
                  } else if (value == ThemeMode.light) {
                    ref.read(themeModeProvider.notifier).setLightTheme();
                  } else if (value == ThemeMode.dark) {
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
              valueText: getLocaleString(locale),
              onTap: () => _navigateToSelectionScreen<String>(
                title: AppLocalizations.of(context)!.language,
                currentValue: locale.languageCode == 'zh' ? 'zh' : 'en',
                options: ['zh', 'en'],
                getLabel: (value) => value == 'zh' ? '繁體中文' : 'English',
                onSelected: (value) {
                  if (value == 'zh') {
                    ref.read(localeProvider.notifier).setTraditionalChinese();
                  } else {
                    ref.read(localeProvider.notifier).setEnglish();
                  }
                  Navigator.of(context).pop();
                },
              ),
            ),

            // Section: Data and sync
            _buildSectionTitle(AppLocalizations.of(context)!.dataAndSync),
            _buildSettingTile(
              icon: Icons.cloud,
              iconColor: theme.colorScheme.primary,
              title: AppLocalizations.of(context)!.cloudSync,
              subtitle: AppLocalizations.of(context)!.cloudSyncSubtitle,
              trailing: Switch(
                value: appSettings.cloudSync,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setCloudSync(value);
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

            // Section: Danger zone
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

            // Version information
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

  // Section title
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

  // Settings item ListTile
  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    String? valueText,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withOpacity(0.15),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing:
          trailing ??
          (valueText != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      valueText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                )
              : null),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      minLeadingWidth: 36,
    );
  }

  // Navigate to selection screen
  void _navigateToSelectionScreen<T>({
    required String title,
    required T currentValue,
    required List<T> options,
    required String Function(T) getLabel,
    required ValueChanged<T> onSelected,
  }) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => SettingsSelectionScreen<T>(
          title: title,
          currentValue: currentValue,
          options: options,
          getLabel: getLabel,
          onSelected: onSelected,
        ),
      ),
    );
  }

  Future<void> _showConfirmDialog(String action) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await ConfirmationDialog.show(
      context,
      title: l10n.confirmAction(action),
      content: l10n.confirmActionMessage(action),
      confirmText: l10n.confirm,
      cancelText: l10n.cancel,
      isDangerous: true,
    );

    if (confirmed == true && mounted) {
      SnackBarUtil.showInfoSnackBar(
        context,
        message: l10n.featureComingSoon(action),
      );
    }
  }
}
