class User {
  final String id;
  final String email;
  final String name;
  final String avatarUrl;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
    );
  }
}