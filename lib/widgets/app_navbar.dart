import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_routes.dart';
import '../services/auth_service.dart';
import 'user_avatar.dart';

class AppNavbar extends StatelessWidget {
  final VoidCallback? onHome;
  final VoidCallback? onBack;
  final VoidCallback? onNowShowing;
  final VoidCallback? onComingSoon;
  final VoidCallback? onLogin;
  final VoidCallback? onRegister;
  final VoidCallback? onLoggedOut;

  const AppNavbar({
    super.key,
    this.onHome,
    this.onBack,
    this.onNowShowing,
    this.onComingSoon,
    this.onLogin,
    this.onRegister,
    this.onLoggedOut,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 1050;
            return Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.95),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE50914).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1320),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 24,
                    ),
                    child: isMobile
                        ? _buildMobileNavbar(context, user)
                        : _buildDesktopNavbar(context, user),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDesktopNavbar(BuildContext context, User? user) {
    return Row(
      children: [
        _brand(),
        const SizedBox(width: 42),
        _NavItem(title: 'Trang chủ', onTap: onHome),
        _NavItem(title: 'Phim đang chiếu', onTap: onNowShowing),
        _NavItem(title: 'Phim sắp chiếu', onTap: onComingSoon),
        const Spacer(),
        if (user == null) ...[
          TextButton(
            onPressed: onLogin,
            child: const Text(
              'Đăng nhập',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onRegister != null) ...[
            const SizedBox(width: 8),
            _registerButton(),
          ],
        ] else ...[
          _accountMenu(context, user),
          const SizedBox(width: 14),
          OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Đăng xuất'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMobileNavbar(BuildContext context, User? user) {
    return Row(
      children: [
        if (onBack != null) ...[
          IconButton(
            tooltip: 'Quay lại',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 4),
        ],
        _brand(),
        const Spacer(),
        PopupMenuButton<String>(
          tooltip: 'Mở menu',
          color: const Color(0xFF1C1C1C),
          icon: const Icon(Icons.menu, color: Colors.white, size: 29),
          onSelected: (value) {
            switch (value) {
              case 'home':
                onHome?.call();
                break;
              case 'now':
                onNowShowing?.call();
                break;
              case 'soon':
                onComingSoon?.call();
                break;
              case 'login':
                onLogin?.call();
                break;
              case 'register':
                onRegister?.call();
                break;
              case 'bookings':
              case 'stats':
              case 'profile':
                _openAccountPage(context, value);
                break;
              case 'logout':
                _logout(context);
                break;
            }
          },
          itemBuilder: (_) => [
            _menuItem('home', Icons.home_outlined, 'Trang chủ'),
            _menuItem('now', Icons.movie_outlined, 'Phim đang chiếu'),
            _menuItem('soon', Icons.upcoming_outlined, 'Phim sắp chiếu'),
            const PopupMenuDivider(),
            if (user == null) ...[
              _menuItem('login', Icons.login_outlined, 'Đăng nhập'),
              if (onRegister != null)
                _menuItem('register', Icons.person_add_outlined, 'Đăng ký'),
            ] else ...[
              PopupMenuItem<String>(
                enabled: false,
                child: _mobileUserSummary(user),
              ),
              const PopupMenuDivider(),
              ..._accountMenuItems(),
              const PopupMenuDivider(),
              _menuItem('logout', Icons.logout, 'Đăng xuất'),
            ],
          ],
        ),
      ],
    );
  }

  Future<void> _logout(BuildContext context) async {
    final authService = AuthService();
    try {
      await authService.signOut();
      if (!context.mounted) return;
      if (onLoggedOut != null) {
        onLoggedOut!.call();
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => route.isFirst,
        );
      }
    } catch (error) {
      if (!context.mounted) return;
      debugPrint('Logout: ${authService.messageFor(error)}');
    }
  }

  Widget _accountMenu(BuildContext context, User user) {
    return PopupMenuButton<String>(
      tooltip: 'Tài khoản',
      color: const Color(0xFF1C1C1C),
      offset: const Offset(0, 46),
      onSelected: (value) => _openAccountPage(context, value),
      itemBuilder: (_) => _accountMenuItems(),
      child: _signedInUser(user),
    );
  }

  List<PopupMenuEntry<String>> _accountMenuItems() {
    return [
      _menuItem('bookings', Icons.confirmation_number_outlined, 'Vé của tôi'),
      _menuItem('stats', Icons.bar_chart_outlined, 'Thống kê cá nhân'),
      _menuItem('profile', Icons.person_outline, 'Thông tin cá nhân'),
    ];
  }

  void _openAccountPage(BuildContext context, String value) {
    final routeName = switch (value) {
      'bookings' => AppRoutes.bookingHistory,
      'stats' => AppRoutes.userStats,
      'profile' => AppRoutes.profile,
      _ => null,
    };
    if (routeName == null ||
        ModalRoute.of(context)?.settings.name == routeName) {
      return;
    }
    Navigator.pushNamed(context, routeName);
  }

  Widget _signedInUser(User user) {
    final name = _displayName(user);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        UserAvatar(userId: user.uid, name: name),
        const SizedBox(width: 9),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 190),
          child: Text(
            'Xin chào, $name',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 20),
      ],
    );
  }

  Widget _mobileUserSummary(User user) {
    final name = _displayName(user);
    return Row(
      children: [
        UserAvatar(userId: user.uid, name: name),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                user.email ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _displayName(User user) {
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;

    final email = user.email?.trim() ?? '';
    if (email.contains('@')) return email.split('@').first;
    return email.isEmpty ? 'Thành viên' : email;
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String title) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _brand() {
    return InkWell(
      onTap: onHome,
      child: ShaderMask(
        shaderCallback: (bounds) =>
            const LinearGradient(colors: [Color(0xFFE50914), Color(0xFFF40612)])
                .createShader(bounds),
        child: const Text(
          'META CINEMA',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _registerButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE50914), Color(0xFFF40612)],
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE50914).withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextButton(
        onPressed: onRegister,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Đăng ký',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final String title;
  final VoidCallback? onTap;

  const _NavItem({required this.title, this.onTap});

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Text(
            widget.title,
            style: TextStyle(
              color: hovering
                  ? const Color(0xFFE50914)
                  : Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
