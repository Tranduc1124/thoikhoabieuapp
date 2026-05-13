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
