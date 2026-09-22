import 'package:flutter/material.dart';

import 'app_footer.dart';
import 'app_navbar.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  final VoidCallback? onHome;
  final VoidCallback? onBack;
  final VoidCallback? onNowShowing;
  final VoidCallback? onComingSoon;
  final VoidCallback? onLogin;
  final VoidCallback? onRegister;
  final VoidCallback? onLoggedOut;

  const AppShell({
    super.key,
    required this.child,
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
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0A0A), Color(0xFF1A1A2E)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AppNavbar(
                onHome: onHome,
                onBack: onBack,
                onNowShowing: onNowShowing,
                onComingSoon: onComingSoon,
                onLogin: onLogin,
                onRegister: onRegister,
                onLoggedOut: onLoggedOut,
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(children: [child, const AppFooter()]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
