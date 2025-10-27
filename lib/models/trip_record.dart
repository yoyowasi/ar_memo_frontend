import 'package:ar_memo_frontend/models/group.dart';
import 'package:flutter/material.dart'; // Color 사용 위해 추가

class TripRecord {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final String? groupId;
  final Group? group; // 백엔드 populate 결과
  final List<String> photoUrls;
  // --- 필드 추가 ---
  final double? latitude;
  final double? longitude;
  // ----------------

  TripRecord({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    this.groupId,
    this.group,
    required this.photoUrls,
    this.latitude, // <-- 생성자 추가
    this.longitude, // <-- 생성자 추가
  });

  // group 객체로부터 색상 값을 가져오는 getter (편의용)
  Color? get groupColor {
    if (group?.colorHex != null) {
      try {
        final colorValue = int.tryParse('0xFF${group!.colorHex!.replaceFirst('#', '')}');
        if (colorValue != null) return Color(colorValue);
      } catch (_) {}
    }
    return null;
  }

  factory TripRecord.fromJson(Map<String, dynamic> json) {
    Group? group;
    String? groupId;
    // populate된 group 객체 또는 groupId 문자열 처리
    final groupData = json['groupId']; // 백엔드에서 populate 필드명 확인 필요
    if (groupData is Map<String, dynamic>) {
      group = Group.fromJson(groupData);
      groupId = group.id;
    } else if (groupData is String) {
      groupId = groupData;
    }

    // location 필드 파싱 (GeoJSON Point)
    double? lat;
    double? lng;
    if (json['location'] != null &&
        json['location']['type'] == 'Point' &&
        json['location']['coordinates'] is List) {
      final coords = json['location']['coordinates'] as List;
      if (coords.length >= 2 && coords[0] is num && coords[1] is num) {
        lng = (coords[0] as num).toDouble(); // 경도
        lat = (coords[1] as num).toDouble(); // 위도
      }
    }

    return TripRecord(
      id: json['_id'],
      title: json['title'] ?? '', // null 처리 강화
      content: json['content'] ?? '',
      date: DateTime.parse(json['date']),
      groupId: groupId,
      group: group,
      photoUrls: List<String>.from(json['photoUrls'] ?? []),
      latitude: lat,
      longitude: lng,
    );
  }

  // toJson은 API 요청 시 사용되므로, 백엔드가 받을 형식에 맞춰야 함
  Map<String, dynamic> toJson() {
    return {
      // '_id' 대신 'id' 사용 (업데이트 시 필요할 수 있음)
      'id': id,
      'title': title,
      'content': content,
      'date': date.toIso8601String(), // ISO 8601 형식
      'groupId': groupId, // ObjectId 문자열
      'photoUrls': photoUrls,
      // 위치 정보는 생성/수정 API에서 별도 파라미터로 처리
      'latitude': latitude,
      'longitude': longitude,
    }..removeWhere((key, value) => value == null); // null 값 제거
  }
}