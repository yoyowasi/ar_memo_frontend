import 'package:vector_math/vector_math_64.dart';

class Memory {
  final String id;
  final String userId;
  final double latitude;
  final double longitude;
  final String? text;
  final String? photoUrl;
  final String? audioUrl;
  final String? thumbUrl;
  final List<String> tags;
  final bool favorite;
  final String visibility;
  final String? groupId;
  final DateTime createdAt;
  final DateTime updatedAt;
  // --- anchor 필드 (백엔드 형식: List<double>[16]) ---
  final List<double>? anchor;
  // ----------------------------------------------------

  Memory({
    required this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    this.text,
    this.photoUrl,
    this.audioUrl,
    this.thumbUrl,
    required this.tags,
    required this.favorite,
    required this.visibility,
    this.groupId,
    required this.createdAt,
    required this.updatedAt,
    this.anchor,
  });

  // --- anchor 데이터를 Matrix4로 변환 ---
  Matrix4? get anchorTransform {
    if (anchor != null && anchor!.length == 16) {
      // Matrix4.fromList는 column-major 순서의 리스트를 받음
      return Matrix4.fromList(anchor!);
    }
    return null;
  }
  // -------------------------------------

  factory Memory.fromJson(Map<String, dynamic> json) {
    double lat = 0.0, lng = 0.0;
    if (json['location']?['coordinates'] is List) {
      final coords = json['location']['coordinates'] as List;
      if (coords.length >= 2 && coords[0] is num && coords[1] is num) {
        lng = (coords[0] as num).toDouble();
        lat = (coords[1] as num).toDouble();
      }
    }

    // --- anchor 파싱 (List<double>[16]) ---
    List<double>? anchorData;
    if (json['anchor'] is List) {
      try {
        anchorData = (json['anchor'] as List).map((e) => (e as num).toDouble()).toList();
        if (anchorData.length != 16) anchorData = null; // 길이 확인
      } catch (e) {
        anchorData = null; // 타입 변환 실패
        debugPrint("Anchor data parsing failed: $e");
      }
    }
    // -------------------------------------

    return Memory(
      id: json['_id'],
      userId: json['userId'],
      latitude: lat,
      longitude: lng,
      text: json['text'],
      photoUrl: json['photoUrl'],
      audioUrl: json['audioUrl'],
      thumbUrl: json['thumbUrl'],
      tags: List<String>.from(json['tags'] ?? []),
      favorite: json['favorite'] ?? false,
      visibility: json['visibility'] ?? 'private',
      groupId: json['groupId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      anchor: anchorData, // 파싱된 데이터 할당
    );
  }
}