import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/task.dart';
import '../l10n/app_localizations.dart';

class TaskFormDialog extends StatefulWidget {
  final Task? task; // null表示新增，不為null表示編輯
  final bool aiPlanningMode;

  const TaskFormDialog({
    super.key,
    this.task,
    this.aiPlanningMode = false,
  });

  @override
  State<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pomodoroCountController = TextEditingController();
  final _goalController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _constraintsController = TextEditingController();

  TaskPriority _selectedPriority = TaskPriority.medium;
  TaskStatus _selectedStatus = TaskStatus.pending;

  bool get isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final task = widget.task!;
      _titleController.text = task.title;
      _descriptionController.text = task.description ?? '';
      _pomodoroCountController.text = task.pomodoroCount.toString();
      _selectedPriority = task.priority;
      _selectedStatus = task.status;
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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (widget.aiPlanningMode) {
      return AlertDialog(
        title: Text(l10n.describeTaskForAI),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: l10n.taskTitle,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
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
                  validator: (value) {
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
                  items: TaskPriority.values.map((priority) {
                    String label;
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
                    return DropdownMenuItem(value: priority, child: Text(label));
                  }).toList(),
                  onChanged: (value) {
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
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: _submitForm,
            child: Text(l10n.generatePlan),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text(isEditing ? l10n.editTask : l10n.addTask),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 任務標題
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: l10n.taskTitle,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.enterTaskTitle;
                  }
                  return null;
                },
                maxLength: 100,
              ),
              const SizedBox(height: 16),

              // 任務描述（選填）
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

              // 預估番茄鐘數量
              TextFormField(
                controller: _pomodoroCountController,
                decoration: InputDecoration(
                  labelText: l10n.estimatedPomodoros,
                  border: const OutlineInputBorder(),
                  suffix: const Text('個'),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.enterPomodoroCount;
                  }
                  final count = int.tryParse(value);
                  if (count == null || count < 1 || count > 20) {
                    return '請輸入1-20之間的數字';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 優先級選擇
              DropdownButtonFormField<TaskPriority>(
                initialValue: _selectedPriority,
                decoration: InputDecoration(
                  labelText: l10n.priority,
                  border: const OutlineInputBorder(),
                ),
                items: TaskPriority.values.map((priority) {
                  String label;
                  Color color;
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

                  return DropdownMenuItem(
                    value: priority,
                    child: Row(
                      children: [
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
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedPriority = value;
                    });
                  }
                },
              ),

              // 狀態選擇（編輯時顯示）
              if (isEditing) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<TaskStatus>(
                  initialValue: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: '狀態',
                    border: OutlineInputBorder(),
                  ),
                  items: TaskStatus.values.map((status) {
                    String label;
                    IconData icon;
                    switch (status) {
                      case TaskStatus.pending:
                        label = '待辦事項';
                        icon = Icons.pending_actions;
                        break;
                      case TaskStatus.inProgress:
                        label = '進行中';
                        icon = Icons.play_circle;
                        break;
                      case TaskStatus.completed:
                        label = '已完成';
                        icon = Icons.check_circle;
                        break;
                    }

                    return DropdownMenuItem(
                      value: status,
                      child: Row(
                        children: [
                          Icon(icon, size: 16),
                          const SizedBox(width: 8),
                          Text(label),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
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
      actions: [
        if (isEditing)
          TextButton(
            onPressed: () => Navigator.of(context).pop({'action': 'delete'}),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: Text(l10n.delete),
          )
        else
          const SizedBox.shrink(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (widget.aiPlanningMode) {
        final result = {
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

      final result = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'pomodoroCount': int.parse(_pomodoroCountController.text),
        'priority': _selectedPriority,
        'status': _selectedStatus,
      };

      Navigator.of(context).pop(result);
    }
  }
}
