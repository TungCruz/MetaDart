class Seat {
  final String code;
  final bool locked;
  final bool sold;
  final bool active;

  const Seat({
    required this.code,
    this.locked = false,
    this.sold = false,
    this.active = true,
  });

  bool get isUnavailable => locked || sold || !active;
}