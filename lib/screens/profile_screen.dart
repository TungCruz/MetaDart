import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app_routes.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../widgets/app_shell.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/user_avatar.dart';

class ProfileScreen extends StatefulWidget {
  static const routeName = AppRoutes.profile;

  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _profileService = UserProfileService();
  final _imagePicker = ImagePicker();

  UserProfile? _profile;
  Uint8List? _pendingAvatarBytes;
  String? _pendingAvatarContentType;
  bool _loading = true;
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileService.loadProfile();
      if (!mounted) return;
      _setControllers(profile);
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage(_messageFor(error));
    }
  }

  Future<void> _pickAvatar() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 78,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      if (bytes.length > UserProfileService.maxAvatarBytes) {
        throw const ProfileValidationException(
          'Ảnh quá lớn. Vui lòng chọn ảnh JPG hoặc PNG nhỏ hơn.',
        );
      }
      if (!mounted) return;
      setState(() {
        _pendingAvatarBytes = bytes;
        _pendingAvatarContentType = image.mimeType;
        _editing = true;
      });
      _showMessage('Đã chọn ảnh. Nhấn Lưu thay đổi để cập nhật.');
    } catch (error) {
      if (!mounted) return;
      _showMessage(_messageFor(error));
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      await _profileService.updateProfile(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        age: int.parse(_ageController.text),
        avatarBytes: _pendingAvatarBytes,
        avatarContentType: _pendingAvatarContentType,
      );
      if (!mounted) return;
      final updated = UserProfile(
        id: _profile!.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        age: int.parse(_ageController.text),
      );
      setState(() {
        _profile = updated;
        _pendingAvatarBytes = null;
        _pendingAvatarContentType = null;
        _editing = false;
      });
      _showMessage('Cập nhật thông tin thành công.');
    } catch (error) {
      if (!mounted) return;
      _showMessage(_messageFor(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _cancelEditing() {
    final profile = _profile;
    if (profile == null) return;
    _setControllers(profile);
    setState(() {
      _pendingAvatarBytes = null;
      _pendingAvatarContentType = null;
      _editing = false;
    });
  }

  void _setControllers(UserProfile profile) {
    _nameController.text = profile.name;
    _emailController.text = profile.email;
    _phoneController.text = profile.phone;
    _ageController.text = profile.age?.toString() ?? '';
  }

  String _messageFor(Object error) {
    if (error is ProfileValidationException) return error.message;
    return AuthService().messageFor(error);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _goHome() => Navigator.popUntil(context, (route) => route.isFirst);

  @override
  Widget build(BuildContext context) {
    return AppShell(
      onHome: _goHome,
      onBack: () => Navigator.maybePop(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 44, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Thông tin cá nhân',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151515),
                    border: Border.all(color: const Color(0xFF333333)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _buildBody(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const SizedBox(
        height: 320,
        child: Center(child: CircularProgressIndicator(color: authRed)),
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    if (_profile == null || user == null) {
      return const SizedBox(
        height: 240,
        child: Center(
          child: Text(
            'Không tải được thông tin tài khoản.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final avatar = _avatarPicker(user);
              final identity = _identityHeader();
              if (constraints.maxWidth < 560) {
                return Column(
                  children: [avatar, const SizedBox(height: 20), identity],
                );
              }
              return Row(
                children: [
                  avatar,
                  const SizedBox(width: 28),
                  Expanded(child: identity),
                ],
              );
            },
          ),
          const SizedBox(height: 30),
          AuthField(
            controller: _nameController,
            label: 'Họ và tên',
            hint: 'Nhập họ và tên',
            icon: Icons.person_outline,
            enabled: _editing && !_saving,
            validator: (value) => value == null || value.trim().length < 2
                ? 'Vui lòng nhập họ và tên.'
                : null,
          ),
          const SizedBox(height: 18),
          AuthField(
            controller: _emailController,
            label: 'Email',
            hint: 'Email',
            icon: Icons.mail_outline,
            enabled: false,
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final phone = AuthField(
                controller: _phoneController,
                label: 'Số điện thoại',
                hint: '0912345678',
                icon: Icons.phone_outlined,
                enabled: _editing && !_saving,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  final normalized = value?.replaceAll(RegExp(r'\s'), '') ?? '';
                  return RegExp(r'^0\d{9}$').hasMatch(normalized)
                      ? null
                      : 'Số điện thoại gồm 10 chữ số.';
                },
              );
              final age = AuthField(
                controller: _ageController,
                label: 'Tuổi',
                hint: '18',
                icon: Icons.cake_outlined,
                enabled: _editing && !_saving,
                keyboardType: TextInputType.number,
                validator: (value) {
                  final age = int.tryParse(value ?? '');
                  return age != null && age >= 1 && age <= 120
                      ? null
                      : 'Tuổi từ 1–120.';
                },
              );
              if (constraints.maxWidth < 560) {
                return Column(
                  children: [phone, const SizedBox(height: 18), age],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: phone),
                  const SizedBox(width: 16),
                  Expanded(child: age),
                ],
              );
            },
          ),
          const SizedBox(height: 26),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: _saving
                    ? null
                    : (_editing
                          ? _cancelEditing
                          : () => setState(() => _editing = true)),
                icon: Icon(_editing ? Icons.close : Icons.edit_outlined),
                label: Text(_editing ? 'Hủy' : 'Sửa'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: !_editing || _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Lưu thay đổi'),
                style: FilledButton.styleFrom(
                  backgroundColor: authRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatarPicker(User user) {
    return Semantics(
      button: true,
      label: 'Đổi ảnh đại diện',
      child: InkWell(
        onTap: _saving ? null : _pickAvatar,
        borderRadius: BorderRadius.circular(64),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: authRed, width: 2),
              ),
              child: UserAvatar(
                userId: user.uid,
                name: _nameController.text,
                radius: 52,
                previewBytes: _pendingAvatarBytes,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 2,
              child: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: authRed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _identityHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _nameController.text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(_emailController.text, style: const TextStyle(color: authMuted)),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _saving ? null : _pickAvatar,
          icon: const Icon(Icons.image_outlined, size: 19),
          label: const Text('Đổi ảnh đại diện'),
          style: TextButton.styleFrom(foregroundColor: authRed),
        ),
      ],
    );
  }
}
