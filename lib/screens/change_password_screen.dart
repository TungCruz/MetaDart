import 'package:flutter/material.dart';

import '../app_routes.dart';
import '../services/auth_service.dart';
import '../widgets/app_shell.dart';
import '../widgets/auth_widgets.dart';

class ChangePasswordScreen extends StatefulWidget {
  static const routeName = AppRoutes.changePassword;

  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _authService = AuthService();
  bool _saving = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _authService.changeInitialPassword(_passwordController.text);
      if (!mounted) return;
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _authService.messageFor(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AppShell(
        onHome: _signOut,
        onBack: _signOut,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 56, 16, 30),
          child: AuthCard(
            icon: Icons.password_outlined,
            title: 'Đổi mật khẩu lần đầu',
            subtitle: 'Tài khoản đang dùng mật khẩu mặc định 123456. Hãy đặt mật khẩu riêng để tiếp tục.',
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ...[
                    Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFFF6B72)),
                    ),
                    const SizedBox(height: 16),
                  ],
                  AuthField(
                    controller: _passwordController,
                    label: 'Mật khẩu mới',
                    hint: 'Tối thiểu 6 ký tự',
                    icon: Icons.lock_outline,
                    enabled: !_saving,
                    obscureText: _obscure,
                    onToggleObscure: () => setState(() => _obscure = !_obscure),
                    validator: (value) => (value?.length ?? 0) < 6
                        ? 'Mật khẩu phải có ít nhất 6 ký tự.'
                        : null,
                  ),
                  const SizedBox(height: 18),
                  AuthField(
                    controller: _confirmController,
                    label: 'Nhập lại mật khẩu',
                    hint: 'Nhập lại mật khẩu mới',
                    icon: Icons.lock_reset_outlined,
                    enabled: !_saving,
                    obscureText: _obscure,
                    validator: (value) => value != _passwordController.text
                        ? 'Mật khẩu nhập lại không khớp.'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  AuthPrimaryButton(
                    label: 'Đổi mật khẩu và tiếp tục',
                    icon: Icons.check_circle_outline,
                    onPressed: _save,
                    loading: _saving,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _saving ? null : _signOut,
                    child: const Text('Đăng xuất'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
