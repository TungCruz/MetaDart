import 'package:flutter/material.dart';

import '../widgets/app_footer.dart';
import '../widgets/app_navbar.dart';
import 'checkout_screen.dart';

class FoodItem {
  final int id;
  final String name;
  final String description;
  final String image;
  final Map<String, int> sizes;

  const FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.sizes,
  });
}

class FoodOrder {
  final FoodItem item;
  String size;
  int quantity;

  FoodOrder({required this.item, required this.size, this.quantity = 0});

  int get unitPrice => item.sizes[size] ?? 0;

  int get total => unitPrice * quantity;
}

class FoodAndDrinkScreen extends StatefulWidget {
  final int showtimeId;
  final List<String> selectedSeats;
  final int ticketPrice;

  const FoodAndDrinkScreen({
    super.key,
    required this.showtimeId,
    required this.selectedSeats,
    required this.ticketPrice,
  });

  @override
  State<FoodAndDrinkScreen> createState() => _FoodAndDrinkScreenState();
}

class _FoodAndDrinkScreenState extends State<FoodAndDrinkScreen> {
  final List<FoodOrder> orders = [];

  // ============================================================
  // DANH SÁCH ĐỒ ĂN / THỨC UỐNG
  // ============================================================

  final List<FoodItem> foods = const [
    FoodItem(
      id: 1,
      name: 'Combo Bỏng nước',
      description: 'Combo siu ngon',
      image: 'assets/images/food_combo.png',
      sizes: {'S': 15000, 'M': 20000, 'L': 25000},
    ),
    FoodItem(
      id: 2,
      name: 'Coca cola',
      description: 'Coca siêu mát',
      image: 'assets/images/food_coca.png',
      sizes: {'S': 10000, 'M': 15000, 'L': 20000},
    ),
    FoodItem(
      id: 3,
      name: 'Bỏng ngô',
      description: 'Bỏng ngô',
      image: 'assets/images/food_popcorn.png',
      sizes: {'S': 10000, 'M': 15000, 'L': 20000},
    ),
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    for (final food in foods) {
      orders.add(FoodOrder(item: food, size: food.sizes.keys.first));
    }
  }

  // ============================================================
  // TÍNH TIỀN
  // ============================================================

  int get seatTotal => widget.selectedSeats.length * widget.ticketPrice;

  int get foodTotal => orders.fold(0, (sum, item) => sum + item.total);

  int get grandTotal => seatTotal + foodTotal;

