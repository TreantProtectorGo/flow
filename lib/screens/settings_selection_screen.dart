import 'package:flutter/material.dart';

class SettingsSelectionScreen<T> extends StatefulWidget {
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
  State<SettingsSelectionScreen<T>> createState() => _SettingsSelectionScreenState<T>();
}

class _SettingsSelectionScreenState<T> extends State<SettingsSelectionScreen<T>> {
  late T _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.currentValue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(widget.title),
            pinned: true,
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final option = widget.options[index];
                return RadioListTile<T>(
                  value: option,
                  groupValue: _selectedValue,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedValue = value);
                      widget.onSelected(value);
                    }
                  },
                  title: Text(
                    widget.getLabel(option),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                );
              },
              childCount: widget.options.length,
            ),
          ),
        ],
      ),
    );
  }
}
