import 'package:ar_memo_frontend/models/group.dart';

class TripRecord {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final Group? group; // 그룹 정보는 nullable일 수 있습니다.
  final List<String> photoUrls;

  TripRecord({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    this.group,
    required this.photoUrls,
  });

  factory TripRecord.fromJson(Map<String, dynamic> json) {
    return TripRecord(
      id: json['_id'],
      title: json['title'],
      content: json['content'] ?? '',
      date: DateTime.parse(json['date']),
      group: json['groupId'] != null ? Group.fromJson(json['groupId']) : null,
      photoUrls: List<String>.from(json['photoUrls'] ?? []),
    );
  }
}