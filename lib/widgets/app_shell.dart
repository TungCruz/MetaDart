import 'package:flutter/material.dart';

import 'app_footer.dart';
import 'app_navbar.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  final VoidCallback? onHome;
  final VoidCallback? onNowShowing;
  final VoidCallback? onComingSoon;

  const AppShell({
    super.key,
    required this.child,
    this.onHome,
    this.onNowShowing,
    this.onComingSoon,
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
            colors: [
              Color(0xFF0A0A0A),
              Color(0xFF1A1A2E),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AppNavbar(
                onHome: onHome,
                onNowShowing: onNowShowing,
                onComingSoon: onComingSoon,
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      child,
                      const AppFooter(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}