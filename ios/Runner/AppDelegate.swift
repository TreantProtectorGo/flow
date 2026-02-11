import Flutter
import EventKit
import EventKitUI
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, EKEventEditViewDelegate {
  private let eventStore = EKEventStore()
  private var pendingCalendarResult: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Required for flutter_local_notifications on iOS 10+
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "focus/calendar",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        guard let self = self else {
          result(FlutterError(code: "UNAVAILABLE", message: "App delegate unavailable", details: nil))
          return
        }

        if call.method == "presentEventEditor" {
          guard
            let args = call.arguments as? [String: Any],
            let title = args["title"] as? String,
            let description = args["description"] as? String,
            let startMillis = args["startMillis"] as? NSNumber,
            let endMillis = args["endMillis"] as? NSNumber
          else {
            result(FlutterError(code: "BAD_ARGS", message: "Missing event arguments", details: nil))
            return
          }

          let startDate = Date(timeIntervalSince1970: startMillis.doubleValue / 1000.0)
          let endDate = Date(timeIntervalSince1970: endMillis.doubleValue / 1000.0)
          self.presentCalendarEditor(
            title: title,
            details: description,
            startDate: startDate,
            endDate: endDate,
            result: result
          )
          return
        }

        if call.method == "saveEvents" {
          guard
            let args = call.arguments as? [String: Any],
            let events = args["events"] as? [[String: Any]]
          else {
            result(FlutterError(code: "BAD_ARGS", message: "Missing events payload", details: nil))
            return
          }

          self.saveEvents(events, result: result)
          return
        }

        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func presentCalendarEditor(
    title: String,
    details: String,
    startDate: Date,
    endDate: Date,
    result: @escaping FlutterResult
  ) {
    if pendingCalendarResult != nil {
      result(FlutterError(code: "BUSY", message: "Calendar editor already open", details: nil))
      return
    }

    pendingCalendarResult = result

    requestEventAccess { [weak self] granted in
      guard let self = self else { return }

      guard granted else {
        self.completeCalendarResult(value: "canceled")
        return
      }

      DispatchQueue.main.async {
        guard let presenter = self.window?.rootViewController else {
          self.completeCalendarResult(value: "canceled")
          return
        }

        let event = EKEvent(eventStore: self.eventStore)
        event.title = title
        event.notes = details
        event.startDate = startDate
        event.endDate = endDate
        event.calendar = self.eventStore.defaultCalendarForNewEvents

        let editor = EKEventEditViewController()
        editor.eventStore = self.eventStore
        editor.event = event
        editor.editViewDelegate = self
        presenter.present(editor, animated: true)
      }
    }
  }

  private func requestEventAccess(completion: @escaping (Bool) -> Void) {
    if #available(iOS 17.0, *) {
      eventStore.requestFullAccessToEvents { granted, _ in
        completion(granted)
      }
      return
    }

    eventStore.requestAccess(to: .event) { granted, _ in
      completion(granted)
    }
  }

  private func saveEvents(
    _ events: [[String: Any]],
    result: @escaping FlutterResult
  ) {
    requestEventAccess { [weak self] granted in
      guard let self = self else { return }
      guard granted else {
        DispatchQueue.main.async {
          result(0)
        }
        return
      }

      var savedCount = 0
      for eventData in events {
        guard
          let title = eventData["title"] as? String,
          let description = eventData["description"] as? String,
          let startMillis = eventData["startMillis"] as? NSNumber,
          let endMillis = eventData["endMillis"] as? NSNumber
        else {
          continue
        }

        let event = EKEvent(eventStore: self.eventStore)
        event.title = title
        event.notes = description
        event.startDate = Date(timeIntervalSince1970: startMillis.doubleValue / 1000.0)
        event.endDate = Date(timeIntervalSince1970: endMillis.doubleValue / 1000.0)
        event.calendar = self.eventStore.defaultCalendarForNewEvents

        do {
          try self.eventStore.save(event, span: .thisEvent, commit: false)
          savedCount += 1
        } catch {
          continue
        }
      }

      do {
        try self.eventStore.commit()
      } catch {
        // Ignore commit error; return saved count that was attempted.
      }

      DispatchQueue.main.async {
        result(savedCount)
      }
    }
  }

  func eventEditViewController(
    _ controller: EKEventEditViewController,
    didCompleteWith action: EKEventEditViewAction
  ) {
    controller.dismiss(animated: true)

    switch action {
    case .saved:
      completeCalendarResult(value: "saved")
    case .canceled, .deleted:
      completeCalendarResult(value: "canceled")
    @unknown default:
      completeCalendarResult(value: "canceled")
    }
  }

  private func completeCalendarResult(value: String) {
    DispatchQueue.main.async {
      self.pendingCalendarResult?(value)
      self.pendingCalendarResult = nil
    }
  }
}
