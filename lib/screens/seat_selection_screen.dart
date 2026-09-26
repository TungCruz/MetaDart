import 'package:flutter/material.dart';

import '../models/seat.dart';
import '../widgets/app_footer.dart';
import '../widgets/app_navbar.dart';
import 'food_and_drink_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
  final int showtimeId;
  final int ticketPrice;

  final VoidCallback? onGoHome;
  final VoidCallback? onGoNowShowing;
  final VoidCallback? onGoComingSoon;

  const SeatSelectionScreen({
    super.key,
    this.showtimeId = 122,
    this.ticketPrice = 100000,
    this.onGoHome,
    this.onGoNowShowing,
    this.onGoComingSoon,
  });

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  late List<Seat> seats;

  final Set<String> selectedSeats = {};

  @override
  void initState() {
    super.initState();

    seats = _createDemoSeats();
  }

  // ============================================================
  // TẠO GHẾ DEMO
  // ============================================================

  List<Seat> _createDemoSeats() {
    final List<Seat> result = [];

    const rows = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];

    for (final row in rows) {
      for (int number = 1; number <= 10; number++) {
        final code = '$row$number';

        result.add(
          Seat(
            code: code,

            // Demo ghế đã bán
            sold: code == 'A5' || code == 'D7',

            // Demo ghế đang bị khóa
            locked: code == 'B8' || code == 'F4',
          ),
        );
      }
    }

    return result;
  }

  // ============================================================
  // LẤY GHẾ THEO HÀNG
  // ============================================================

  List<Seat> _getRowSeats(String row) {
    return seats.where((seat) => seat.code.startsWith(row)).toList();
  }

  // ============================================================
  // CHỌN / BỎ GHẾ
  // ============================================================

  void _toggleSeat(Seat seat) {
    if (seat.isUnavailable) {
      return;
    }

    setState(() {
      if (selectedSeats.contains(seat.code)) {
        selectedSeats.remove(seat.code);
      } else {
        selectedSeats.add(seat.code);
      }
    });
  }

  // ============================================================
  // TÍNH TOÁN
  // ============================================================

  int get selectedCount {
    return selectedSeats.length;
  }

  int get totalPrice {
    return selectedCount * widget.ticketPrice;
  }

  String _formatPrice(int price) {
    return '${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match.group(1)}.')}đ';
  }

  // ============================================================
  // VỀ TRANG CHỦ
  // ============================================================

  void _goHome() {
    if (widget.onGoHome != null) {
      widget.onGoHome!.call();
      return;
    }

    Navigator.popUntil(context, (route) => route.isFirst);
  }

  // ============================================================
  // PHIM ĐANG CHIẾU
  // ============================================================

  void _goNowShowing() {
    if (widget.onGoNowShowing != null) {
      widget.onGoNowShowing!.call();
      return;
    }

    Navigator.popUntil(context, (route) => route.isFirst);
  }

  // ============================================================
  // PHIM SẮP CHIẾU
  // ============================================================

  void _goComingSoon() {
    if (widget.onGoComingSoon != null) {
      widget.onGoComingSoon!.call();
      return;
    }

    Navigator.popUntil(context, (route) => route.isFirst);
  }

  // ============================================================
  // ĐẶT VÉ
  // ============================================================

  void _continueBooking() {
    // Không có ghế
    if (selectedSeats.isEmpty) {
      return;
    }

    // Sắp xếp ghế
    final List<String> sortedSeats = selectedSeats.toList()..sort();

    // Debug để kiểm tra
    debugPrint('======================================');
    debugPrint('CHUYỂN SANG TRANG ĐỒ ĂN');
    debugPrint('Showtime ID: ${widget.showtimeId}');
    debugPrint('Ghế: ${sortedSeats.join(', ')}');
    debugPrint('Giá vé: ${widget.ticketPrice}');
    debugPrint('======================================');

    // ==========================================================
    // CHUYỂN SANG TRANG CHỌN ĐỒ ĂN & THỨC UỐNG
    // ==========================================================

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return FoodAndDrinkScreen(
            showtimeId: widget.showtimeId,
            selectedSeats: sortedSeats,
            ticketPrice: widget.ticketPrice,
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
              // NỘI DUNG + FOOTER
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
            children: [
              // Tiêu đề
              _buildTitle(),

              const SizedBox(height: 14),

              // Gạch đỏ
              _buildTitleLine(),

              const SizedBox(height: 30),

              // Chú thích
              _buildLegend(),

              const SizedBox(height: 30),

              // Sơ đồ ghế
              _buildCinemaLayout(),

              const SizedBox(height: 34),

              // Tổng tiền + nút đặt vé
              _buildSummary(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TITLE
  // ============================================================

  Widget _buildTitle() {
    return const Text(
      'Chọn ghế của bạn',
      textAlign: TextAlign.center,

      style: TextStyle(
        color: Colors.white,
        fontSize: 32,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // ============================================================
  // TITLE LINE
  // ============================================================

  Widget _buildTitleLine() {
    return Container(
      width: 50,
      height: 4,

      decoration: BoxDecoration(
        color: const Color(0xFFE50914),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // ============================================================
  // LEGEND
  // ============================================================

  Widget _buildLegend() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 22,
      runSpacing: 10,

      children: [
        _legendItem(const Color(0xFF444451), 'Còn trống'),

        _legendItem(const Color(0xFFE50914), 'Đang chọn'),

        _legendItem(const Color(0xFF1C1C1C), 'Đã bán/khóa'),
      ],
    );
  }

  Widget _legendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,

      children: [
        Container(
          width: 21,
          height: 18,

          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),

        const SizedBox(width: 6),

        Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }

  // ============================================================
  // CINEMA LAYOUT
  // ============================================================

  Widget _buildCinemaLayout() {
    return Column(
      children: [
        // ======================================================
        // MÀN HÌNH
        // ======================================================

        Container(
          width: double.infinity,
          height: 10,

          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1F1F1F), Color(0xFF2B2B2B)],
            ),

            borderRadius: BorderRadius.circular(6),

            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 12)],
          ),
        ),

        const SizedBox(height: 28),

        const Text(
          'MÀN HÌNH',

          style: TextStyle(
            color: Colors.white38,
            fontSize: 12,
            letterSpacing: 3,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 20),

        // ======================================================
        // SƠ ĐỒ GHẾ
        // ======================================================
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,

          child: Column(
            children: [
              for (final row in ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'])
                _buildSeatRow(row),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SEAT ROW
  // ============================================================

  Widget _buildSeatRow(String row) {
    final rowSeats = _getRowSeats(row);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          // Tên hàng
          SizedBox(
            width: 22,

            child: Text(
              row,
              textAlign: TextAlign.center,

              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Các ghế
          for (int i = 0; i < rowSeats.length; i++) ...[
            // Khoảng cách giữa ghế 2 và 3
            if (i == 2) const SizedBox(width: 12),

            // Khoảng cách giữa ghế 8 và 9
            if (i == rowSeats.length - 2) const SizedBox(width: 12),

            _buildSeat(rowSeats[i]),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // SEAT
  // ============================================================

  Widget _buildSeat(Seat seat) {
    final bool selected = selectedSeats.contains(seat.code);

    Color seatColor;

    // Đã bán / khóa
    if (seat.isUnavailable) {
      seatColor = const Color(0xFF1C1C1C);
    }
    // Đang chọn
    else if (selected) {
      seatColor = const Color(0xFFE50914);
    }
    // Còn trống
    else {
      seatColor = const Color(0xFF444451);
    }

    return GestureDetector(
      onTap: () {
        _toggleSeat(seat);
      },

      child: Padding(
        padding: const EdgeInsets.all(3),

        child: Tooltip(
          message: seat.code,

          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),

            width: 25,
            height: 20,

            decoration: BoxDecoration(
              color: seatColor,

              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(5),
              ),

              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: const Color(0xFFE50914).withOpacity(0.45),

                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummary() {
    final List<String> sortedSeats = selectedSeats.toList()..sort();

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),

      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),

        borderRadius: BorderRadius.circular(8),

        border: Border.all(color: const Color(0xFF333333)),

        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 10)],
      ),

      child: Column(
        children: [
          // ======================================================
          // TỔNG GHẾ + GIÁ
          // ======================================================

          Text(
            'Bạn đã chọn $selectedCount ghế '
            'với tổng giá là ${_formatPrice(totalPrice)}',

            textAlign: TextAlign.center,

            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          // ======================================================
          // DANH SÁCH GHẾ
          // ======================================================
          if (sortedSeats.isNotEmpty) ...[
            const SizedBox(height: 8),

            Text(
              sortedSeats.join(', '),

              textAlign: TextAlign.center,

              style: const TextStyle(
                color: Color(0xFFE50914),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          const SizedBox(height: 18),

          // ======================================================
          // NÚT ĐẶT VÉ
          // ======================================================
          SizedBox(
            width: double.infinity,

            child: ElevatedButton(
              // Không có ghế -> disable
              // Có ghế -> chuyển sang FoodAndDrinkScreen
              onPressed: selectedSeats.isEmpty ? null : _continueBooking,

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE50914),

                disabledBackgroundColor: const Color(0xFF333333),

                foregroundColor: Colors.white,

                disabledForegroundColor: Colors.white38,

                padding: const EdgeInsets.symmetric(vertical: 14),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),

                elevation: 4,

                shadowColor: const Color(0xFFE50914),
              ),

              child: const Text(
                'Đặt vé',

                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
