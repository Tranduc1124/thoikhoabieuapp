# Debug Fixes Checklist

## 1. Test Dark Mode

1. Vào `Cài đặt` trong app.
2. Chọn theme `Tối`.
3. Kiểm tra các màn: Home, Hôm nay, Tuần, Thống kê, Cài đặt, Profile, Thông báo, Chia sẻ.
4. Đảm bảo không có card trắng gắt, text mờ, icon chìm hoặc nút khó đọc.

## 2. Test Đổi Màu Môn Học

1. Tạo hoặc sửa một môn học.
2. Chọn một palette trong mục `Màu sắc`.
3. Bấm lưu.
4. Quay về Home hoặc Tuần và kiểm tra card đổi màu ngay.
5. Đóng và mở lại app để đảm bảo màu vẫn được đọc từ Firestore field `color`.

Lưu ý: lịch cũ chưa có field `color` sẽ dùng fallback palette theo hash tên môn, không mất dữ liệu cũ.

## 3. Test Notification 10 Giây

1. Vào `Cài đặt` > `Thông báo`.
2. Bật thông báo toàn app.
3. Cấp quyền notification khi iOS hỏi.
4. Bấm `Test 10 giây`.
5. Đưa app ra background và chờ notification.

## 4. Kiểm Tra Pending Notifications

Trong màn `Thông báo`, bấm `Lên lịch lại`.

App sẽ:

- reschedule toàn bộ notification lịch học
- log danh sách pending notifications bằng `debugPrint`
- hiển thị popup hoặc trạng thái thành công tùy màn

## 5. Test Dynamic Island / Live Activities

Điều kiện:

- iOS 16.1+
- iPhone hỗ trợ Live Activities / Dynamic Island
- build trên thiết bị thật

Cách test:

1. Đăng nhập và có lịch học trong hôm nay.
2. Vào `Cài đặt`.
3. Nếu máy hỗ trợ, section `Dynamic Island` sẽ hiện.
4. Bật toggle.
5. Mở app gần giờ học hoặc trong giờ học.
6. Kiểm tra Live Activity hiển thị môn sắp học hoặc đang học.

Máy không hỗ trợ sẽ không hiện section Dynamic Island và app không gọi native API.

## 6. Test Share Link

1. Vào màn `Chia sẻ thời khóa biểu`.
2. Chọn phạm vi chia sẻ.
3. Bấm `Tạo link + QR`.
4. Kiểm tra popup thành công xuất hiện.
5. Tại màn preview, bấm `Mở share sheet`.
6. Xác nhận native share sheet mở ra.

Debug log mong đợi:

- `share started`
- `firestore upload success`
- `link generated`
- `share sheet opened`

## 7. Test QR Code

1. Tạo một share mới.
2. Vào màn preview.
3. Kiểm tra QR có hiện và không rỗng.
4. Bấm `Share ảnh QR` hoặc `Lưu poster`.
5. Quét QR bằng camera hoặc sao chép link công khai từ app.
6. Dán vào màn `Nhập lịch được chia sẻ` để xác nhận app mở đúng snapshot.

## 8. Test Import Shared Timetable

1. Mở `/shared/<shareId>` hoặc dán link vào màn import.
2. Kiểm tra preview hiện:
   - tên owner
   - danh sách môn
   - số buổi học
3. Chọn một vài buổi học.
4. Bấm `Import`.
5. Kiểm tra popup thành công và Home/Week đã nhận dữ liệu mới.

App tự bỏ qua các lịch bị trùng `subjectName + dayOfWeek + startTime + endTime`.

## 9. Test Deep Links

### Android

- App có `intent-filter` cho:
  - `thoikhoabieu://share/<id>`
  - `https://thoikhoabieuapp.page.link/share/<id>`

### iOS

- App có `CFBundleURLTypes` cho scheme `thoikhoabieu`
- Test trực tiếp với:

```bash
xcrun simctl openurl booted "thoikhoabieu://share/<shareId>"
```

Nếu chưa có universal links thật, iOS sẽ mở chắc chắn bằng custom scheme.

## 10. Test NFC Support Fallback

NFC quick share hiện được ẩn nếu native peer-to-peer chưa sẵn sàng trên build hiện tại. Điều này là chủ đích để tránh nút giả và tránh crash.

## 11. Deploy Firestore Indexes

```bash
firebase login
firebase use thoikhoabieuapp-9f53e
firebase deploy --only firestore:indexes
```

Sau khi deploy, Firebase có thể cần vài phút để build index.

## 12. Debug Firebase Errors

UI không hiển thị link Firebase dài. Các lỗi được map:

- `failed-precondition` / `requires an index`: Firebase đang tạo chỉ mục
- `permission-denied`: kiểm tra Firestore Rules
- `network-request-failed` / `unavailable`: kiểm tra kết nối mạng
- `internal-error`: thử lại sau

Chi tiết lỗi được log bằng `debugPrint`.
