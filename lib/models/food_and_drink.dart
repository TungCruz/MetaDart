class FoodAndDrink {
  final String id;
  final String name;
  final String description;
  final String category;
  final int price;
  final String icon;
  final List<FoodSize> sizes;

  const FoodAndDrink({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.icon,
    this.sizes = const [],
  });
}

class FoodSize {
  final String name;
  final int price;

  const FoodSize(this.name, this.price);
}
