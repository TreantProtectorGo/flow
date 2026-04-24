import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task_timer_plan.dart';

export '../models/task_timer_plan.dart';

class TaskTimerSystemPayload {
  final TaskTimerPayloadType type;
  final String taskId;
  final String? nextTaskId;
  final String? sectionId;
  final int phaseIndex;

  const TaskTimerSystemPayload({
    required this.type,
    required this.taskId,
    required this.nextTaskId,
    required this.sectionId,
    required this.phaseIndex,
  });

  factory TaskTimerSystemPayload.fromMap(Map<Object?, Object?> map) {
    final String typeName = map['type'] as String? ?? 'phaseEnd';
    return TaskTimerSystemPayload(
      type: TaskTimerPayloadType.values.firstWhere(
        (TaskTimerPayloadType type) => type.name == typeName,
        orElse: () => TaskTimerPayloadType.phaseEnd,
      ),
      taskId: map['taskId'] as String? ?? '',
      nextTaskId: map['nextTaskId'] as String?,
      sectionId: map['sectionId'] as String?,
      phaseIndex: (map['phaseIndex'] as num?)?.toInt() ?? 0,
    );
  }
}

abstract class TaskTimerSystemScheduler {
  Future<void> initialize();

  Future<void> scheduleTaskTimeline(TaskTimerPlan plan);

  Future<void> cancelTaskTimeline(String taskId);

  Future<void> rescheduleTaskTimeline(TaskTimerPlan plan);
}

final Provider<TaskTimerSystemScheduler> taskTimerSystemSchedulerProvider =
    Provider<TaskTimerSystemScheduler>((Ref ref) {
      return PlatformTaskTimerSystemScheduler.instance;
    });

final StreamProvider<TaskTimerSystemPayload> taskTimerSystemPayloadProvider =
    StreamProvider<TaskTimerSystemPayload>((Ref ref) {
      return PlatformTaskTimerSystemScheduler.instance.payloads;
    });

class PlatformTaskTimerSystemScheduler implements TaskTimerSystemScheduler {
  static const MethodChannel _channel = MethodChannel(
    'focus/task_timer_system',
  );

  static final PlatformTaskTimerSystemScheduler instance =
      PlatformTaskTimerSystemScheduler._();

  final StreamController<TaskTimerSystemPayload> _payloadController =
      StreamController<TaskTimerSystemPayload>.broadcast();
  bool _initialized = false;

  PlatformTaskTimerSystemScheduler._();

  Stream<TaskTimerSystemPayload> get payloads => _payloadController.stream;

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _channel.setMethodCallHandler(_handleMethodCall);
    _initialized = true;
  }

  @override
  Future<void> scheduleTaskTimeline(TaskTimerPlan plan) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    await initialize();
    try {
      await _channel.invokeMethod<void>('scheduleTaskTimeline', plan.toJson());
    } on MissingPluginException catch (e) {
      debugPrint('[TASK_TIMER_SYSTEM] Missing platform plugin: $e');
    } catch (e) {
      debugPrint('[TASK_TIMER_SYSTEM] Failed to schedule timeline: $e');
    }
  }

  @override
  Future<void> cancelTaskTimeline(String taskId) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    await initialize();
    try {
      await _channel.invokeMethod<void>('cancelTaskTimeline', <String, Object?>{
        'taskId': taskId,
      });
    } on MissingPluginException catch (e) {
      debugPrint('[TASK_TIMER_SYSTEM] Missing platform plugin: $e');
    } catch (e) {
      debugPrint('[TASK_TIMER_SYSTEM] Failed to cancel timeline: $e');
    }
  }

  @override
  Future<void> rescheduleTaskTimeline(TaskTimerPlan plan) async {
    await cancelTaskTimeline(plan.taskId);
    await scheduleTaskTimeline(plan);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method != 'taskTimerPayload') {
      return;
    }

    final Object? arguments = call.arguments;
    if (arguments is Map<Object?, Object?>) {
      _payloadController.add(TaskTimerSystemPayload.fromMap(arguments));
    }
  }
}