  String _formatPrice(int price) {
    return '${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match.group(1)}.')}đ';
  }

  // ============================================================
  // NAVBAR
  // ============================================================

  void _goHome() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _goNowShowing() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _goComingSoon() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  // ============================================================
  // ĐỔI SỐ LƯỢNG
  // ============================================================

  void _changeQuantity(int index, int value) {
    setState(() {
      final newQuantity = orders[index].quantity + value;

      if (newQuantity >= 0) {
        orders[index].quantity = newQuantity;
      }
    });
  }

  // ============================================================
  // ĐỔI SIZE
  // ============================================================

  void _changeSize(int index, String? size) {
    if (size == null) return;

    setState(() {
      orders[index].size = size;
    });
  }

  // ============================================================
  // TIẾP TỤC THANH TOÁN
  // ============================================================

  void _continuePayment() {
    final selectedFoodOrders = orders
        .where((item) => item.quantity > 0)
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return CheckoutScreen(
            showtimeId: widget.showtimeId,
            selectedSeats: List<String>.from(widget.selectedSeats),
            ticketPrice: widget.ticketPrice,
            foodOrders: selectedFoodOrders,
          );
        },
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

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
              // ==================================================
              // NAVBAR
              // ==================================================

              AppNavbar(
                onHome: _goHome,
                onNowShowing: _goNowShowing,
                onComingSoon: _goComingSoon,
              ),

              // ==================================================
              // BODY
              // ==================================================
              Expanded(
                child: SingleChildScrollView(
                  child: Column(children: [_buildContent(), const AppFooter()]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1115),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 34, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TITLE
              const Text(
                'Chọn Đồ ăn & Thức uống',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 24),

              // FOOD CARDS
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;

                  int columns;

                  if (width >= 900) {
                    columns = 3;
                  } else if (width >= 600) {
                    columns = 2;
                  } else {
                    columns = 1;
                  }

                  final cardWidth = (width - ((columns - 1) * 20)) / columns;

                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      for (int i = 0; i < foods.length; i++)
                        SizedBox(width: cardWidth, child: _buildFoodCard(i)),
                    ],
                  );
                },
              ),

              const SizedBox(height: 40),

              // BILL
              _buildBill(),

              const SizedBox(height: 20),

              // PAYMENT BUTTON
              _buildPaymentButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FOOD CARD
  // ============================================================

  Widget _buildFoodCard(int index) {
    final order = orders[index];
    final item = order.item;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF555555)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGE
          SizedBox(
            height: 275,
            width: double.infinity,
            child: Image.asset(
              item.image,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.white,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.fastfood,
                    size: 60,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),

          // CARD BODY
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // NAME
                Text(
                  item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                // DESCRIPTION
                Text(
                  item.description,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),

                const SizedBox(height: 16),

                // SIZE LABEL
                const Text(
                  'Chọn size',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 6),

                // SIZE DROPDOWN
                Container(
                  width: 120,
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: order.size,
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.black54,
                      ),
                      style: const TextStyle(color: Colors.black, fontSize: 14),
                      items: item.sizes.keys
                          .map(
                            (size) => DropdownMenuItem<String>(
                              value: size,
                              child: Text(size),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => _changeSize(index, value),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // PRICE
                Text(
                  _formatPrice(order.unitPrice),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 12),

                // QUANTITY
                Row(
                  children: [
                    _quantityButton(
                      '-',
                      () => _changeQuantity(index, -1),
                      const Color(0xFFDC3545),
                    ),

                    const SizedBox(width: 8),

                    Container(
                      width: 42,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: const Color(0xFF555555)),
                      ),
                      child: Text(
                        '${order.quantity}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),

                    const SizedBox(width: 8),

                    _quantityButton(
                      '+',
                      () => _changeQuantity(index, 1),
                      const Color(0xFF198754),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // +/- BUTTON
  // ============================================================

  Widget _quantityButton(String text, VoidCallback onTap, Color color) {
    return SizedBox(
      width: 34,
      height: 34,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          elevation: 0,
        ),
        child: Text(text, style: const TextStyle(fontSize: 18)),
      ),
    );
  }

  // ============================================================
  // BILL
  // ============================================================

  Widget _buildBill() {
    final selectedOrders = orders.where((item) => item.quantity > 0).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF24282C),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TITLE
          const Text(
            'Chi tiết hóa đơn',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 18),

          // HEADER
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Sản phẩm',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(
                width: 90,
                child: Text(
                  'Số lượng',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(
                width: 110,
                child: Text(
                  'Giá',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const Divider(color: Colors.white24, height: 24),

          // GHẾ
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ghế: ${widget.selectedSeats.join(', ')}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(
                width: 90,
                child: Text(
                  '${widget.selectedSeats.length}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              SizedBox(
                width: 110,
                child: Text(
                  _formatPrice(seatTotal),
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),

          // ĐỒ ĂN
          for (final order in selectedOrders) ...[
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: Text(
                    '${order.item.name} size ${order.size}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: Text(
                    '${order.quantity}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                SizedBox(
                  width: 110,
                  child: Text(
                    _formatPrice(order.total),
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],

          const Divider(color: Colors.white24, height: 28),

          // FOOD TOTAL
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tiền đồ ăn:',
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
              Text(
                _formatPrice(foodTotal),
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // GRAND TOTAL
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng thanh toán:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _formatPrice(grandTotal),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAYMENT BUTTON
  // ============================================================

  Widget _buildPaymentButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _continuePayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE50914),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          elevation: 8,
          shadowColor: const Color(0xFFE50914),
        ),
        child: const Text(
          'Tiếp tục thanh toán',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
