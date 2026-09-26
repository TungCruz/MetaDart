import 'package:flutter/material.dart';

import '../widgets/app_footer.dart';
import '../widgets/app_navbar.dart';
import 'food_and_drink_screen.dart';

class CheckoutScreen extends StatelessWidget {
  final int showtimeId;
  final List<String> selectedSeats;
  final int ticketPrice;
  final List<FoodOrder> foodOrders;

  const CheckoutScreen({
    super.key,
    required this.showtimeId,
    required this.selectedSeats,
    required this.ticketPrice,
    required this.foodOrders,
  });

  int get seatTotal => selectedSeats.length * ticketPrice;

  int get foodTotal => foodOrders.fold(0, (sum, item) => sum + item.total);

  int get grandTotal => seatTotal + foodTotal;

  String _formatPrice(int price) {
    return '${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match.group(1)}.')}đ';
  }

  void _goHome(BuildContext context) {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _payment(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFF242424),
          title: const Text(
            'Thanh toán',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Chức năng thanh toán ngân hàng sẽ được kết nối API ở bước sau.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Đóng',
                style: TextStyle(color: Color(0xFFE50914)),
              ),
            ),
          ],
        );
      },
    );
  }

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
              AppNavbar(onHome: () => _goHome(context)),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [_buildContent(context), const AppFooter()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 55, 16, 55),
          child: Column(
            children: [
              const Text(
                'Thanh toán',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 35),

              LayoutBuilder(
                builder: (context, constraints) {
                  final desktop = constraints.maxWidth >= 700;

                  if (desktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildOrderSummary(context)),
                        const SizedBox(width: 30),
                        Expanded(child: _buildPayment()),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      _buildOrderSummary(context),
                      const SizedBox(height: 30),
                      _buildPayment(),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tóm tắt đơn hàng',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 14),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1C),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Suất chiếu:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                '19:00 15/09/2026 | Phòng: Phòng 1',
                style: TextStyle(color: Colors.white70),
              ),

              const SizedBox(height: 22),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ghế:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Đổi ghế',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),

              Text(
                selectedSeats.join(', '),
                style: const TextStyle(color: Colors.white70),
              ),

              const SizedBox(height: 18),

              const Text(
                'Tiền ghế:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                _formatPrice(seatTotal),
                style: const TextStyle(color: Colors.white70),
              ),

              const Divider(color: Colors.white24, height: 30),

              const Text(
                'Đồ ăn & thức uống',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              if (foodOrders.isEmpty)
                const Text(
                  'Không chọn đồ ăn/thức uống.',
                  style: TextStyle(color: Colors.white54),
                ),

              for (final item in foodOrders)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.item.name} size ${item.size} x ${item.quantity}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      Text(
                        _formatPrice(item.total),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),

              const Divider(color: Colors.white24, height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tổng cộng:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _formatPrice(grandTotal),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPayment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn phương thức thanh toán',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 14),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1C),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ElevatedButton(
            onPressed: () {
              // handled in parent below
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE50914),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              'Thanh toán qua Ngân hàng',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
