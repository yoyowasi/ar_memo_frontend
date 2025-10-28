import 'package:vector_math/vector_math_64.dart';
import 'package:flutter/foundation.dart'; // <- debugPrint 사용을 위해 추가

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
  final List<double>? anchor;

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

  Matrix4? get anchorTransform {
    if (anchor != null && anchor!.length == 16) {
      return Matrix4.fromList(anchor!);
    }
    return null;
  }

  factory Memory.fromJson(Map<String, dynamic> json) {
    double? lat;
    double? lng;

    double? parseCoordinate(dynamic value) {
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        return double.tryParse(value);
      }
      return null;
    }

    void tryAssign(dynamic latitudeSource, dynamic longitudeSource) {
      final parsedLat = parseCoordinate(latitudeSource);
      final parsedLng = parseCoordinate(longitudeSource);
      if (parsedLat != null && parsedLng != null) {
        lat ??= parsedLat;
        lng ??= parsedLng;
      }
    }

    final location = json['location'];
    if (location is Map<String, dynamic>) {
      if (location['coordinates'] is List) {
        final coords = location['coordinates'] as List;
        if (coords.length >= 2) {
          tryAssign(coords[1], coords[0]);
        }
      } else {
        tryAssign(
          location['lat'] ?? location['latitude'],
          location['lng'] ?? location['longitude'],
        );
      }
    }

    tryAssign(
      json['latitude'] ?? json['lat'],
      json['longitude'] ?? json['lng'],
    );

    final latValue = lat ?? 0.0;
    final lngValue = lng ?? 0.0;

    List<double>? anchorData;
    if (json['anchor'] is List) {
      try {
        anchorData = (json['anchor'] as List).map((e) => (e as num).toDouble()).toList();
        if (anchorData.length != 16) anchorData = null;
      } catch (e) {
        anchorData = null;
        debugPrint("Anchor data parsing failed: $e"); // <- 오류 해결
      }
    }

    return Memory(
      id: json['_id'],
      userId: json['userId'],
      latitude: latValue,
      longitude: lngValue,
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
      anchor: anchorData,
    );
  }
}