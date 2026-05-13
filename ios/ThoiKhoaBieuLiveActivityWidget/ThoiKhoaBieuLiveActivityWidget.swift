import ActivityKit
import SwiftUI
import WidgetKit

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
        HStack {
          Image(systemName: context.state.status == "completed" ? "checkmark.circle.fill" : "book.closed.fill")
            .foregroundStyle(.blue)
          Text(context.state.status == "completed" ? "Hết môn rồi 🎉" : context.state.subjectName)
            .font(.headline)
            .lineLimit(1)
        }
        if context.state.status == "completed" {
          Text("Bạn đã hoàn thành lịch học hôm nay")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        } else {
          Text("\(context.state.startTime) - \(context.state.endTime)")
            .font(.subheadline)
          if !context.state.room.isEmpty {
            Text("Phòng: \(context.state.room)")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      }
      .padding()
      .activityBackgroundTint(Color(.systemBackground).opacity(0.82))
      .activitySystemActionForegroundColor(.blue)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Label(statusTitle(context.state.status), systemImage: statusIcon(context.state.status))
            .font(.caption.weight(.semibold))
        }
        DynamicIslandExpandedRegion(.trailing) {
          if context.state.status == "active" {
            Text("\(context.state.remainingMinutes)p")
              .font(.caption.weight(.bold))
          } else {
            Text(context.state.startTime)
              .font(.caption.weight(.bold))
          }
        }
        DynamicIslandExpandedRegion(.bottom) {
          VStack(alignment: .leading, spacing: 6) {
            Text(context.state.subjectName)
              .font(.headline)
              .lineLimit(1)
            if context.state.status != "completed" {
              Text("\(context.state.startTime) - \(context.state.endTime)")
                .font(.subheadline)
              if !context.state.room.isEmpty {
                Text("Phòng: \(context.state.room)")
                  .font(.caption)
              }
              if !context.state.teacher.isEmpty {
                Text("Giáo viên: \(context.state.teacher)")
                  .font(.caption)
              }
              if !context.state.nextSubjectName.isEmpty {
                Text("Tiếp theo: \(context.state.nextSubjectName)")
                  .font(.caption.weight(.semibold))
              }
            } else {
              Text("Bạn đã hoàn thành lịch học hôm nay")
                .font(.caption)
            }
          }
        }
      } compactLeading: {
        Image(systemName: statusIcon(context.state.status))
      } compactTrailing: {
        Text(context.state.status == "active" ? "\(context.state.remainingMinutes)p" : context.state.startTime)
          .font(.caption2.weight(.bold))
      } minimal: {
        Image(systemName: "clock")
      }
    }
  }

  private func statusTitle(_ status: String) -> String {
    switch status {
    case "active": return "Đang học"
    case "completed": return "Hoàn thành"
    default: return "Sắp học"
    }
  }

  private func statusIcon(_ status: String) -> String {
    switch status {
    case "active": return "play.circle.fill"
    case "completed": return "checkmark.circle.fill"
    default: return "clock.fill"
    }
  }
}

@main
struct ThoiKhoaBieuWidgetBundle: WidgetBundle {
  var body: some Widget {
    if #available(iOS 16.1, *) {
      ThoiKhoaBieuLiveActivityWidget()
    }
  }
}
