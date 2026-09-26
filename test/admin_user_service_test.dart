import 'package:flutter_test/flutter_test.dart';
import 'package:metacinema/models/managed_user.dart';
import 'package:metacinema/services/admin_user_service.dart';

void main() {
  test('tài khoản admin tạo dùng mật khẩu mặc định 123456', () {
    expect(AdminUserService.defaultPassword, '123456');
  });

  test('trạng thái disabled được nhận diện là tài khoản bị khóa', () {
    const user = ManagedUser(
      id: 'uid',
      name: 'Nguyễn Văn A',
      email: 'a@example.com',
      phone: '0912345678',
      age: 20,
      status: 'disabled',
    );
    expect(user.isActive, isFalse);
  });
}
