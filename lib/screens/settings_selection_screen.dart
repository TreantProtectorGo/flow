import 'package:flutter/material.dart';

class SettingsSelectionScreen<T> extends StatelessWidget {
  final String title;
  final List<T> options;
  final T currentValue;
  final String Function(T) getLabel;
  final ValueChanged<T> onSelected;

  const SettingsSelectionScreen({
    super.key,
    required this.title,
    required this.options,
    required this.currentValue,
    required this.getLabel,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: ListView(
        children: options.map((option) {
          final isSelected = option == currentValue;
          return RadioListTile<T>(
            title: Text(
              getLabel(option),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : null,
                  ),
            ),
            value: option,
            groupValue: currentValue,
            onChanged: (value) {
              if (value != null) {
                onSelected(value);
                // Do not auto-pop the page
              }
            },
            secondary: isSelected
                ? Icon(
                    Icons.check,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            controlAffinity: ListTileControlAffinity.trailing,
          );
        }).toList(),
      ),
    );
  }
}
