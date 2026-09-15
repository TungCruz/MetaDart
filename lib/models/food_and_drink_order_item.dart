import 'food_and_drink.dart';

class FoodAndDrinkOrderItem {
  final FoodAndDrink item;
  final FoodSize? size;
  final int quantity;

  const FoodAndDrinkOrderItem({
    required this.item,
    required this.quantity,
    this.size,
  });

  int get unitPrice => size?.price ?? item.price;
  int get total => unitPrice * quantity;
  String get displayName => size == null ? item.name : '${item.name} · ${size!.name}';
}
