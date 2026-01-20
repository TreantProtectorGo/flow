import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// A reusable confirmation dialog for various actions
/// 
/// This dialog follows Material 3 design guidelines and provides
/// a consistent confirmation experience across the app.
/// 
/// Usage:
/// ```dart
/// final confirmed = await ConfirmationDialog.show(
///   context,
///   title: 'Clear History',
///   content: 'Are you sure you want to clear all history?',
///   confirmText: 'Clear',
///   isDangerous: true,
/// );
/// if (confirmed == true) {
///   // Perform action
/// }
/// ```
class ConfirmationDialog {
  ConfirmationDialog._(); // Private constructor

  /// Shows a confirmation dialog
  /// 
  /// Returns `true` if user confirms, `false` if cancelled, or `null` if dismissed
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String content,
    String? confirmText,
    String? cancelText,
    bool isDangerous = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText ?? l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: isDangerous 
                ? FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                  )
                : null,
            child: Text(confirmText ?? l10n.confirm),
          ),
        ],
      ),
    );
  }
}
