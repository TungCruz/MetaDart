# Firebase Admin API cho MetaCinema

API này đồng bộ thao tác quản trị giữa Firebase Authentication và Cloud Firestore.

## Chuẩn bị một lần

1. Firebase Console → Project settings → Service accounts → Generate new private key.
2. Khóa của máy này được lưu ngoài Git tại `C:\Users\PC\.firebase-secrets\metacinema-admin.json`.
3. Mở PowerShell và đặt biến môi trường cho cửa sổ hiện tại:

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS = 'C:\Users\PC\.firebase-secrets\metacinema-admin.json'
```

Không chép khóa này vào Flutter, APK hoặc commit lên Git.

## Chạy API

```powershell
dotnet run --project backend\MetaCinema.AdminApi --urls http://0.0.0.0:5055
```

Hoặc chạy nhanh từ thư mục dự án:

```powershell
.\run_admin_api.ps1
```

Sau đó chạy Flutter trên Android emulator. App tự dùng `http://10.0.2.2:5055`.

Admin tạo user sẽ tạo đồng thời:

- tài khoản Firebase Authentication;
- hồ sơ `users/{uid}` trong Firestore;
- mật khẩu mặc định `123456`;
- cờ `mustChangePassword: true` để buộc đổi mật khẩu ở lần đăng nhập đầu.

Khóa user sẽ đặt `disabled=true` trong Authentication, thu hồi refresh token và cập nhật `status=disabled` trong Firestore. Xóa user sẽ xóa cả Authentication, hồ sơ và avatar.

Khi đưa lên môi trường thật, chạy API qua HTTPS và bỏ cấu hình clear-text HTTP dành cho phát triển Android.
