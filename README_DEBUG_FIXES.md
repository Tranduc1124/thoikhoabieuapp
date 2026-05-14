# Debug Fixes Checklist

## 1. Test Dark Mode

1. Vao `Cai dat` trong app.
2. Chon theme `Toi`.
3. Kiem tra cac man: Home, Hom nay, Tuan, Thong ke, Cai dat, Profile, Thong bao, Chia se.
4. Dam bao khong co card trang xoa, text mo, icon chim, bottom nav qua nhat.

## 2. Test Doi Mau Mon Hoc

1. Tao hoac sua mot mon hoc.
2. Chon mot palette trong muc `Mau sac`.
3. Bam luu.
4. Quay ve Home hoac Tuan va kiem tra card doi mau ngay.
5. Dong/mo lai app de dam bao mau van duoc doc tu Firestore field `color`.

Luu y: lich cu khong co field `color` se duoc gan palette fallback theo hash ten mon hoc, khong mat du lieu cu.

## 3. Test Notification 10 Giay

1. Vao `Cai dat` > `Thong bao`.
2. Bat `Bat thong bao toan app`.
3. Cap quyen notification khi iOS hoi.
4. Bam `Test 10 giay`.
5. Khoa man hinh hoac dua app ve background va doi thong bao.

## 4. Kiem Tra Pending Notifications

Trong man `Thong bao`, bam `Len lich lai`.

App se:

- Reschedule tat ca notification lich hoc.
- Log danh sach pending notifications bang `debugPrint`.
- Hien snackbar so luong pending notification.

## 5. Test Dynamic Island / Live Activities

Dieu kien:

- iOS 16.1+.
- iPhone ho tro Live Activities/Dynamic Island.
- Build tren real device de kiem tra chinh xac.

Cach test:

1. Dang nhap va co lich hoc trong hom nay.
2. Vao `Cai dat`.
3. Neu may ho tro, section `Dynamic Island` se hien.
4. Bat toggle.
5. Mo app gan gio hoc hoac trong gio hoc.
6. Kiem tra Live Activity hien mon sap hoc/dang hoc, gio hoc, phong, giao vien va mon tiep theo.

May khong ho tro se khong hien section Dynamic Island va app khong goi native API.

## 6. Deploy Firestore Indexes

```bash
firebase login
firebase use thoikhoabieuapp-9f53e
firebase deploy --only firestore:indexes
```

Sau khi deploy, Firebase co the can vai phut de build index.

## 7. Debug Firebase Errors

UI khong hien link Firebase dai. Cac loi duoc map:

- `failed-precondition` / requires index: Firebase dang tao chi muc.
- `permission-denied`: Kiem tra Firestore Rules.
- `network-request-failed` / unavailable: Kiem tra ket noi mang.
- `internal-error`: Thu lai sau.

Chi tiet loi duoc log bang `debugPrint`.
