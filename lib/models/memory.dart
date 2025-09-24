class Memory {
  final String id;
  final String? userId;
  final List<double> coordinates;
  final Map<String, dynamic>? anchor;
  final String? text;
  final String? photoUrl;
  final String? audioUrl;
  final String? thumbUrl;
  final List<String> tags;
  final bool favorite;
  final String visibility;
  final String? groupId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Memory({
    required this.id,
    required this.coordinates,
    this.userId,
    this.anchor,
    this.text,
    this.photoUrl,
    this.audioUrl,
    this.thumbUrl,
    required this.tags,
    required this.favorite,
    required this.visibility,
    this.groupId,
    this.createdAt,
    this.updatedAt,
  });

  factory Memory.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>?;
    final coordinatesRaw = location != null ? location['coordinates'] as List<dynamic>? : null;
    final coordinates = coordinatesRaw != null
        ? coordinatesRaw.map((coord) => (coord as num).toDouble()).toList()
        : <double>[];

    return Memory(
      id: json['_id'] ?? json['id'],
      userId: json['userId']?.toString(),
      coordinates: coordinates,
      anchor: json['anchor'] as Map<String, dynamic>?,
      text: json['text'] as String?,
      photoUrl: json['photoUrl'] as String?,
      audioUrl: json['audioUrl'] as String?,
      thumbUrl: json['thumbUrl'] as String?,
      tags: List<String>.from((json['tags'] as List<dynamic>? ?? []).map((tag) => tag.toString())),
      favorite: json['favorite'] as bool? ?? false,
      visibility: json['visibility'] as String? ?? 'private',
      groupId: json['groupId']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }
}
