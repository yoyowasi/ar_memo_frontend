class UploadPhotoResult {
  final String url;
  final String? thumbUrl;
  final int width;
  final int height;
  final int bytes;

  const UploadPhotoResult({
    required this.url,
    this.thumbUrl,
    required this.width,
    required this.height,
    required this.bytes,
  });

  factory UploadPhotoResult.fromJson(Map<String, dynamic> json) {
    return UploadPhotoResult(
      url: json['url'] as String,
      thumbUrl: json['thumbUrl'] as String?,
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      bytes: (json['bytes'] as num?)?.toInt() ?? 0,
    );
  }
}
