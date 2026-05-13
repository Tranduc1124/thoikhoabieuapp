# Thời Khoá Biểu

Ứng dụng iOS Flutter giúp học sinh/sinh viên quản lý lịch học tuần, lịch hôm nay, nhắc nhở trước giờ học, ghi chú sau buổi học và thống kê thời gian học. App dùng Firebase Authentication, Cloud Firestore, Riverpod, go_router, local notifications và Material 3.

## Chạy local

```bash
flutter pub get
flutter run
```

Nếu chưa cấu hình Firebase, app vẫn mở được tới màn hình đăng nhập và hiển thị cảnh báo cấu hình.

## Firebase

Firestore data path:

```text
users/{userId}
users/{userId}/schedules/{scheduleId}
users/{userId}/studyLogs/{logId}
```

Cấu hình iOS:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --platforms=ios
```

Sau đó đặt `GoogleService-Info.plist` vào `ios/Runner/`. Bật Firebase Authentication providers: Email/Password, Google và Apple. Với Apple Sign-In, bật capability tương ứng trong Apple Developer account và Xcode project.

## Codemagic

File `codemagic.yaml` đã có workflow `ios-release` với các bước:

- `flutter pub get`
- decode `GOOGLE_SERVICE_INFO_PLIST_BASE64` nếu dùng biến môi trường
- `pod install`
- `flutter build ios --release --no-codesign`

Để ký và upload TestFlight/App Store, cấu hình App Store Connect API key hoặc certificate/provisioning profile trong Codemagic, đổi `BUNDLE_ID`, rồi chuyển build command sang `flutter build ipa --release` với export options phù hợp.

## Pro features

App đã có thêm các nhóm tính năng:

- iPhone Widget data sync bằng `home_widget`, preview tại màn `Widget iPhone`.
- Notification settings lưu ở `users/{userId}/settings/notification`.
- Profile, avatar upload Firebase Storage với fallback local path, backup JSON.
- Chia sẻ lịch bằng ảnh, link và QR qua `public_shares/{shareId}`.
- Dynamic Island / Live Activities setting + safe native MethodChannel. Xem [README_DYNAMIC_ISLAND.md](README_DYNAMIC_ISLAND.md).

Firestore public share chỉ lưu snapshot lịch đã chọn, không lộ toàn bộ user data. Nếu dùng query quản lý link đã chia sẻ theo `ownerId + createdAt`, Firebase có thể yêu cầu tạo composite index theo link báo trong console.

Firebase Storage cần bật rules phù hợp cho avatar:

```text
users/{userId}/avatar.jpg
```

iOS WidgetKit target cần App Group thật. Xem [README_WIDGET_IOS.md](README_WIDGET_IOS.md).
Firebase setup/debug checklist: [README_FIREBASE_FIX.md](README_FIREBASE_FIX.md).
