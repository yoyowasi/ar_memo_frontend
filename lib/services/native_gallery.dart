// lib/services/native_gallery.dart
import 'package:flutter/services.dart';

class NativeGallery {
  static const MethodChannel _channel = MethodChannel('image_channel');

  static Future<Map<String, dynamic>?> pickImageWithGPS() async {
    final result =
    await _channel.invokeMethod<Map<dynamic, dynamic>>('pickImageWithGPS');
    if (result == null) return null;
    return {
      'uri': result['uri'] as String?,
      'path': result['path'] as String?,
      'latitude': (result['latitude'] as num?)?.toDouble(),
      'longitude': (result['longitude'] as num?)?.toDouble(),
    };
  }
}
