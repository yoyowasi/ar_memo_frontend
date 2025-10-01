
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

  // 위경도 값에 더 쉽게 접근하기 위한 getter
  double? get latitude => coordinates.length >= 2 ? coordinates[1] : null;
  double? get longitude => coordinates.length >= 2 ? coordinates[0] : null;

  // 대표 이미지를 가져오기 위한 getter
  String? get coverImage => photoUrl ?? thumbUrl;

  /// JSON 데이터를 Memory 객체로 변환하는 factory 생성자
  factory Memory.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>?;
    final coordinatesRaw =
        location != null ? location['coordinates'] as List<dynamic>? : json['coordinates'] as List<dynamic>?;
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

  /// Memory 객체를 JSON 데이터로 변환하는 메서드
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'location': {
        'type': 'Point',
        'coordinates': coordinates,
      },
      'anchor': anchor,
      'text': text,
      'photoUrl': photoUrl,
      'audioUrl': audioUrl,
      'thumbUrl': thumbUrl,
      'tags': tags,
      'favorite': favorite,
      'visibility': visibility,
      'groupId': groupId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    }..removeWhere((key, value) => value == null); // null 값인 필드는 제거
  }
}