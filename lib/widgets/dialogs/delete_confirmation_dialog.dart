import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// A reusable confirmation dialog for delete actions
/// 
/// This dialog follows Material 3 design guidelines and provides
/// a consistent delete confirmation experience across the app.
/// 
/// Usage:
/// ```dart
/// final confirmed = await DeleteConfirmationDialog.show(
///   context,
///   title: task.title,
/// );
/// if (confirmed == true) {
///   // Perform delete action
/// }
/// ```
class DeleteConfirmationDialog {
  /// Shows a confirmation dialog for deleting an item
  /// 
  /// Returns `true` if user confirms, `false` if cancelled, or `null` if dismissed
  static Future<bool?> show(
    BuildContext context, {
    required String title,
  }) {
    final l10n = AppLocalizations.of(context)!;
    
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteTask),
        content: Text(l10n.confirmDelete(title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}
