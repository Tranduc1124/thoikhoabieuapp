# Thời Khóa Biểu

Ứng dụng Flutter quản lý thời khóa biểu, lịch học hôm nay, nhắc lịch, chia sẻ lịch và hồ sơ học tập. Backend hiện dùng một API PHP/MySQL duy nhất tại `http://minhduc.huutien.store/api.php`.

## Chạy local

```bash
flutter pub get
flutter run
```

## Kiến trúc backend

- Flutter gọi `lib/api/api.dart`
- Mọi request đều `POST` đến `api.php`
- Backend xử lý theo `action + data`
- PHP dùng `PDO`, `utf8mb4`, prepared statements
- Dữ liệu lưu trong MySQL

Ví dụ payload:

```json
{
  "action": "schedule.create",
  "data": {
    "subjectName": "Toán",
    "dayOfWeek": 2,
    "startTime": 420,
    "endTime": 510
  }
}
```

## Backend setup

Toàn bộ hướng dẫn backend nằm trong [backend_php/README_BACKEND_SETUP.md](backend_php/README_BACKEND_SETUP.md).

Thư mục backend cần upload:

- `backend_php/api.php`
- `backend_php/install.php`
- `backend_php/config.php`
- `backend_php/uploads/avatars/`

## Codemagic

`codemagic.yaml` đã được dọn sạch Firebase. iOS build flow hiện chỉ cần:

1. `flutter clean`
2. `flutter pub get`
3. `pod install`
4. `flutter build ios --release --no-codesign`

## Ghi chú

- App không còn dùng Firebase Auth / Firestore / Firebase Storage.
- Android đã bỏ `google-services` plugin.
- iOS không còn yêu cầu `GoogleService-Info.plist`.
