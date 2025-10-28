// lib/models/trip_record.dart
import 'dart:convert';
import 'package:flutter/material.dart';

/// 백엔드가 populate한 그룹 요약 객체
class GroupSummary {
  final String id;
  final String name;
  final String? color; // 예: "#FF8040"

  GroupSummary({
    required this.id,
    required this.name,
    this.color,
  });

  factory GroupSummary.fromJson(dynamic json) {
    // json은 Map이어야 함. (string이면 호출 금지)
    return GroupSummary(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      color: json['color']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'color': color,
  };
}

/// TripRecord 도메인 모델
class TripRecord {
  final String id;
  final String userId;
  final String? groupIdRaw; // 백엔드가 문자열로 주는 경우를 보존
  final GroupSummary? _group; // populate 된 경우
  final String title;
  final String content;
  final DateTime date;
  final List<String> photoUrls;

  /// 좌표 (신규 스키마)
  final double? latitude;
  final double? longitude;

  /// 구형 데이터 호환용 (location.coordinates = [lng, lat])
  final _GeoPoint? _location;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  TripRecord({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.date,
    required this.photoUrls,
    this.latitude,
    this.longitude,
    String? groupIdRaw,
    GroupSummary? groupPopulated,
    _GeoPoint? location,
    this.createdAt,
    this.updatedAt,
  })  : groupIdRaw = groupIdRaw,
        _group = groupPopulated,
        _location = location;

  /// UI 코드 호환용: record.group 로 접근 가능
  GroupSummary? get group => _group;

  /// UI 코드 호환용: record.groupColor 로 접근 가능
  Color? get groupColor {
    final hex = _group?.color;
    if (hex == null || hex.isEmpty) return null;
    return _hexToColorOrNull(hex);
  }

  /// 좌표 최종 결정 (latitude/longitude 우선, 없으면 location.coordinates 폴백)
  double? get lat {
    if (latitude != null) return latitude;
    return _location?.lat;
  }

  double? get lng {
    if (longitude != null) return longitude;
    return _location?.lng;
  }

  /// JSON 파싱
  factory TripRecord.fromJson(Map<String, dynamic> json) {
    // photoUrls: string 배열로 정규화
    final photos = <String>[];
    final rawPhotos = json['photoUrls'];
    if (rawPhotos is List) {
      for (final e in rawPhotos) {
        if (e != null) photos.add(e.toString());
      }
    }

    // groupId: string 또는 object(populate)
    String? groupIdRaw;
    GroupSummary? groupPopulated;
    final gid = json['groupId'];
    if (gid == null) {
      groupIdRaw = null;
      groupPopulated = null;
    } else if (gid is String) {
      groupIdRaw = gid;
      groupPopulated = null;
    } else if (gid is Map) {
      // populate된 객체
      groupIdRaw = (gid['_id'] ?? gid['id'])?.toString();
      groupPopulated = GroupSummary.fromJson(gid);
    } else {
      groupIdRaw = gid.toString();
    }

    // 좌표: 신규 필드 우선
    final lat = _toDoubleOrNull(json['latitude']);
    final lng = _toDoubleOrNull(json['longitude']);

    // 폴백: 구형 location GeoJSON
    _GeoPoint? location;
    if ((lat == null || lng == null) && json['location'] is Map) {
      location = _GeoPoint.fromJson(json['location'] as Map<String, dynamic>);
    }

    return TripRecord(
      id: (json['_id'] ?? json['id']).toString(),
      userId: json['userId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      photoUrls: photos,
      latitude: lat,
      longitude: lng,
      groupIdRaw: groupIdRaw,
      groupPopulated: groupPopulated,
      location: location,
      createdAt: _parseDateOrNull(json['createdAt']),
      updatedAt: _parseDateOrNull(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'userId': userId,
    'title': title,
    'content': content,
    'date': date.toIso8601String(),
    'photoUrls': photoUrls,
    'latitude': latitude ?? _location?.lat,
    'longitude': longitude ?? _location?.lng,
    'groupId': _group?.toJson() ?? groupIdRaw,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };
}

/// 구형 GeoJSON 폴백
class _GeoPoint {
  final double lat;
  final double lng;

  _GeoPoint({required this.lat, required this.lng});

  factory _GeoPoint.fromJson(Map<String, dynamic> json) {
    // { type: "Point", coordinates: [lng, lat] }
    final coords = json['coordinates'];
    if (coords is List && coords.length >= 2) {
      final lng = _toDoubleOrNull(coords[0]) ?? 126.9780;
      final lat = _toDoubleOrNull(coords[1]) ?? 37.5665;
      return _GeoPoint(lat: lat, lng: lng);
    }
    return _GeoPoint(lat: 37.5665, lng: 126.9780);
  }
}

/// 헬퍼들
DateTime? _parseDateOrNull(dynamic v) {
  if (v == null) return null;
  try {
    return DateTime.parse(v.toString());
  } catch (_) {
    return null;
  }
}

double? _toDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  return double.tryParse(s);
}

Color? _hexToColorOrNull(String hex) {
  // '#RRGGBB' 또는 'RRGGBB' 지원
  var v = hex.trim();
  if (v.startsWith('#')) v = v.substring(1);
  if (v.length == 6) v = 'FF$v'; // 불투명
  final val = int.tryParse(v, radix: 16);
  if (val == null) return null;
  return Color(val);
}
