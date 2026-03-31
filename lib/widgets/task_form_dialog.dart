import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/task.dart';
import '../providers/settings_provider.dart';

class TaskFormDialog extends ConsumerStatefulWidget {
  final Task? task;
  final bool aiPlanningMode;

  const TaskFormDialog({super.key, this.task, this.aiPlanningMode = false});

  @override
  ConsumerState<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends ConsumerState<TaskFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _pomodoroCountController =
      TextEditingController();
  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();
  final TextEditingController _constraintsController = TextEditingController();

  TaskPriority _selectedPriority = TaskPriority.medium;
  TaskStatus _selectedStatus = TaskStatus.pending;
  bool _reminderEnabled = false;
  TimeOfDay _selectedReminderTime = const TimeOfDay(hour: 9, minute: 0);

  bool get isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final Task task = widget.task!;
      _titleController.text = task.title;
      _descriptionController.text = task.description ?? '';
      _pomodoroCountController.text = task.pomodoroCount.toString();
      _selectedPriority = task.priority;
      _selectedStatus = task.status;
      if (task.dailyReminderTime != null) {
        _reminderEnabled = true;
        _selectedReminderTime = _parseReminderTime(task.dailyReminderTime!);
      }
    } else {
      _pomodoroCountController.text = '1';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pomodoroCountController.dispose();
    _goalController.dispose();
    _deadlineController.dispose();
    _constraintsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    if (widget.aiPlanningMode) {
      return _buildAiPlanningDialog(context, l10n);
    }

    final bool notificationsEnabled = ref.watch(settingsProvider).notifications;

    return AlertDialog(
      title: Text(isEditing ? l10n.editTask : l10n.addTask),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: l10n.taskTitle,
                  border: const OutlineInputBorder(),
                ),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.enterTaskTitle;
                  }
                  return null;
                },
                maxLength: 100,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: l10n.taskDescriptionOptional,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                maxLength: 500,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pomodoroCountController,
                decoration: InputDecoration(
                  labelText: l10n.estimatedPomodoros,
                  border: const OutlineInputBorder(),
                  suffix: Text(l10n.pomodoros),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.enterPomodoroCount;
                  }
                  final int? count = int.tryParse(value);
                  if (count == null || count < 1 || count > 20) {
                    return l10n.pomodoroCountRange;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildReminderSection(
                context: context,
                theme: theme,
                l10n: l10n,
                notificationsEnabled: notificationsEnabled,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TaskPriority>(
                initialValue: _selectedPriority,
                decoration: InputDecoration(
                  labelText: l10n.priority,
                  border: const OutlineInputBorder(),
                ),
                items: TaskPriority.values.map((TaskPriority priority) {
                  late final String label;
                  late final Color color;
                  switch (priority) {
                    case TaskPriority.high:
                      label = l10n.highPriority;
                      color = theme.colorScheme.error;
                      break;
                    case TaskPriority.medium:
                      label = l10n.mediumPriority;
                      color = theme.colorScheme.tertiary;
                      break;
                    case TaskPriority.low:
                      label = l10n.lowPriority;
                      color = theme.colorScheme.primary;
                      break;
                  }

                  return DropdownMenuItem<TaskPriority>(
                    value: priority,
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(label),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (TaskPriority? value) {
                  if (value != null) {
                    setState(() {
                      _selectedPriority = value;
                    });
                  }
                },
              ),
              if (isEditing) ...<Widget>[
                const SizedBox(height: 16),
                DropdownButtonFormField<TaskStatus>(
                  initialValue: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: l10n.status,
                    border: const OutlineInputBorder(),
                  ),
                  items: TaskStatus.values.map((TaskStatus status) {
                    late final String label;
                    late final IconData icon;
                    switch (status) {
                      case TaskStatus.pending:
                        label = l10n.statusPending;
                        icon = Icons.pending_actions;
                        break;
                      case TaskStatus.inProgress:
                        label = l10n.statusInProgress;
                        icon = Icons.play_circle;
                        break;
                      case TaskStatus.completed:
                        label = l10n.statusCompleted;
                        icon = Icons.check_circle;
                        break;
                    }

                    return DropdownMenuItem<TaskStatus>(
                      value: status,
                      child: Row(
                        children: <Widget>[
                          Icon(icon, size: 16),
                          const SizedBox(width: 8),
                          Text(label),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (TaskStatus? value) {
                    if (value != null) {
                      setState(() {
                        _selectedStatus = value;
                      });
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: <Widget>[
        if (isEditing)
          TextButton(
            onPressed: () => Navigator.of(
              context,
            ).pop(<String, dynamic>{'action': 'delete'}),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: Text(l10n.delete),
          )
        else
          const SizedBox.shrink(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _submitForm,
              child: Text(isEditing ? l10n.update : l10n.add),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAiPlanningDialog(BuildContext context, AppLocalizations l10n) {
    return AlertDialog(
      title: Text(l10n.describeTaskForAI),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: l10n.taskTitle,
                  border: const OutlineInputBorder(),
                ),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.enterTaskTitle;
                  }
                  return null;
                },
                maxLength: 100,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _goalController,
                decoration: InputDecoration(
                  labelText: l10n.aiGoal,
                  border: const OutlineInputBorder(),
                ),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.aiGoalRequired;
                  }
                  return null;
                },
                maxLength: 200,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: l10n.taskDescriptionOptional,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                maxLength: 500,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _deadlineController,
                decoration: InputDecoration(
                  labelText: l10n.aiDeadline,
                  border: const OutlineInputBorder(),
                ),
                maxLength: 80,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _constraintsController,
                decoration: InputDecoration(
                  labelText: l10n.aiConstraints,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                maxLength: 300,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TaskPriority>(
                initialValue: _selectedPriority,
                decoration: InputDecoration(
                  labelText: l10n.priority,
                  border: const OutlineInputBorder(),
                ),
                items: TaskPriority.values.map((TaskPriority priority) {
                  late final String label;
                  switch (priority) {
                    case TaskPriority.high:
                      label = l10n.highPriority;
                      break;
                    case TaskPriority.medium:
                      label = l10n.mediumPriority;
                      break;
                    case TaskPriority.low:
                      label = l10n.lowPriority;
                      break;
                  }

                  return DropdownMenuItem<TaskPriority>(
                    value: priority,
                    child: Text(label),
                  );
                }).toList(),
                onChanged: (TaskPriority? value) {
                  if (value != null) {
                    setState(() {
                      _selectedPriority = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submitForm, child: Text(l10n.generatePlan)),
      ],
    );
  }

  Widget _buildReminderSection({
    required BuildContext context,
    required ThemeData theme,
    required AppLocalizations l10n,
    required bool notificationsEnabled,
  }) {
    final String reminderLabel = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(_selectedReminderTime);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.notifications_active_outlined,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.dailyReminder,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch(
                value: _reminderEnabled,
                onChanged: notificationsEnabled
                    ? (bool value) {
                        setState(() {
                          _reminderEnabled = value;
                        });
                      }
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            notificationsEnabled
                ? l10n.dailyReminderHelper
                : l10n.dailyReminderDisabledHelper,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (_reminderEnabled) ...<Widget>[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: notificationsEnabled
                  ? () => _pickReminderTime(context)
                  : null,
              icon: const Icon(Icons.schedule),
              label: Text('${l10n.dailyReminderTime}: $reminderLabel'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickReminderTime(BuildContext context) async {
    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: _selectedReminderTime,
    );

    if (selectedTime != null) {
      setState(() {
        _selectedReminderTime = selectedTime;
      });
    }
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.aiPlanningMode) {
      final Map<String, dynamic> result = <String, dynamic>{
        'title': _titleController.text.trim(),
        'goal': _goalController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'deadline': _deadlineController.text.trim().isEmpty
            ? null
            : _deadlineController.text.trim(),
        'constraints': _constraintsController.text.trim().isEmpty
            ? null
            : _constraintsController.text.trim(),
        'priority': _selectedPriority,
      };

      Navigator.of(context).pop(result);
      return;
    }

    final Map<String, dynamic> result = <String, dynamic>{
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      'pomodoroCount': int.parse(_pomodoroCountController.text),
      'priority': _selectedPriority,
      'status': _selectedStatus,
      'dailyReminderTime': _reminderEnabled
          ? _encodeReminderTime(_selectedReminderTime)
          : null,
    };

    Navigator.of(context).pop(result);
  }

  TimeOfDay _parseReminderTime(String value) {
    final List<String> parts = value.split(':');
    return TimeOfDay(
      hour: int.parse(parts.first),
      minute: int.parse(parts.last),
    );
  }

  String _encodeReminderTime(TimeOfDay timeOfDay) {
    final String hour = timeOfDay.hour.toString().padLeft(2, '0');
    final String minute = timeOfDay.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
