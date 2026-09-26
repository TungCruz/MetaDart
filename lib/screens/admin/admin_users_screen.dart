import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app_routes.dart';
import '../../models/managed_user.dart';
import '../../services/admin_user_service.dart';
import '../../services/auth_service.dart';
import '../../services/user_profile_service.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/user_avatar.dart';
import 'admin_shell.dart';

class AdminUsersScreen extends StatefulWidget {
  static const routeName = AppRoutes.adminUsers;

  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _service = AdminUserService();
  final _searchController = TextEditingController();
  final Set<String> _deletingIds = {};
  final Set<String> _statusBusyIds = {};
  late final Stream<List<ManagedUser>> _usersStream;
  String _search = '';
  String? _operationMessage;

  @override
  void initState() {
    super.initState();
    _usersStream = _service.watchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openEditor([ManagedUser? user]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _UserEditorDialog(service: _service, user: user),
    );
    if (!mounted || saved != true) return;
    _showMessage(
      user == null ? 'Thêm người dùng thành công.' : 'Cập nhật thành công.',
    );
  }

  Future<void> _toggleUserStatus(ManagedUser user) async {
    final nextStatus = user.isActive ? 'disabled' : 'active';
    setState(() => _statusBusyIds.add(user.id));
    try {
      await _service.setUserStatus(user, nextStatus);
      if (!mounted) return;
      _showMessage(
        nextStatus == 'active' ? 'Đã mở khóa tài khoản.' : 'Đã khóa tài khoản.',
      );
    } catch (error) {
      if (mounted) _showMessage(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _statusBusyIds.remove(user.id));
    }
  }

