class ManagedUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final int age;
  final String status;
  final String role;

  const ManagedUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.age,
    this.status = 'active',
    this.role = 'user',
  });

  bool get isActive => status == 'active';
}
