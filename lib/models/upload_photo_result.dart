// lib/models/upload_photo_result.dart
class UploadPhotoResult {
  final String url; // 임시 보기용 URL
  final String? thumbUrl; // 임시 보기용 썸네일 URL
  final String key; // DB 저장용 GCS Key
  final String? thumbKey; // DB 저장용 GCS Key (썸네일)
  final int width;
  final int height;
  final int bytes;

  const UploadPhotoResult({
    required this.url,
    this.thumbUrl,
    required this.key,
    this.thumbKey,
    required this.width,
    required this.height,
    required this.bytes,
  });

  factory UploadPhotoResult.fromJson(Map<String, dynamic> json) {
    return UploadPhotoResult(
      url: json['url'] as String? ?? '', // url이 null일 경우 대비
      thumbUrl: json['thumbUrl'] as String?,
      key: json['key'] as String? ?? '', // key가 필수
      thumbKey: json['thumbKey'] as String?,
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      bytes: (json['bytes'] as num?)?.toInt() ?? 0,
    );
  }
}