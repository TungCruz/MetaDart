import 'package:flutter/material.dart';

class AppNavbar extends StatelessWidget {
  final VoidCallback? onHome;
  final VoidCallback? onNowShowing;
  final VoidCallback? onComingSoon;

  const AppNavbar({
    super.key,
    this.onHome,
    this.onNowShowing,
    this.onComingSoon,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 750;

        return Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.95),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE50914).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1320,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 24,
                ),
                child: isMobile
                    ? _buildMobileNavbar(context)
                    : _buildDesktopNavbar(context),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopNavbar(BuildContext context) {
    return Row(
      children: [
        _brand(),
        const SizedBox(width: 42),
        _NavItem(
          title: 'Trang chủ',
          onTap: onHome,
        ),
        _NavItem(
          title: 'Phim đang chiếu',
          onTap: onNowShowing,
        ),
        _NavItem(
          title: 'Phim sắp chiếu',
          onTap: onComingSoon,
        ),
        const Spacer(),
        TextButton(
          onPressed: () {},
          child: const Text(
            'Đăng nhập',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _registerButton(),
      ],
    );
  }

  Widget _buildMobileNavbar(BuildContext context) {
    return Row(
      children: [
        _brand(),
        const Spacer(),
        PopupMenuButton<String>(
          color: const Color(0xFF1C1C1C),
          icon: const Icon(
            Icons.menu,
            color: Colors.white,
            size: 29,
          ),
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
            }
          },
          itemBuilder: (context) {
            return [
              _menuItem(
                'home',
                Icons.home_outlined,
                'Trang chủ',
              ),
              _menuItem(
                'now',
                Icons.movie_outlined,
                'Phim đang chiếu',
              ),
              _menuItem(
                'soon',
                Icons.upcoming_outlined,
                'Phim sắp chiếu',
              ),
              const PopupMenuDivider(),
              _menuItem(
                'login',
                Icons.login_outlined,
                'Đăng nhập',
              ),
              _menuItem(
                'register',
                Icons.person_add_outlined,
                'Đăng ký',
              ),
            ];
          },
        ),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    String title,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white70,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _brand() {
    return InkWell(
      onTap: onHome,
      child: ShaderMask(
        shaderCallback: (bounds) {
          return const LinearGradient(
            colors: [
              Color(0xFFE50914),
              Color(0xFFF40612),
            ],
          ).createShader(bounds);
        },
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
          colors: [
            Color(0xFFE50914),
            Color(0xFFF40612),
          ],
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE50914).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextButton(
        onPressed: () {},
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Đăng ký',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final String title;
  final VoidCallback? onTap;

  const _NavItem({
    required this.title,
    this.onTap,
  });

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
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 10,
          ),
          child: Text(
            widget.title,
            style: TextStyle(
              color: hovering
                  ? const Color(0xFFE50914)
                  : Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}