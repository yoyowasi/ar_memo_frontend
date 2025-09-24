class Memory {
  final String id;
  final List<double> coordinates;
  final String? text;
  final String? photoUrl;
  final String? thumbUrl;
  final List<String> tags;
  final bool favorite;
  final String visibility;
  final String? groupId;

  Memory({
    required this.id,
    required this.coordinates,
    this.text,
    this.photoUrl,
    this.thumbUrl,
    required this.tags,
    required this.favorite,
    required this.visibility,
    this.groupId,
  });

  factory Memory.fromJson(Map<String, dynamic> json) {
    return Memory(
      id: json['_id'],
      coordinates: List<double>.from(json['location']['coordinates'].map((coord) => coord.toDouble())),
      text: json['text'],
      photoUrl: json['photoUrl'],
      thumbUrl: json['thumbUrl'],
      tags: List<String>.from(json['tags'] ?? []),
      favorite: json['favorite'] ?? false,
      visibility: json['visibility'] ?? 'private',
      groupId: json['groupId'],
    );
  }
}