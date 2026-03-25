import 'package:flutter_test/flutter_test.dart';

import 'package:focus/l10n/app_localizations_en.dart';
import 'package:focus/l10n/app_localizations_zh.dart';

void main() {
  test('pomodoro progress localizations no longer embed tomato emoji', () {
    final AppLocalizationsEn en = AppLocalizationsEn();
    final AppLocalizationsZh zh = AppLocalizationsZh();

    expect(en.pomodoroProgress(0, 2), '0/2');
    expect(zh.pomodoroProgress(0, 2), '0/2');
  });
}
