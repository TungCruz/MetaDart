import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../models/managed_user.dart';
import '../../services/admin_user_service.dart';
import 'admin_shell.dart';

class AdminDashboardScreen extends StatelessWidget {
  static const routeName = AppRoutes.adminDashboard;

  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Bảng điều khiển',
      currentRoute: routeName,
      child: StreamBuilder<List<ManagedUser>>(
        stream: AdminUserService().watchUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE50914)),
            );
          }
          if (snapshot.hasError) {
            return const _DashboardMessage(
              icon: Icons.cloud_off_outlined,
              message: 'Không tải được dữ liệu quản trị.',
            );
          }

          final users = snapshot.data ?? const <ManagedUser>[];
          final withPhone = users.where((user) => user.phone.isNotEmpty).length;
          final withAge = users.where((user) => user.age > 0).length;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _SummaryTile(
                      icon: Icons.people_outline,
                      label: 'Tổng người dùng',
                      value: '${users.length}',
                    ),
                    _SummaryTile(
                      icon: Icons.phone_outlined,
                      label: 'Có số điện thoại',
                      value: '$withPhone',
                    ),
                    _SummaryTile(
                      icon: Icons.cake_outlined,
                      label: 'Có thông tin tuổi',
                      value: '$withAge',
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                FilledButton.icon(
                  onPressed: () => Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.adminUsers,
                  ),
                  icon: const Icon(Icons.manage_accounts_outlined),
                  label: const Text('Quản lý người dùng'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE50914),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF191919),
        border: Border.all(color: const Color(0xFF303030)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFE50914), size: 30),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(label, style: const TextStyle(color: Colors.white54)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardMessage extends StatelessWidget {
  final IconData icon;
  final String message;

  const _DashboardMessage({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white38, size: 48),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
