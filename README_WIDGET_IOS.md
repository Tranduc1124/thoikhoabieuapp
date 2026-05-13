# iOS Home Screen Widget

Flutter đã có `WidgetSyncService` dùng `home_widget` để ghi dữ liệu local cho iOS WidgetKit:

- `nextSubjectName`
- `nextStartTime`
- `nextEndTime`
- `nextRoom`
- `nextTeacher`
- `todayClassCount`
- `todayClasses`
- `themeMode`
- `lastUpdated`

Service tự chạy khi app khởi động và khi lịch học thay đổi. Trong app có màn `Widget iPhone` để preview small/medium/large và sync thủ công.

## App Group

Giá trị mặc định đang dùng:

```text
group.com.minhduc.thoikhoabieuapp.widget
```

Khi đổi bundle id thật, hãy đổi hằng số `WidgetSyncService.appGroupId` trong `lib/services/widget_sync_service.dart` và cấu hình cùng App Group trong Apple Developer + Codemagic signing.

## Tạo WidgetKit extension

Vì WidgetKit target cần Team ID, Bundle ID và App Group capability thật, không nên tự sửa `project.pbxproj` khi chưa có thông tin signing. Cách an toàn:

1. Mở project bằng Xcode trên macOS hoặc Codemagic remote machine.
2. File > New > Target > Widget Extension.
3. Đặt tên target: `ThoiKhoaBieuWidget`.
4. Bật App Groups cho app target và widget target.
5. Thêm cùng app group: `group.com.minhduc.thoikhoabieuapp.widget`.
6. Trong Swift widget, đọc `UserDefaults(suiteName:)` theo app group và render small/medium/large.

Ví dụ Swift đọc dữ liệu:

```swift
let defaults = UserDefaults(suiteName: "group.com.minhduc.thoikhoabieuapp.widget")
let nextSubjectName = defaults?.string(forKey: "nextSubjectName") ?? "Không có lịch"
let todayClasses = defaults?.string(forKey: "todayClasses") ?? "[]"
```

## Codemagic

Khi đã thêm widget extension:

- Cấu hình provisioning profile cho cả app target và widget target.
- Bật App Groups trong Apple Developer.
- Nếu build ipa/TestFlight, dùng signing thật thay vì `--no-codesign`.
