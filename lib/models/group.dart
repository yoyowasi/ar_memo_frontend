class Group {
  final String id;
  final String name;
  final String color;

  Group({required this.id, required this.name, required this.color});

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['_id'],
      name: json['name'],
      color: json['color'],
    );
  }
}