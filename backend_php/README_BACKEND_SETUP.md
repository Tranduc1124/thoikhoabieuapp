# Backend PHP/MySQL Setup

1. Upload toàn bộ thư mục `backend_php/` lên host `https://minhduc.huutien.store/`.
2. Đảm bảo Apache bật `mod_rewrite` để route `/share/{id}` hoạt động.
3. Tạo MySQL database và user có quyền `CREATE`, `ALTER`, `INDEX`, `INSERT`, `UPDATE`, `DELETE`, `SELECT`.
4. Mở `config.php` và điền đúng:
   - `DB_HOST`
   - `DB_NAME`
   - `DB_USER`
   - `DB_PASS`
   - `APP_KEY`
   - `JWT_SECRET`
   - `INSTALL_KEY`
   - `APP_BASE_URL`
   - `APP_DOWNLOAD_URL`
5. Chạy:
   - `https://minhduc.huutien.store/install.php?key=YOUR_INSTALL_KEY`
6. Test API:

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

7. Test public share:
   - `https://minhduc.huutien.store/share/{shareId}`
   - Link cũ `/shared/{shareId}` và `api.php?action=share.get&shareId=...` sẽ tự chuyển về route mới.

## Ghi chú

- Tất cả chức năng app vẫn đi qua `api.php`.
- Public share page dùng `share.php` và route rewrite trong `.htaccess`.
- Auth header:
  - `Authorization: Bearer TOKEN`
  - `X-App-Key: thoikhoabieuapp_public_key`
- Upload avatar dùng multipart field `avatar`.
- `install.php` idempotent, chạy lại không xóa dữ liệu cũ.
