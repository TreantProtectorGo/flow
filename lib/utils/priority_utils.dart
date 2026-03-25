import 'package:flutter/material.dart';

/// Utility class for task priority-related styling
///
/// Centralizes priority color logic to avoid repetition across the app.
/// Follows Material 3 semantic color guidelines:
/// - High priority → Error container (red tones)
/// - Medium priority → Secondary container (default)
/// - Low priority → Tertiary container (green tones)
class PriorityUtils {
  PriorityUtils._(); // Private constructor to prevent instantiation

  /// Returns the background color for a given priority level
  static Color getBackgroundColor(String priority, ColorScheme colorScheme) {
    switch (priority.toLowerCase()) {
      case 'high':
        return colorScheme.errorContainer;
      case 'low':
        return colorScheme.tertiaryContainer;
      default: // medium
        return colorScheme.secondaryContainer;
    }
  }

  /// Returns the foreground (text/icon) color for a given priority level
  static Color getForegroundColor(String priority, ColorScheme colorScheme) {
    switch (priority.toLowerCase()) {
      case 'high':
        return colorScheme.onErrorContainer;
      case 'low':
        return colorScheme.onTertiaryContainer;
      default: // medium
        return colorScheme.onSecondaryContainer;
    }
  }

  /// Returns an IconData representing the priority level
  static IconData getIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Icons.keyboard_double_arrow_up;
      case 'low':
        return Icons.keyboard_double_arrow_down;
      default: // medium
        return Icons.remove;
    }
  }
}
