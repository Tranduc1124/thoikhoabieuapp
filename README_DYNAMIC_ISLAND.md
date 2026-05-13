# Dynamic Island / Live Activities

Flutter side is implemented in:

- `lib/services/live_activity_service.dart`
- `users/{userId}/settings/app.dynamicIslandEnabled`
- `users/{userId}/settings/app.liveActivitiesEnabled`

The Settings screen hides the Dynamic Island section unless native iOS reports Live Activities support. Android/Web/Windows are no-op and never show the toggle.

## Native iOS already added

`ios/Runner/AppDelegate.swift` now exposes a safe MethodChannel:

```text
thoikhoabieu/live_activity
```

Methods:

- `isSupported`
- `areEnabled`
- `start`
- `update`
- `completedToday`
- `end`

`ios/Runner/Info.plist` includes:

```xml
<key>NSSupportsLiveActivities</key>
<true/>
<key>NSSupportsLiveActivitiesFrequentUpdates</key>
<true/>
```

## Required Widget Extension for visible Dynamic Island UI

ActivityKit can start/update the Live Activity from the Runner app, but the visible Lock Screen / Dynamic Island UI is rendered by a Widget Extension. Add a Widget Extension target named:

```text
ThoiKhoaBieuLiveActivityWidget
```

Use the same attributes/state shape as `ClassScheduleActivityAttributes` in `AppDelegate.swift`.
Sample extension source has been added under:

```text
ios/ThoiKhoaBieuLiveActivityWidget/
```

Add those files to the Widget Extension target in Xcode. They are intentionally not wired into `project.pbxproj` automatically because the target requires a real Team ID, bundle id and provisioning profile.

Minimal SwiftUI widget code:

```swift
import ActivityKit
import WidgetKit
import SwiftUI

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
struct ThoiKhoaBieuLiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: ClassScheduleActivityAttributes.self) { context in
      VStack(alignment: .leading, spacing: 8) {
        Text(context.state.status == "completed" ? "Hết môn rồi 🎉" : context.state.subjectName)
          .font(.headline)
        Text("\(context.state.startTime) - \(context.state.endTime)")
          .font(.subheadline)
        if !context.state.room.isEmpty { Text(context.state.room).font(.caption) }
      }
      .padding()
      .activityBackgroundTint(Color.black.opacity(0.08))
      .activitySystemActionForegroundColor(.blue)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Label(context.state.status == "active" ? "Đang học" : "Sắp học", systemImage: "book")
        }
        DynamicIslandExpandedRegion(.trailing) {
          Text("\(context.state.remainingMinutes)p")
        }
        DynamicIslandExpandedRegion(.bottom) {
          VStack(alignment: .leading) {
            Text(context.state.subjectName).font(.headline)
            Text("\(context.state.startTime) - \(context.state.endTime)")
            if !context.state.room.isEmpty { Text("Phòng: \(context.state.room)") }
            if !context.state.teacher.isEmpty { Text("GV: \(context.state.teacher)") }
            if !context.state.nextSubjectName.isEmpty { Text("Tiếp theo: \(context.state.nextSubjectName)") }
          }
        }
      } compactLeading: {
        Image(systemName: "book.closed")
      } compactTrailing: {
        Text(context.state.status == "active" ? "\(context.state.remainingMinutes)p" : context.state.startTime)
      } minimal: {
        Image(systemName: "clock")
      }
    }
  }
}
```

## Codemagic

When the Widget Extension target is added:

- Add signing/provisioning for both Runner and the widget extension.
- Ensure deployment target is iOS 16.1+ for the widget extension.
- Keep `flutter build ios --release --no-codesign` for compile-only builds, or use `flutter build ipa --release` once signing is configured.
