import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:ar_memo_frontend/models/upload_photo_result.dart';
import 'package:ar_memo_frontend/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:image_picker/image_picker.dart';

class UploadRepository {
  final ApiService _apiService;

  UploadRepository(this._apiService);

  Future<UploadPhotoResult> uploadPhoto(XFile file) async {
    final request = _apiService.multipartRequest('POST', '/uploads/photo');
    final lookupSource = file.path.isNotEmpty ? file.path : file.name;
    final mimeType = file.mimeType ?? lookupMimeType(lookupSource) ?? 'image/jpeg';
    final parts = mimeType.split('/');

    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: file.name,
          contentType: MediaType(parts.first, parts.last),
        ),
      );
    } else {
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: file.name,
          contentType: MediaType(parts.first, parts.last),
        ),
      );
    }

    final streamedResponse = await _apiService.sendMultipart(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return UploadPhotoResult.fromJson(decoded);
      }
    }
    throw Exception('Failed to upload photo: ${response.body}');
  }
}
