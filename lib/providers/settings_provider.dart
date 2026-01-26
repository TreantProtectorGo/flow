import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App settings model
/// 
/// Contains all user preferences that need to be persisted.
class AppSettings {
  final bool notifications;
  final bool vibration;
  final String soundEffect;
  final int longBreakFrequency;
  final bool aiTaskBreakdown;
  final bool smartSuggestions;
  final bool dataAnalysis;
  final bool cloudSync;

  const AppSettings({
    this.notifications = true,
    this.vibration = false,
    this.soundEffect = 'bell',
    this.longBreakFrequency = 4,
    this.aiTaskBreakdown = true,
    this.smartSuggestions = true,
    this.dataAnalysis = false,
    this.cloudSync = true,
  });

  AppSettings copyWith({
    bool? notifications,
    bool? vibration,
    String? soundEffect,
    int? longBreakFrequency,
    bool? aiTaskBreakdown,
    bool? smartSuggestions,
    bool? dataAnalysis,
    bool? cloudSync,
  }) {
    return AppSettings(
      notifications: notifications ?? this.notifications,
      vibration: vibration ?? this.vibration,
      soundEffect: soundEffect ?? this.soundEffect,
      longBreakFrequency: longBreakFrequency ?? this.longBreakFrequency,
      aiTaskBreakdown: aiTaskBreakdown ?? this.aiTaskBreakdown,
      smartSuggestions: smartSuggestions ?? this.smartSuggestions,
      dataAnalysis: dataAnalysis ?? this.dataAnalysis,
      cloudSync: cloudSync ?? this.cloudSync,
    );
  }
}

/// Settings notifier - manages app settings with persistence
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _loadSettings();
  }

  // SharedPreferences keys
  static const String _notificationsKey = 'settings_notifications';
  static const String _vibrationKey = 'settings_vibration';
  static const String _soundEffectKey = 'settings_sound_effect';
  static const String _longBreakFrequencyKey = 'settings_long_break_frequency';
  static const String _aiTaskBreakdownKey = 'settings_ai_task_breakdown';
  static const String _smartSuggestionsKey = 'settings_smart_suggestions';
  static const String _dataAnalysisKey = 'settings_data_analysis';
  static const String _cloudSyncKey = 'settings_cloud_sync';

  /// Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      state = AppSettings(
        notifications: prefs.getBool(_notificationsKey) ?? true,
        vibration: prefs.getBool(_vibrationKey) ?? false,
        soundEffect: prefs.getString(_soundEffectKey) ?? 'bell',
        longBreakFrequency: prefs.getInt(_longBreakFrequencyKey) ?? 4,
        aiTaskBreakdown: prefs.getBool(_aiTaskBreakdownKey) ?? true,
        smartSuggestions: prefs.getBool(_smartSuggestionsKey) ?? true,
        dataAnalysis: prefs.getBool(_dataAnalysisKey) ?? false,
        cloudSync: prefs.getBool(_cloudSyncKey) ?? true,
      );
    } catch (e) {
      // Keep default values if loading fails
    }
  }

  /// Save all settings to SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool(_notificationsKey, state.notifications);
      await prefs.setBool(_vibrationKey, state.vibration);
      await prefs.setString(_soundEffectKey, state.soundEffect);
      await prefs.setInt(_longBreakFrequencyKey, state.longBreakFrequency);
      await prefs.setBool(_aiTaskBreakdownKey, state.aiTaskBreakdown);
      await prefs.setBool(_smartSuggestionsKey, state.smartSuggestions);
      await prefs.setBool(_dataAnalysisKey, state.dataAnalysis);
      await prefs.setBool(_cloudSyncKey, state.cloudSync);
    } catch (e) {
      // Handle error silently
    }
  }

  // Individual setters with auto-save

  void setNotifications(bool value) {
    state = state.copyWith(notifications: value);
    _saveSettings();
  }

  void setVibration(bool value) {
    state = state.copyWith(vibration: value);
    _saveSettings();
  }

  void setSoundEffect(String value) {
    state = state.copyWith(soundEffect: value);
    _saveSettings();
  }

  void setLongBreakFrequency(int value) {
    state = state.copyWith(longBreakFrequency: value);
    _saveSettings();
  }

  void setAITaskBreakdown(bool value) {
    state = state.copyWith(aiTaskBreakdown: value);
    _saveSettings();
  }

  void setSmartSuggestions(bool value) {
    state = state.copyWith(smartSuggestions: value);
    _saveSettings();
  }

  void setDataAnalysis(bool value) {
    state = state.copyWith(dataAnalysis: value);
    _saveSettings();
  }

  void setCloudSync(bool value) {
    state = state.copyWith(cloudSync: value);
    _saveSettings();
  }
}

/// Provider for app settings
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>(
  (ref) => SettingsNotifier(),
);
