import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/account_screens.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_users_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MetaCinemaApp());
}

class MetaCinemaApp extends StatelessWidget {
  const MetaCinemaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Meta Cinema',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE50914),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      routes: {
        LoginScreen.routeName: (_) => const LoginScreen(),
        BookingHistoryScreen.routeName: (_) => const BookingHistoryScreen(),
        UserStatsScreen.routeName: (_) => const UserStatsScreen(),
        ProfileScreen.routeName: (_) => const ProfileScreen(),
        AdminDashboardScreen.routeName: (_) => const AdminDashboardScreen(),
        AdminUsersScreen.routeName: (_) => const AdminUsersScreen(),
        ChangePasswordScreen.routeName: (_) => const ChangePasswordScreen(),
      },
    );
  }
}
