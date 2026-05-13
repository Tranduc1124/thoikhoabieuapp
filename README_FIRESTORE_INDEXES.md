# Firestore Indexes

File `firestore.indexes.json` khai bao composite indexes cho cac query dang dung trong app:

- `users/{uid}/schedules`: sap xep lich theo `dayOfWeek` va `startTime`.
- `users/{uid}/studyLogs`: loc theo `status` va khoang ngay `date` khi can thong ke nang cao.
- `public_shares`: loc link chia se theo `ownerId` va sap xep `createdAt`.
- `tasks` va `exams`: index du phong cho tinh nang homework/deadline va lich thi.

## Deploy indexes

Can dang nhap Firebase CLI va dung dung project Firebase:

```bash
firebase login
firebase use thoikhoabieuapp-9f53e
firebase deploy --only firestore:indexes
```

Sau khi deploy, Firebase co the can vai phut de build index. Trong thoi gian do app van co the bao thieu index cho query moi.

## Khi gap failed-precondition

Loi:

```text
[cloud_firestore/failed-precondition] The query requires an index.
```

Cach debug:

1. Xem query co dung `where` + `orderBy`, nhieu `where`, hoac `collectionGroup` khong.
2. Neu Firebase log tra ve link tao index, mo link do de xem field/order can them.
3. Them index moi vao `firestore.indexes.json`.
4. Deploy lai:

```bash
firebase deploy --only firestore:indexes
```

## Quy uoc query hien tai

Lich hoc dang nam trong subcollection theo user:

```text
users/{userId}/schedules/{scheduleId}
```

Vi query da nam trong path cua user, app khong can `where('userId')` cho lich hoc hien tai. Neu sau nay chuyen sang `collectionGroup('schedules')` hoac top-level `schedules`, hay them field `userId` vao document va tao index tuong ung.

## Toi uu index

- Khong them `orderBy` neu UI co the sort sau khi load tap du lieu nho cua mot user.
- Uu tien query theo path `users/{uid}/...` de giam nhu cau index theo `userId`.
- Moi khi them query co `where` ket hop `orderBy`, cap nhat file index trong repo thay vi tao thu cong tren console roi quen commit.