  Future<void> _deleteUser(ManagedUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF202020),
        title: const Text('Xóa người dùng'),
        content: Text(
          'Bạn có chắc muốn xóa ${user.name}? Avatar cũng sẽ bị xóa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Xóa'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE50914),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletingIds.add(user.id));
    try {
      await _service.deleteUser(user);
      if (!mounted) return;
      _showMessage('Đã xóa người dùng và avatar.');
    } catch (error) {
      if (!mounted) return;
      _showMessage(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _deletingIds.remove(user.id));
    }
  }

  String _errorMessage(Object error) {
    if (error is AdminUserException) return error.message;
    return AuthService().messageFor(error);
  }

  void _showMessage(String message) {
    debugPrint('Admin users: $message');
    if (mounted) setState(() => _operationMessage = message);
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Quản lý người dùng',
      currentRoute: AdminUsersScreen.routeName,
      child: Column(
        children: [
          _toolbar(),
          if (_operationMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _operationMessage!,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
          Expanded(
            child: StreamBuilder<List<ManagedUser>>(
              stream: _usersStream,
              builder: (context, snapshot) => _content(snapshot),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final search = TextField(
            controller: _searchController,
            onChanged: (value) =>
                setState(() => _search = value.trim().toLowerCase()),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Tìm theo tên, email hoặc số điện thoại',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              suffixIcon: _search.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Xóa tìm kiếm',
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _search = '');
                      },
                      icon: const Icon(Icons.close, color: Colors.white54),
                    ),
              filled: true,
              fillColor: const Color(0xFF191919),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFF343434)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFF343434)),
              ),
            ),
          );
          final addButton = FilledButton.icon(
            onPressed: _openEditor,
            icon: const Icon(Icons.person_add_outlined),
            label: const Text('Thêm người dùng'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE50914),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
            ),
          );
          if (constraints.maxWidth < 650) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [search, const SizedBox(height: 12), addButton],
            );
          }
          return Row(
            children: [
              Expanded(child: search),
              const SizedBox(width: 14),
              addButton,
            ],
          );
        },
      ),
    );
  }

  Widget _content(AsyncSnapshot<List<ManagedUser>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE50914)),
      );
    }
    if (snapshot.hasError) {
      return const _UsersMessage(
        icon: Icons.cloud_off_outlined,
        title: 'Không tải được danh sách người dùng',
        message: 'Vui lòng kiểm tra kết nối mạng và thử lại.',
      );
    }

    final users = (snapshot.data ?? const <ManagedUser>[]).where((user) {
      if (_search.isEmpty) return true;
      return user.name.toLowerCase().contains(_search) ||
          user.email.toLowerCase().contains(_search) ||
          user.phone.contains(_search);
    }).toList();

    if (users.isEmpty) {
      return _UsersMessage(
        icon: _search.isEmpty ? Icons.people_outline : Icons.search_off,
        title: _search.isEmpty
            ? 'Chưa có người dùng'
            : 'Không tìm thấy kết quả',
        message: _search.isEmpty
            ? 'Nhấn Thêm người dùng để tạo tài khoản đầu tiên.'
            : 'Thử tìm kiếm bằng từ khóa khác.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 28),
      itemCount: users.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _userRow(users[index]),
    );
  }

  Widget _userRow(ManagedUser user) {
    final deleting = _deletingIds.contains(user.id);
    final changingStatus = _statusBusyIds.contains(user.id);
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: deleting || changingStatus ? null : () => _openEditor(user),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFF191919),
          border: Border.all(color: const Color(0xFF303030)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final identity = Row(
              children: [
                UserAvatar(userId: user.id, name: user.name, radius: 21),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user.isActive ? 'Đang hoạt động' : 'Đã khóa',
                        style: TextStyle(
                          color: user.isActive
                              ? const Color(0xFF66BB6A)
                              : const Color(0xFFFFB74D),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
            final actions = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (changingStatus)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  IconButton(
                    tooltip: user.isActive ? 'Khóa tài khoản' : 'Mở khóa',
                    onPressed: () => _toggleUserStatus(user),
                    icon: Icon(
                      user.isActive ? Icons.lock_outline : Icons.lock_open,
                      color: user.isActive
                          ? const Color(0xFFFFB74D)
                          : const Color(0xFF66BB6A),
                    ),
                  ),
                IconButton(
                  tooltip: 'Sửa',
                  onPressed: deleting || changingStatus
                      ? null
                      : () => _openEditor(user),
                  icon: const Icon(Icons.edit_outlined, color: Colors.white70),
                ),
                if (deleting)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFE50914),
                      ),
                    ),
                  )
                else
                  IconButton(
                    tooltip: 'Xóa',
                    onPressed: () => _deleteUser(user),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFFF6B72),
                    ),
                  ),
              ],
            );

            if (constraints.maxWidth < 640) {
              return Column(
                children: [
                  identity,
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${user.phone} • ${user.age} tuổi',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      actions,
                    ],
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(flex: 3, child: identity),
                Expanded(
                  child: Text(
                    user.phone,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    '${user.age} tuổi',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _UserEditorDialog extends StatefulWidget {
  final AdminUserService service;
  final ManagedUser? user;

  const _UserEditorDialog({required this.service, this.user});

  @override
  State<_UserEditorDialog> createState() => _UserEditorDialogState();
}

class _UserEditorDialogState extends State<_UserEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _ageController;
  Uint8List? _avatarBytes;
  String? _avatarContentType;
  bool _removeAvatar = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _ageController = TextEditingController(
      text: user == null ? '' : '${user.age}',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 78,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (bytes.length > UserProfileService.maxAvatarBytes) {
        throw const AdminUserException('Ảnh quá lớn. Vui lòng chọn ảnh khác.');
      }
      if (!mounted) return;
      setState(() {
        _avatarBytes = bytes;
        _avatarContentType = image.mimeType;
        _removeAvatar = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _messageFor(error));
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final user = widget.user;
      if (user == null) {
        await widget.service.addUser(
          name: _nameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          age: int.parse(_ageController.text),
          avatarBytes: _avatarBytes,
          avatarContentType: _avatarContentType,
        );
      } else {
        await widget.service.updateUser(
          user: user,
          name: _nameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          age: int.parse(_ageController.text),
          avatarBytes: _avatarBytes,
          avatarContentType: _avatarContentType,
          removeAvatar: _removeAvatar,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _messageFor(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _messageFor(Object error) {
    if (error is AdminUserException) return error.message;
    return AuthService().messageFor(error);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.user != null;
    return Dialog(
      backgroundColor: const Color(0xFF181818),
      insetPadding: const EdgeInsets.all(18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 760),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        editing ? 'Sửa người dùng' : 'Thêm người dùng',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Đóng',
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _avatarEditor(),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFFF6B72)),
                  ),
                ],
                const SizedBox(height: 20),
                if (!editing) ...[
                  const Text(
                    'Tài khoản đăng nhập sẽ được tạo với mật khẩu mặc định 123456 và người dùng phải đổi mật khẩu ở lần đăng nhập đầu.',
                    style: TextStyle(color: Colors.white60),
                  ),
                  const SizedBox(height: 16),
                ],
                AuthField(
                  controller: _nameController,
                  label: 'Họ và tên',
                  hint: 'Nguyễn Văn A',
                  icon: Icons.person_outline,
                  enabled: !_saving,
                  validator: (value) => value == null || value.trim().length < 2
                      ? 'Vui lòng nhập họ và tên.'
                      : null,
                ),
                const SizedBox(height: 16),
                AuthField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'name@example.com',
                  icon: Icons.mail_outline,
                  enabled: !_saving,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
                        ? null
                        : 'Email không hợp lệ.';
                  },
                ),
                const SizedBox(height: 16),
                AuthField(
                  controller: _phoneController,
                  label: 'Số điện thoại',
                  hint: '0912345678',
                  icon: Icons.phone_outlined,
                  enabled: !_saving,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    final phone = value?.replaceAll(RegExp(r'\s'), '') ?? '';
                    return RegExp(r'^0\d{9}$').hasMatch(phone)
                        ? null
                        : 'Số điện thoại gồm 10 chữ số.';
                  },
                ),
                const SizedBox(height: 16),
                AuthField(
                  controller: _ageController,
                  label: 'Tuổi',
                  hint: '18',
                  icon: Icons.cake_outlined,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final age = int.tryParse(value ?? '');
                    return age != null && age >= 1 && age <= 120
                        ? null
                        : 'Tuổi từ 1–120.';
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text('Lưu'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE50914),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatarEditor() {
    final user = widget.user;
    final name = _nameController.text.trim().isEmpty
        ? 'M'
        : _nameController.text;
    final avatar = _removeAvatar
        ? CircleAvatar(
            radius: 43,
            backgroundColor: const Color(0xFFE50914),
            child: Text(
              name.characters.first.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        : UserAvatar(
            userId: user?.id ?? '__new_user__',
            name: name,
            radius: 43,
            previewBytes: _avatarBytes,
          );
    return Wrap(
      spacing: 16,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        avatar,
        OutlinedButton.icon(
          onPressed: _saving ? null : _pickAvatar,
          icon: const Icon(Icons.image_outlined),
          label: const Text('Chọn ảnh'),
        ),
        if (user != null)
          TextButton.icon(
            onPressed: _saving
                ? null
                : () => setState(() {
                    _avatarBytes = null;
                    _avatarContentType = null;
                    _removeAvatar = true;
                  }),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Xóa avatar'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF6B72),
            ),
          ),
      ],
    );
  }
}

class _UsersMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _UsersMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white30, size: 52),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}
