import 'package:flutter/material.dart';

import '../app_routes.dart';
import '../services/auth_service.dart';
import '../widgets/app_shell.dart';
import '../widgets/auth_widgets.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _obscurePassword = true;
  bool _submitting = false;
  bool _resettingPassword = false;

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _goHome() => Navigator.popUntil(context, (route) => route.isFirst);

  void _openRegister() {
    Navigator.pushReplacementNamed(context, RegisterScreen.routeName);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    try {
      await _authService.signIn(
        email: _accountController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      final isAdmin = await _authService.isCurrentUserAdmin(forceRefresh: true);
      if (!mounted) return;
      showAuthMessage(context, 'Đăng nhập thành công.');
      if (isAdmin) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.adminDashboard,
          (route) => route.isFirst,
        );
      } else {
        _goHome();
      }
    } catch (error) {
      if (!mounted) return;
      showAuthMessage(context, _authService.messageFor(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _accountController.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      showAuthMessage(context, 'Vui lòng nhập email hợp lệ trước.');
      return;
    }

    setState(() => _resettingPassword = true);
    try {
      await _authService.sendPasswordResetEmail(email);
      if (!mounted) return;
      showAuthMessage(context, 'Đã gửi email đặt lại mật khẩu.');
    } catch (error) {
      if (!mounted) return;
      showAuthMessage(context, _authService.messageFor(error));
    } finally {
      if (mounted) setState(() => _resettingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      onHome: _goHome,
      onBack: _goHome,
      onLogin: () {},
      onRegister: _openRegister,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 56, 16, 10),
        child: Column(
          children: [
            AuthCard(
              icon: Icons.local_movies_outlined,
              title: 'Chào mừng trở lại!',
              subtitle: 'Đăng nhập để tiếp tục đặt vé',
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthField(
                      controller: _accountController,
                      label: 'Email hoặc tài khoản',
                      hint: 'Nhập email hoặc tài khoản',
                      icon: Icons.mail_outline,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.toLowerCase() == AuthService.adminUsername) {
                          return null;
                        }
                        return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                .hasMatch(email)
                            ? null
                            : 'Email không hợp lệ.';
                      },
                    ),
                    const SizedBox(height: 20),
                    AuthField(
                      controller: _passwordController,
                      label: 'Mật khẩu',
                      hint: 'Nhập mật khẩu',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onToggleObscure: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                      validator: (value) => value == null || value.isEmpty
                          ? 'Vui lòng nhập mật khẩu.'
                          : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _submitting || _resettingPassword
                            ? null
                            : _resetPassword,
                        child: const Text(
                          'Quên mật khẩu?',
                          style: TextStyle(color: authRed),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AuthPrimaryButton(
                      label: 'Đăng nhập',
                      icon: Icons.login,
                      onPressed: _submit,
                      loading: _submitting,
                    ),
                    const SizedBox(height: 24),
                    const AuthDivider(label: 'Hoặc đăng nhập với'),
                    const SizedBox(height: 18),
                    AuthSocialButton(
                      label: 'Google',
                      icon: Icons.g_mobiledata,
                      onPressed: () => showAuthMessage(
                        context,
                        'Đăng nhập Google sẽ được bật sau khi cấu hình Firebase.',
                      ),
                    ),
                    const SizedBox(height: 22),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Chưa có tài khoản?',
                          style: TextStyle(color: authMuted),
                        ),
                        TextButton(
                          onPressed: _openRegister,
                          child: const Text(
                            'Đăng ký ngay',
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
            const SizedBox(height: 24),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user_outlined, color: authMuted, size: 18),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Thông tin của bạn được bảo mật an toàn',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: authMuted, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
