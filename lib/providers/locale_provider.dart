import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 語言設定 Provider
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (ref) => LocaleNotifier(),
);

class LocaleNotifier extends StateNotifier<Locale> {
  static const String _localeKey = 'locale';

  LocaleNotifier() : super(const Locale('zh', 'TW')) {
    _loadLocale();
  }

  /// 載入儲存的語言設定
  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('${_localeKey}_language');
    final countryCode = prefs.getString('${_localeKey}_country');

    if (languageCode != null) {
      state = Locale(languageCode, countryCode);
    }
  }

  /// 儲存語言設定
  Future<void> _saveLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_localeKey}_language', locale.languageCode);
    if (locale.countryCode != null) {
      await prefs.setString('${_localeKey}_country', locale.countryCode!);
    }
  }

  /// 設定為繁體中文
  Future<void> setTraditionalChinese() async {
    state = const Locale('zh', 'TW');
    await _saveLocale(state);
  }

  /// 設定為簡體中文
  Future<void> setSimplifiedChinese() async {
    state = const Locale('zh', 'CN');
    await _saveLocale(state);
  }

  /// 設定為英文
  Future<void> setEnglish() async {
    state = const Locale('en');
    await _saveLocale(state);
  }

  /// 設定自訂語言
  Future<void> setLocale(Locale locale) async {
    state = locale;
    await _saveLocale(locale);
  }

  /// 取得當前語言的顯示名稱
  String getLocaleName(Locale locale) {
    if (locale.languageCode == 'zh') {
      if (locale.countryCode == 'TW') {
        return '繁體中文';
      } else if (locale.countryCode == 'CN') {
        return '简体中文';
      }
    } else if (locale.languageCode == 'en') {
      return 'English';
    }
    return locale.toString();
  }

  /// 取得支援的語言列表
  static const List<Locale> supportedLocales = [
    Locale('zh', 'TW'), // 繁體中文
    Locale('en'), // 英文
  ];
}
