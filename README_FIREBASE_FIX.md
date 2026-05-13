# Firebase Fix Checklist

## 1. FlutterFire config

Chạy lại khi đổi bundle id/package id:

```bash
dart pub global activate flutterfire_cli
dart pub global run flutterfire_cli:flutterfire configure
```

Kiểm tra file:

```text
lib/firebase_options.dart
```

App đang initialize bằng:

```dart
Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
)
```

## 2. iOS

File bắt buộc:

```text
ios/Runner/GoogleService-Info.plist
```

Bundle id hiện được đồng bộ:

```text
com.minhduc.thoikhoabieuapp
```

Kiểm tra các nơi sau phải cùng bundle id iOS:

- Firebase Console > iOS app bundle id
- `ios/Runner/GoogleService-Info.plist` > `BUNDLE_ID`
- `ios/Runner.xcodeproj/project.pbxproj` > `PRODUCT_BUNDLE_IDENTIFIER`
- `codemagic.yaml` > `BUNDLE_ID`

Podfile đã đặt:

```ruby
platform :ios, '15.0'
```

Lệnh local trên macOS:

```bash
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter build ios --release --no-codesign
```

## 3. Android

File bắt buộc:

```text
android/app/google-services.json
```

Package id hiện tại:

```text
com.minhduc.thoikhoabieuapp
```

Kiểm tra `android/app/build.gradle.kts`:

```kotlin
applicationId = "com.minhduc.thoikhoabieuapp"
id("com.google.gms.google-services")
```

## 4. Authentication

Firebase Console > Authentication > Sign-in method:

- Bật Email/Password
- Bật Google nếu dùng Google Sign-In
- Bật Apple nếu dùng Apple Sign-In

App đã map lỗi tiếng Việt cho:

- `invalid-email`
- `user-not-found`
- `wrong-password`
- `invalid-credential`
- `email-already-in-use`
- `weak-password`
- `network-request-failed`
- `operation-not-allowed`

Nếu gặp `operation-not-allowed`, hãy bật Email/Password trong Firebase Authentication.

## 5. Firestore

Cấu trúc dữ liệu:

```text
users/{userId}
users/{userId}/schedules/{scheduleId}
users/{userId}/studyLogs/{logId}
users/{userId}/settings/app
users/{userId}/settings/notification
public_shares/{shareId}
```

Rules gợi ý:

```text
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      match /{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }

    match /public_shares/{shareId} {
      allow read: if resource.data.isActive == true;
      allow create: if request.auth != null
        && request.resource.data.ownerId == request.auth.uid;
      allow update, delete: if request.auth != null
        && resource.data.ownerId == request.auth.uid;
    }
  }
}
```

Nếu app báo `permission-denied`, kiểm tra rules trên và user đã đăng nhập chưa.

## 6. Storage

Avatar upload dùng:

```text
users/{userId}/avatar.jpg
```

Rules gợi ý:

```text
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

Nếu Storage chưa bật, app fallback avatar path local và không crash.

## 7. Diagnostics

Trong app:

```text
Cài đặt > Đồng bộ & Sao lưu > Firebase diagnostics
```

Màn này kiểm tra:

- `Firebase.apps.isNotEmpty`
- Project ID
- App ID
- Platform
- Auth current user
- Firestore test write nếu đã đăng nhập

Không log secret/private key.

## 8. Codemagic

Workflow `ios-release` đã có:

- `flutter create --platforms=ios .`
- set deployment target iOS 15.0
- set bundle id từ biến `BUNDLE_ID`
- `flutter clean`
- `flutter pub get`
- decode `GOOGLE_SERVICE_INFO_PLIST_BASE64` nếu có
- fail rõ nếu thiếu `GoogleService-Info.plist`
- `pod install`
- `flutter build ios --release --no-codesign`

Nếu không commit plist, thêm env var:

```text
GOOGLE_SERVICE_INFO_PLIST_BASE64
```

Không hardcode secret trong `codemagic.yaml`.

## 9. Lỗi thường gặp

- App báo Firebase khởi tạo thất bại: kiểm tra `firebase_options.dart`, plist/json và bundle id.
- iOS build lỗi pods: chạy `flutter clean`, `flutter pub get`, `cd ios && pod install`.
- Auth `operation-not-allowed`: bật Email/Password trong Firebase Console.
- Firestore `permission-denied`: sửa Firestore rules.
- Google Sign-In lỗi iOS: kiểm tra URL scheme từ `REVERSED_CLIENT_ID` trong `GoogleService-Info.plist`.
