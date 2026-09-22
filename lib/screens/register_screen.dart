import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/app_shell.dart';
import '../widgets/auth_widgets.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  static const routeName = '/register';

  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _acceptedTerms = false;
  bool _showTermsError = false;
  int _passwordStrength = 0;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _goHome() => Navigator.popUntil(context, (route) => route.isFirst);

  void _openLogin() {
    Navigator.pushReplacementNamed(context, LoginScreen.routeName);
  }

  void _updatePasswordStrength(String password) {
    var strength = 0;
    if (password.length >= 6) strength += 25;
    if (password.length >= 8) strength += 25;
    if (RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[A-Z]').hasMatch(password)) {
      strength += 25;
    }
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 25;
    setState(() => _passwordStrength = strength);
  }

  String get _strengthLabel {
    if (_passwordStrength <= 25) return 'Yếu';
    if (_passwordStrength <= 50) return 'Trung bình';
    if (_passwordStrength <= 75) return 'Khá';
    return 'Mạnh';
  }

  Color get _strengthColor {
    if (_passwordStrength <= 25) return const Color(0xFFE50914);
    if (_passwordStrength <= 50) return const Color(0xFFFFC107);
    if (_passwordStrength <= 75) return const Color(0xFF29B6F6);
    return const Color(0xFF43A047);
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState?.validate() ?? false;
    setState(() => _showTermsError = !_acceptedTerms);
    if (!formValid || !_acceptedTerms) return;

    setState(() => _submitting = true);
    try {
      await _authService.register(
        name: _nameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        age: int.parse(_ageController.text),
        password: _passwordController.text,
      );
      if (!mounted) return;
      showAuthMessage(context, 'Đăng ký tài khoản thành công.');
      _goHome();
    } catch (error) {
      if (!mounted) return;
      showAuthMessage(context, _authService.messageFor(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      onHome: _goHome,
      onBack: _goHome,
      onLogin: _openLogin,
      onRegister: () {},
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 56, 16, 10),
        child: Column(
          children: [
            AuthCard(
              maxWidth: 680,
              icon: Icons.person_add_alt_1,
              title: 'Tạo tài khoản mới',
              subtitle: 'Đăng ký để trải nghiệm đặt vé nhanh chóng',
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ResponsivePair(
                      first: AuthField(
                        controller: _nameController,
                        label: 'Họ và tên',
                        hint: 'Nguyễn Văn A',
                        icon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            value == null || value.trim().length < 2
                            ? 'Vui lòng nhập họ và tên.'
                            : null,
                      ),
                      second: AuthField(
                        controller: _phoneController,
                        label: 'Số điện thoại',
                        hint: '0912345678',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          final phone =
                              value?.replaceAll(RegExp(r'\s'), '') ?? '';
                          return RegExp(r'^0\d{9}$').hasMatch(phone)
                              ? null
                              : 'Số điện thoại gồm 10 chữ số.';
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    _ResponsivePair(
                      firstFlex: 3,
                      first: AuthField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'name@example.com',
                        icon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                  .hasMatch(email)
                              ? null
                              : 'Email không hợp lệ.';
                        },
                      ),
                      second: AuthField(
                        controller: _ageController,
                        label: 'Tuổi',
                        hint: '18',
                        icon: Icons.cake_outlined,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          final age = int.tryParse(value ?? '');
                          return age != null && age >= 1 && age <= 120
                              ? null
                              : 'Tuổi từ 1–120.';
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    AuthField(
                      controller: _passwordController,
                      label: 'Mật khẩu',
                      hint: 'Tối thiểu 6 ký tự',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      onChanged: _updatePasswordStrength,
                      onToggleObscure: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                      validator: (value) => value == null || value.length < 6
                          ? 'Mật khẩu phải có ít nhất 6 ký tự.'
                          : null,
                    ),
                    const SizedBox(height: 9),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        minHeight: 5,
                        value: _passwordStrength / 100,
                        backgroundColor: const Color(0xFF333333),
                        valueColor: AlwaysStoppedAnimation(_strengthColor),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _passwordController.text.isEmpty ? '' : _strengthLabel,
                      style: TextStyle(color: _strengthColor, fontSize: 12),
                    ),
                    const SizedBox(height: 14),
                    AuthField(
                      controller: _confirmPasswordController,
                      label: 'Xác nhận mật khẩu',
                      hint: 'Nhập lại mật khẩu',
                      icon: Icons.lock_reset_outlined,
                      obscureText: _obscureConfirmation,
                      textInputAction: TextInputAction.done,
                      onToggleObscure: () {
                        setState(
                          () => _obscureConfirmation = !_obscureConfirmation,
                        );
                      },
                      validator: (value) => value == _passwordController.text
                          ? null
                          : 'Mật khẩu xác nhận không khớp.',
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      value: _acceptedTerms,
                      onChanged: (value) {
                        setState(() {
                          _acceptedTerms = value ?? false;
                          _showTermsError = false;
                        });
                      },
                      activeColor: authRed,
                      checkColor: Colors.white,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text(
                        'Tôi đồng ý với Điều khoản sử dụng và Chính sách bảo mật',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                    if (_showTermsError)
                      const Padding(
                        padding: EdgeInsets.only(left: 12, bottom: 10),
                        child: Text(
                          'Bạn cần đồng ý với điều khoản để đăng ký.',
                          style: TextStyle(
                            color: Color(0xFFFF6B72),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    AuthPrimaryButton(
                      label: 'Đăng ký',
                      icon: Icons.person_add_alt_1,
                      onPressed: _submit,
                      loading: _submitting,
                    ),
                    const SizedBox(height: 24),
                    const AuthDivider(label: 'Hoặc đăng ký với'),
                    const SizedBox(height: 18),
                    _SocialButtons(
                      onGoogle: () => showAuthMessage(
                        context,
                        'Đăng ký Google sẽ được bật sau khi cấu hình Firebase.',
                      ),
                      onFacebook: () => showAuthMessage(
                        context,
                        'Đăng ký Facebook sẽ được bật sau khi cấu hình Firebase.',
                      ),
                    ),
                    const SizedBox(height: 22),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Đã có tài khoản?',
                          style: TextStyle(color: authMuted),
                        ),
                        TextButton(
                          onPressed: _openLogin,
                          child: const Text(
                            'Đăng nhập ngay',
                            style: TextStyle(
                              color: authRed,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Wrap(
              alignment: WrapAlignment.center,
              spacing: 34,
              runSpacing: 18,
              children: [
                _RegisterBenefit(
                  icon: Icons.bolt,
                  label: 'Đặt vé nhanh chóng',
                  color: Color(0xFFFFC107),
                ),
                _RegisterBenefit(
                  icon: Icons.card_giftcard,
                  label: 'Ưu đãi độc quyền',
                  color: authRed,
                ),
                _RegisterBenefit(
                  icon: Icons.star,
                  label: 'Tích điểm thưởng',
                  color: Color(0xFFFFC107),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResponsivePair extends StatelessWidget {
  final Widget first;
  final Widget second;
  final int firstFlex;

  const _ResponsivePair({
    required this.first,
    required this.second,
    this.firstFlex = 1,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [first, const SizedBox(height: 18), second],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: firstFlex, child: first),
            const SizedBox(width: 16),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

class _SocialButtons extends StatelessWidget {
  final VoidCallback onGoogle;
  final VoidCallback onFacebook;

  const _SocialButtons({required this.onGoogle, required this.onFacebook});

  @override
  Widget build(BuildContext context) {
    final google = AuthSocialButton(
      label: 'Google',
      icon: Icons.g_mobiledata,
      onPressed: onGoogle,
    );
    final facebook = AuthSocialButton(
      label: 'Facebook',
      icon: Icons.facebook,
      onPressed: onFacebook,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 400) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [google, const SizedBox(height: 12), facebook],
          );
        }
        return Row(
          children: [
            Expanded(child: google),
            const SizedBox(width: 12),
            Expanded(child: facebook),
          ],
        );
      },
    );
  }
}

class _RegisterBenefit extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _RegisterBenefit({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: authMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
