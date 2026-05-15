# Backend PHP/MySQL Setup

1. Upload toàn bộ nội dung thư mục `backend_php/` lên host `http://minhduc.huutien.store/`.
2. Tạo MySQL database và user có quyền `CREATE`, `ALTER`, `INDEX`, `INSERT`, `UPDATE`, `DELETE`, `SELECT`.
3. Mở `config.php` và điền đúng:
   - `DB_HOST`
   - `DB_NAME`
   - `DB_USER`
   - `DB_PASS`
   - `APP_KEY`
   - `JWT_SECRET`
   - `INSTALL_KEY`
   - `APP_BASE_URL`
4. Chạy:
   - `http://minhduc.huutien.store/install.php?key=YOUR_INSTALL_KEY`
5. Test API:

```json
POST /api.php
Headers:
  Content-Type: application/json
  X-App-Key: thoikhoabieuapp_public_key

Body:
{
  "action": "system.ping",
  "data": {}
}
```

6. Khi `system.ping` trả `success=true`, build app Flutter.

## Ghi chú

- Tất cả chức năng app đều đi qua `api.php`.
- Auth header:
  - `Authorization: Bearer TOKEN`
  - `X-App-Key: thoikhoabieuapp_public_key`
- Upload avatar dùng multipart field `avatar`.
- `install.php` idempotent, chạy lại không xoá dữ liệu cũ.
