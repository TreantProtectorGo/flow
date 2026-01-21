import 'package:flutter/material.dart';

/// Utility class for showing Snackbar
/// Ensures only one Snackbar is shown at a time
class SnackBarUtil {
  /// Show simple info message
  static void showInfoSnackBar(
    BuildContext context, {
    required String message,
    IconData? icon,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    _showSnackBar(
      context,
      message: message,
      icon: icon,
      duration: duration,
      action: action,
    );
  }

  /// Show success message Snackbar
  static void showSuccessSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    _showSnackBar(
      context,
      message: message,
      icon: Icons.check_circle_outline,
      duration: duration,
      action: action,
    );
  }

  /// Show error message Snackbar
  static void showErrorSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    _showSnackBar(
      context,
      message: message,
      icon: Icons.error_outline,
      duration: duration,
      action: action,
    );
  }

  /// Base Snackbar display method
  static void _showSnackBar(
    BuildContext context, {
    required String message,
    IconData? icon,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    // Hide current Snackbar before showing new one
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final theme = Theme.of(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: theme.colorScheme.onInverseSurface),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: theme.colorScheme.onInverseSurface),
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.inverseSurface.withValues(
          alpha: 0.9,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: duration,
        action: action,
      ),
    );
  }
}
