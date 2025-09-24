class Group {
  final String id;
  final String name;
  final String? colorHex;
  final String? ownerId;
  final List<String> memberIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Group({
    required this.id,
    required this.name,
    this.colorHex,
    this.ownerId,
    this.memberIds = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    final members = (json['members'] as List<dynamic>? ?? [])
        .map((member) => member.toString())
        .toList();

    return Group(
      id: json['_id']?.toString() ?? json['id'].toString(),
      name: json['name'] as String? ?? '',
      colorHex: json['color']?.toString(),
      ownerId: json['ownerId']?.toString(),
      memberIds: members,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

  int get colorValue {
    final colorString = colorHex ?? '#8D7BFD';
    final normalized = colorString.replaceFirst('#', '');
    return int.tryParse('0xFF$normalized') ?? 0xFF8D7BFD;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': colorHex,
      'ownerId': ownerId,
      'members': memberIds,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    }..removeWhere((key, value) => value == null);
  }
}