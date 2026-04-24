import ActivityKit
import AlarmKit
import SwiftUI
import WidgetKit

@available(iOS 26.0, *)
struct FocusTaskAlarmMetadata: AlarmMetadata {
  let taskId: String
  let nextTaskId: String?
  let sectionId: String?
  let phaseIndex: Int
  let payloadType: String
  let taskTitle: String
  let pomodoroProgress: String
}

@available(iOS 26.0, *)
struct FocusTimerLiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: AlarmAttributes<FocusTaskAlarmMetadata>.self) { context in
      FocusTimerLockScreenView(context: context)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Label("Flow", systemImage: "timer")
        }
        DynamicIslandExpandedRegion(.trailing) {
          Text(context.attributes.metadata?.pomodoroProgress ?? "")
            .monospacedDigit()
        }
        DynamicIslandExpandedRegion(.bottom) {
          FocusTimerCountdownText(context: context)
        }
      } compactLeading: {
        Image(systemName: "timer")
      } compactTrailing: {
        FocusTimerCountdownText(context: context)
          .font(.caption2)
          .monospacedDigit()
      } minimal: {
        Image(systemName: "timer")
      }
    }
  }
}

@available(iOS 26.0, *)
private struct FocusTimerLockScreenView: View {
  let context: ActivityViewContext<AlarmAttributes<FocusTaskAlarmMetadata>>

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Label("Flow", systemImage: "timer")
          .font(.headline)
        Spacer()
        Text(context.attributes.metadata?.pomodoroProgress ?? "")
          .font(.headline)
          .monospacedDigit()
      }

      Text(context.attributes.metadata?.taskTitle ?? "")
        .font(.subheadline)
        .lineLimit(1)

      FocusTimerCountdownText(context: context)
        .font(.title2)
        .monospacedDigit()
    }
    .padding()
    .activityBackgroundTint(.blue.opacity(0.16))
    .activitySystemActionForegroundColor(.blue)
  }
}

@available(iOS 26.0, *)
private struct FocusTimerCountdownText: View {
  let context: ActivityViewContext<AlarmAttributes<FocusTaskAlarmMetadata>>

  var body: some View {
    if let fireDate {
      Text(timerInterval: Date()...fireDate, countsDown: true)
    } else {
      Text(context.attributes.metadata?.taskTitle ?? "Focus")
    }
  }

  private var fireDate: Date? {
    switch context.state.mode {
    case .countdown(let countdown):
      return countdown.fireDate
    case .alert(let alert):
      return Calendar.current.nextDate(
        after: Date(),
        matching: DateComponents(hour: alert.time.hour, minute: alert.time.minute),
        matchingPolicy: .nextTime
      )
    case .paused:
      return nil
    @unknown default:
      return nil
    }
  }
}

@main
@available(iOS 26.0, *)
struct FocusTimerWidgetBundle: WidgetBundle {
  var body: some Widget {
    FocusTimerLiveActivityWidget()
  }
}
