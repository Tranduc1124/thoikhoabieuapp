import Flutter
import UIKit
import ActivityKit

@available(iOS 16.1, *)
struct ClassScheduleActivityAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    var status: String
    var subjectName: String
    var startTime: String
    var endTime: String
    var room: String
    var teacher: String
    var nextSubjectName: String
    var remainingMinutes: Int
  }

  var activityId: String
}

@available(iOS 16.1, *)
enum ClassScheduleLiveActivityBridge {
  static func areEnabled() -> Bool {
    return ActivityAuthorizationInfo().areActivitiesEnabled
  }

  static func start(arguments: [String: Any]) async throws {
    guard areEnabled() else { return }
    await end()
    let current = arguments["current"] as? [String: Any]
    let next = arguments["next"] as? [String: Any]
    let visible = current ?? next
    let attributes = ClassScheduleActivityAttributes(
      activityId: (visible?["id"] as? String) ?? UUID().uuidString
    )
    let state = stateFrom(
      current: current,
      next: next,
      status: (arguments["status"] as? String) ?? "upcoming",
      remainingMinutes: (arguments["remainingMinutes"] as? Int) ?? 0
    )
    _ = try Activity<ClassScheduleActivityAttributes>.request(
      attributes: attributes,
      contentState: state,
      pushType: nil
    )
  }

  static func update(arguments: [String: Any]) async {
    guard areEnabled() else { return }
    if Activity<ClassScheduleActivityAttributes>.activities.isEmpty {
      try? await start(arguments: arguments)
      return
    }
    let state = stateFrom(
      current: arguments["current"] as? [String: Any],
      next: arguments["next"] as? [String: Any],
      status: (arguments["status"] as? String) ?? "upcoming",
      remainingMinutes: (arguments["remainingMinutes"] as? Int) ?? 0
    )
    for activity in Activity<ClassScheduleActivityAttributes>.activities {
      await activity.update(using: state)
    }
  }

  static func completedToday() async {
    guard areEnabled() else { return }
    let state = ClassScheduleActivityAttributes.ContentState(
      status: "completed",
      subjectName: "Hết môn rồi 🎉",
      startTime: "",
      endTime: "",
      room: "Bạn đã hoàn thành lịch học hôm nay",
      teacher: "",
      nextSubjectName: "",
      remainingMinutes: 0
    )
    if Activity<ClassScheduleActivityAttributes>.activities.isEmpty {
      let attributes = ClassScheduleActivityAttributes(activityId: UUID().uuidString)
      _ = try? Activity<ClassScheduleActivityAttributes>.request(
        attributes: attributes,
        contentState: state,
        pushType: nil
      )
      return
    }
    for activity in Activity<ClassScheduleActivityAttributes>.activities {
      await activity.update(using: state)
    }
  }

  static func end() async {
    for activity in Activity<ClassScheduleActivityAttributes>.activities {
      await activity.end(dismissalPolicy: .immediate)
    }
  }

  private static func stateFrom(
    current: [String: Any]?,
    next: [String: Any]?,
    status: String,
    remainingMinutes: Int = 0
  ) -> ClassScheduleActivityAttributes.ContentState {
    let visible = current ?? next
    return ClassScheduleActivityAttributes.ContentState(
      status: status,
      subjectName: (visible?["subjectName"] as? String) ?? "Không có lịch",
      startTime: (visible?["startTime"] as? String) ?? "",
      endTime: (visible?["endTime"] as? String) ?? "",
      room: (visible?["room"] as? String) ?? "",
      teacher: (visible?["teacher"] as? String) ?? "",
      nextSubjectName: (next?["subjectName"] as? String) ?? "",
      remainingMinutes: remainingMinutes
    )
  }
}

enum LiveActivityChannelConfigurator {
  static func configure(controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: "thoikhoabieu/live_activity",
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "isSupported":
        if #available(iOS 16.1, *) {
          result(UIDevice.current.userInterfaceIdiom == .phone)
        } else {
          result(false)
        }
      case "areEnabled":
        if #available(iOS 16.1, *) {
          result(ClassScheduleLiveActivityBridge.areEnabled())
        } else {
          result(false)
        }
      case "start":
        guard #available(iOS 16.1, *) else {
          result(nil)
          return
        }
        Task {
          do {
            try await ClassScheduleLiveActivityBridge.start(
              arguments: call.arguments as? [String: Any] ?? [:]
            )
            result(nil)
          } catch {
            result(FlutterError(code: "LIVE_ACTIVITY_START_FAILED", message: error.localizedDescription, details: nil))
          }
        }
      case "update":
        guard #available(iOS 16.1, *) else {
          result(nil)
          return
        }
        Task {
          await ClassScheduleLiveActivityBridge.update(
            arguments: call.arguments as? [String: Any] ?? [:]
          )
          result(nil)
        }
      case "completedToday":
        guard #available(iOS 16.1, *) else {
          result(nil)
          return
        }
        Task {
          await ClassScheduleLiveActivityBridge.completedToday()
          result(nil)
        }
      case "updateRemainingTime":
        result(nil)
      case "end":
        guard #available(iOS 16.1, *) else {
          result(nil)
          return
        }
        Task {
          await ClassScheduleLiveActivityBridge.end()
          result(nil)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let ok = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    configureLiveActivityChannel()
    return ok
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func configureLiveActivityChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }
    LiveActivityChannelConfigurator.configure(controller: controller)
  }
}
