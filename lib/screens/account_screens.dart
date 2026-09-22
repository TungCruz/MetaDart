import 'package:flutter/material.dart';

import '../app_routes.dart';
import '../widgets/app_shell.dart';

class BookingHistoryScreen extends StatelessWidget {
  static const routeName = AppRoutes.bookingHistory;

  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _AccountPage(
      title: 'Vé của tôi',
      onBack: () => Navigator.maybePop(context),
      child: const _EmptyState(
        icon: Icons.confirmation_number_outlined,
        title: 'Chưa có vé nào',
        message: 'Các vé đã đặt sẽ xuất hiện tại đây.',
      ),
    );
  }
}

class UserStatsScreen extends StatelessWidget {
  static const routeName = AppRoutes.userStats;

  const UserStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _AccountPage(
      title: 'Thống kê cá nhân',
      onBack: () => Navigator.maybePop(context),
      child: const Column(
        children: [
          Wrap(
            spacing: 14,
            runSpacing: 14,
            alignment: WrapAlignment.center,
            children: [
              _StatItem(
                icon: Icons.confirmation_number_outlined,
                value: '0',
                label: 'Vé đã mua',
              ),
              _StatItem(
                icon: Icons.payments_outlined,
                value: '0 đ',
                label: 'Tổng chi tiêu',
              ),
              _StatItem(
                icon: Icons.event_seat_outlined,
                value: '0',
                label: 'Ghế đã đặt',
              ),
            ],
          ),
          SizedBox(height: 36),
          _EmptyState(
            icon: Icons.bar_chart_outlined,
            title: 'Chưa có dữ liệu thống kê',
            message: 'Thống kê sẽ được cập nhật sau khi bạn hoàn tất đặt vé.',
          ),
        ],
      ),
    );
  }
}

class _AccountPage extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final Widget child;

  const _AccountPage({
    required this.title,
    required this.onBack,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AppShell(
      onHome: () => Navigator.popUntil(context, (route) => route.isFirst),
      onBack: onBack,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 44, 18, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        border: Border.all(color: const Color(0xFF333333)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFE50914), size: 28),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 16),
      child: Column(
        children: [
          Icon(icon, color: Colors.white30, size: 58),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
