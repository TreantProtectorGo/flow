import '../l10n/app_localizations.dart';

/// Calculates the total estimated minutes for completing [totalPomodoros] pomodoros,
/// including focus time and breaks between pomodoros.
///
/// Break logic: After each pomodoro (except the last), a break is taken.
/// Every [longBreakFrequency]-th completed pomodoro triggers a long break;
/// all other breaks are short breaks.
///
/// Returns 0 if [totalPomodoros] <= 0.
int calculateEstimatedMinutes({
  required int totalPomodoros,
  required int focusMinutes,
  required int shortBreakMinutes,
  required int longBreakMinutes,
  required int longBreakFrequency,
}) {
  if (totalPomodoros <= 0) {
    return 0;
  }

  final normalizedFrequency = longBreakFrequency <= 0 ? 4 : longBreakFrequency;
  var totalMinutes = totalPomodoros * focusMinutes;

  for (var i = 1; i < totalPomodoros; i++) {
    if (i % normalizedFrequency == 0) {
      totalMinutes += longBreakMinutes;
    } else {
      totalMinutes += shortBreakMinutes;
    }
  }

  return totalMinutes;
}

/// Formats total minutes into a localized time string.
/// Uses l10n.hour/l10n.minute for display.
/// Returns just minutes if < 60, otherwise "X hour Y minute" format.
/// If minutes component is 0 after hours, returns just "X hour".
String formatEstimatedTime(int totalMinutes, AppLocalizations l10n) {
  if (totalMinutes < 60) {
    return '$totalMinutes ${l10n.minute}';
  }

  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  if (minutes == 0) {
    return '$hours ${l10n.hour}';
  }
  return '$hours ${l10n.hour} $minutes ${l10n.minute}';
}
