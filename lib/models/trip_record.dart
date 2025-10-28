// lib/models/trip_record.dart
import 'package:flutter/material.dart';

/// 그룹 객체(백엔드 populate 대응)
class GroupRef {
  final String id;
  final String name;
  /// "#RRGGBB" 또는 "#AARRGGBB" 형태 가정(없을 수 있음)
  final String? color;

  const GroupRef({
    required this.id,
    required this.name,
    this.color,
  });

  factory GroupRef.fromJson(Map<String, dynamic> json) {
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

class TripRecord {
  final String id;
  final String userId;

  /// 백엔드에서 groupId가 문자열이거나, populate되어 객체로 올 수 있어 둘 다 지원
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

  /// HomeScreen 호환용: record.groupColor
  Color get groupColor {
    final hex = group?.color;
    if (hex == null || hex.isEmpty) return Colors.blueAccent;
    return _hexToColorOrNull(hex) ?? Colors.blueAccent;
  }

  /// JSON → TripRecord
  factory TripRecord.fromJson(Map<String, dynamic> json) {
    // id
    final id = (json['id'] ?? json['_id'])?.toString() ?? '';

    // userId
    final userId = (json['userId'] ?? json['user'])?.toString() ?? '';

    // group / groupId (문자열 or 객체 모두 대응)
    GroupRef? groupObj;
    String? groupIdStr;

    dynamic groupRaw = json['groupId'] ?? json['group'];
    if (groupRaw is Map) {
      groupObj = GroupRef.fromJson(Map<String, dynamic>.from(groupRaw));
      groupIdStr = groupObj.id;
    } else if (groupRaw != null) {
      groupIdStr = groupRaw.toString();
    }

    // 기본 필드
    final title = json['title']?.toString() ?? '';
    final content = json['content']?.toString() ?? '';

    // 날짜 필드
    DateTime _parseDate(dynamic v) {
      if (v is DateTime) return v;
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      return DateTime.tryParse(v?.toString() ?? '') ?? DateTime.now();
    }

    final date = _parseDate(json['date']);
    final createdAt = _parseDate(json['createdAt']);
    final updatedAt = _parseDate(json['updatedAt']);

    // 사진 URL 배열
    final List<String> photoUrls = (json['photoUrls'] as List?)
        ?.map((e) => e?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList() ??
        const [];

    // 좌표
    double? _toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    final latitude = _toDouble(json['latitude']);
    final longitude = _toDouble(json['longitude']);

    return TripRecord(
      id: id,
      userId: userId,
      groupIdString: groupIdStr,
      group: groupObj,
      title: title,
      content: content,
      date: date,
      photoUrls: photoUrls,
      latitude: latitude,
      longitude: longitude,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// TripRecord → JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    // 백엔드에 따라 'groupId' 또는 'group' 키를 사용할 수 있음
    if (group != null) 'group': group!.toJson() else 'groupId': groupIdString,
    'title': title,
    'content': content,
    'date': date.toIso8601String(),
    'photoUrls': photoUrls,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  // 헬퍼: "#RRGGBB" / "#AARRGGBB" → Color
  static Color? _hexToColorOrNull(String hex) {
    var value = hex.trim();
    if (!value.startsWith('#')) return null;
    value = value.substring(1);
    if (value.length == 6) {
      // RRGGBB → AARRGGBB
      value = 'FF$value';
    }
    if (value.length != 8) return null;
    final intColor = int.tryParse(value, radix: 16);
    if (intColor == null) return null;
    return Color(intColor);
  }
}
