import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../services/auth_service.dart';

class AdminShell extends StatefulWidget {
  final String title;
  final String currentRoute;
  final Widget child;

  const AdminShell({
    super.key,
    required this.title,
    required this.currentRoute,
    required this.child,
  });

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final _authService = AuthService();
  late final Future<bool> _adminCheck;

  @override
  void initState() {
    super.initState();
    _adminCheck = _authService.isCurrentUserAdmin();
  }

  Future<void> _logout() async {
    try {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => route.isFirst,
      );
    } catch (error) {
      if (!mounted) return;
      debugPrint('Admin logout: ${_authService.messageFor(error)}');
    }
  }

  void _navigate(String route) {
    if (route == widget.currentRoute) return;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _adminCheck,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Color(0xFF0A0A0A),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFE50914)),
            ),
          );
        }
        if (snapshot.data != true) return _accessDenied();

        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 900) return _mobileLayout();
            return _desktopLayout();
          },
        );
      },
    );
  }

  Widget _desktopLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      body: Row(
        children: [
          SizedBox(width: 260, child: _sidebar()),
          Expanded(
            child: Column(
              children: [
                _topBar(),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: const Color(0xFF171717),
        title: Text(widget.title),
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF171717),
        child: _sidebar(),
      ),
      body: widget.child,
    );
  }

  Widget _topBar() {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Color(0xFF171717),
        border: Border(bottom: BorderSide(color: Color(0xFF2B2B2B))),
      ),
      child: Row(
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          const Icon(
            Icons.admin_panel_settings_outlined,
            color: Colors.white54,
          ),
          const SizedBox(width: 8),
          const Text('Administrator', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _sidebar() {
    return SafeArea(
      child: Container(
        color: const Color(0xFF171717),
        padding: const EdgeInsets.fromLTRB(14, 20, 14, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.local_movies, color: Color(0xFFE50914), size: 27),
                  SizedBox(width: 10),
                  Text(
                    'META ADMIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _navItem(
              route: AppRoutes.adminDashboard,
              icon: Icons.dashboard_outlined,
              label: 'Bảng điều khiển',
            ),
            const SizedBox(height: 6),
            _navItem(
              route: AppRoutes.adminUsers,
              icon: Icons.people_outline,
              label: 'Quản lý người dùng',
            ),
            const Spacer(),
            const Divider(color: Color(0xFF343434)),
            TextButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Align(
                alignment: Alignment.centerLeft,
                child: Text('Đăng xuất'),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem({
    required String route,
    required IconData icon,
    required String label,
  }) {
    final selected = widget.currentRoute == route;
    return Material(
      color: selected ? const Color(0xFFE50914) : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: selected ? Colors.white : Colors.white60),
        title: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        onTap: () => _navigate(route),
      ),
    );
  }

  Widget _accessDenied() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, color: Color(0xFFE50914), size: 52),
            const SizedBox(height: 16),
            const Text(
              'Bạn không có quyền truy cập trang quản trị.',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 18),
            FilledButton(onPressed: _logout, child: const Text('Về đăng nhập')),
          ],
        ),
      ),
    );
  }
}
