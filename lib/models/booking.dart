import 'food_and_drink_order_item.dart';
import 'movie.dart';

class Booking {
  final Movie movie;
  final List<String> seats;
  final List<FoodAndDrinkOrderItem> concessions;

  const Booking({
    required this.movie,
    required this.seats,
    this.concessions = const [],
  });

  int get ticketTotal => seats.length * 90000;
  int get concessionTotal =>
      concessions.fold(0, (sum, item) => sum + item.total);
  int get total => ticketTotal + concessionTotal;
}
