import 'package:ar_memo_frontend/models/group.dart';

class TripRecord {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final String? groupId;
  final Group? group; // 그룹 정보는 nullable일 수 있습니다.
  final List<String> photoUrls;

  TripRecord({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    this.groupId,
    this.group,
    required this.photoUrls,
  });

  factory TripRecord.fromJson(Map<String, dynamic> json) {
    Group? group;
    String? groupId;
    final groupData = json['group'] ?? json['groupId'];
    if (groupData is Map<String, dynamic>) {
      group = Group.fromJson(groupData);
      groupId = group.id;
    } else if (groupData != null) {
      groupId = groupData.toString();
    }

    return TripRecord(
      id: json['_id'],
      title: json['title'],
      content: json['content'] ?? '',
      date: DateTime.parse(json['date']),
      groupId: groupId,
      group: group,
      photoUrls: List<String>.from(json['photoUrls'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date.toIso8601String(),
      'groupId': groupId,
      'photoUrls': photoUrls,
    }..removeWhere((key, value) => value == null);
  }
}