// lib/models/trip_record.dart
import 'package:flutter/material.dart';

/// 그룹 참조(응답에서 populate된 경우)
class GroupRef {
  final String id;
  final String name;
  final String? color; // "#RRGGBB" 형태 가정

  const GroupRef({
    required this.id,
    required this.name,
    this.color,
  });

  factory GroupRef.fromJson(Map<String, dynamic> json) {
    // id or _id 지원
    final rawId = (json['id'] ?? json['_id'])?.toString() ?? '';
    return GroupRef(
      id: rawId,
      name: json['name']?.toString() ?? '',
      color: json['color']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (color != null) 'color': color,
  };
}

/// TripRecord 모델
class TripRecord {
  final String id;
  final String userId;

  /// 백엔드에서 populate되면 groupId가 객체가 되어 들어올 수 있음
  /// - 이 모델에서는 내부적으로
  ///   - groupIdString : 문자열 형태의 groupId
  ///   - group         : populate된 그룹 객체
  /// 를 함께 보유합니다.
  final String? groupIdString;
  final GroupRef? group;

  final String title;
  final String content;
  final DateTime date;
  final List<String> photoUrls;

  final double? latitude;
  final double? longitude;

  final DateTime createdAt;
  final DateTime updatedAt;

  const TripRecord({
    required this.id,
    required this.userId,
    this.groupIdString,
    this.group,
    required this.title,
    required this.content,
    required this.date,
    required this.photoUrls,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
  });

  /// JSON → TripRecord
  factory TripRecord.fromJson(Map<String, dynamic> json) {
    // id or _id 지원
    final rawId = (json['id'] ?? json['_id'])?.toString() ?? '';
    final userId = json['userId']?.toString() ?? '';

    // groupId가 문자열 또는 객체(populate)일 수 있음
    String? groupIdString;
    GroupRef? group;

    final groupIdRaw = json['groupId'];
    if (groupIdRaw is String) {
      groupIdString = groupIdRaw;
    } else if (groupIdRaw is Map<String, dynamic>) {
      group = GroupRef.fromJson(groupIdRaw);
      groupIdString = (groupIdRaw['id'] ?? groupIdRaw['_id'])?.toString();
    } else if (groupIdRaw != null) {
      // 예외적인 형태 방어
      groupIdString = groupIdRaw.toString();
    }

    final title = json['title']?.toString() ?? '';
    final content = json['content']?.toString() ?? '';

    final dateStr = json['date']?.toString();
    final date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();

    // photoUrls: array of string
    final List<String> photos = [];
    final rawPhotos = json['photoUrls'];
    if (rawPhotos is List) {
      for (final p in rawPhotos) {
        if (p != null) photos.add(p.toString());
      }
    }

    // 위/경도 (선택)
    double? lat;
    double? lng;
    final latRaw = json['latitude'];
    final lngRaw = json['longitude'];
    if (latRaw != null) {
      lat = (latRaw is num) ? latRaw.toDouble() : double.tryParse(latRaw.toString());
    }
    if (lngRaw != null) {
      lng = (lngRaw is num) ? lngRaw.toDouble() : double.tryParse(lngRaw.toString());
    }

    final createdAtStr = json['createdAt']?.toString();
    final updatedAtStr = json['updatedAt']?.toString();
    final createdAt = createdAtStr != null ? DateTime.parse(createdAtStr) : DateTime.now();
    final updatedAt = updatedAtStr != null ? DateTime.parse(updatedAtStr) : DateTime.now();

    return TripRecord(
      id: rawId,
      userId: userId,
      groupIdString: groupIdString,
      group: group,
      title: title,
      content: content,
      date: date,
      photoUrls: photos,
      latitude: lat,
      longitude: lng,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// TripRecord → JSON (서버 전송용)
  /// - 서버는 보통 `groupId`(문자열)만 받으므로, 우선순위: group?.id → groupIdString
  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'groupId': group?.id ?? groupIdString,
    'title': title,
    'content': content,
    'date': date.toUtc().toIso8601String(),
    'photoUrls': photoUrls,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  TripRecord copyWith({
    String? id,
    String? userId,
    String? groupIdString,
    GroupRef? group,
    String? title,
    String? content,
    DateTime? date,
    List<String>? photoUrls,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TripRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      groupIdString: groupIdString ?? this.groupIdString,
      group: group ?? this.group,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      photoUrls: photoUrls ?? this.photoUrls,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// UI 편의를 위한 확장: groupColor
extension TripRecordColorExtension on TripRecord {
  /// 그룹 색상(hex → Color). 없으면 기본 색상 반환.
  Color get groupColor {
    final hex = group?.color;
    if (hex == null || hex.isEmpty) {
      return Colors.blueAccent;
    }
    final parsed = _parseHexColor(hex);
    return parsed ?? Colors.blueAccent;
  }
}

/// "#RRGGBB" 또는 "RRGGBB" 형태를 Color로 변환
Color? _parseHexColor(String input) {
  var hex = input.trim();
  if (hex.startsWith('#')) hex = hex.substring(1);
  if (hex.length == 6) {
    hex = 'FF$hex'; // 불투명도 추가
  }
  if (hex.length != 8) return null;
  final intVal = int.tryParse(hex, radix: 16);
  if (intVal == null) return null;
  return Color(intVal);
}
