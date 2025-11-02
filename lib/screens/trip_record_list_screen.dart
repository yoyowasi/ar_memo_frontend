// lib/screens/trip_record_list_screen.dart
import 'dart:io';
import 'package:ar_memo_frontend/models/trip_record.dart';
import 'package:ar_memo_frontend/providers/trip_record_provider.dart';
import 'package:ar_memo_frontend/providers/upload_provider.dart';
import 'package:ar_memo_frontend/screens/create_trip_record_screen.dart';
import 'package:ar_memo_frontend/screens/trip_record_detail_screen.dart';
import 'package:ar_memo_frontend/theme/colors.dart';
import 'package:ar_memo_frontend/theme/text_styles.dart';
import 'package:ar_memo_frontend/widgets/trip_record_search_delegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:native_exif/native_exif.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/native_gallery.dart';

enum TripRecordFilter {
  all,
  withPhotos,
  withGroup,
}

class TripRecordListScreen extends ConsumerWidget {
  const TripRecordListScreen({super.key});

  List<TripRecord> _applyFilter(
      List<TripRecord> records, TripRecordFilter filter) {
    switch (filter) {
      case TripRecordFilter.all:
        return records;
      case TripRecordFilter.withPhotos:
        return records.where((record) => record.photoUrls.isNotEmpty).toList();
      case TripRecordFilter.withGroup:
        return records
            .where((record) =>
        record.group != null ||
            (record.groupIdString != null &&
                record.groupIdString!.isNotEmpty))
            .toList();
    }
  }

  Future<void> _openSearch(BuildContext context, WidgetRef ref) async {
    final records = ref.read(tripRecordsProvider).asData?.value ?? [];
    if (records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('검색할 일기가 없습니다.')),
      );
      return;
    }

    final selected = await showSearch<TripRecord?>(
      context: context,
      delegate: TripRecordSearchDelegate(records),
    );

    if (selected != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TripRecordDetailScreen(recordId: selected.id),
        ),
      );
    }
  }

  Future<void> _openFilter(BuildContext context, WidgetRef ref) async {
    final records = ref.read(tripRecordsProvider).asData?.value ?? [];
    if (records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('필터링할 일기가 없습니다.')),
      );
      return;
    }

    final filter = await showModalBottomSheet<TripRecordFilter>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.all_inclusive),
                title: const Text('전체 보기'),
                onTap: () => Navigator.of(ctx).pop(TripRecordFilter.all),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('사진이 있는 일기'),
                onTap: () =>
                    Navigator.of(ctx).pop(TripRecordFilter.withPhotos),
              ),
              ListTile(
                leading: const Icon(Icons.group_outlined),
                title: const Text('그룹에 공유된 일기'),
                onTap: () => Navigator.of(ctx).pop(TripRecordFilter.withGroup),
              ),
            ],
          ),
        );
      },
    );

    if (filter == null) return;

    final filtered = _applyFilter(records, filter);
    if (filtered.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('조건에 맞는 일기가 없습니다.')),
        );
      }
      return;
    }

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final record = filtered[index];
              return ListTile(
                leading: const Icon(Icons.article_outlined),
                title: Text(record.title, style: bodyText1),
                subtitle: Text(
                  DateFormat('yyyy.MM.dd').format(record.date),
                  style: bodyText2,
                ),
                trailing: record.photoUrls.isNotEmpty
                    ? const Icon(Icons.photo, color: primaryColor)
                    : null,
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          TripRecordDetailScreen(recordId: record.id),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<bool> _ensureMediaLocationPermission() async {
    final status = await Permission.accessMediaLocation.status;
    debugPrint('🟡 [perm] ACCESS_MEDIA_LOCATION status: $status');
    if (status.isGranted) return true;
    final result = await Permission.accessMediaLocation.request();
    debugPrint('🟡 [perm] ACCESS_MEDIA_LOCATION result: $result');
    return result.isGranted;
  }

  Future<Map<String, double>?> _getExifLocationFromXFile(XFile file) async {
    debugPrint('[EXIF Fallback] Attempting to read EXIF from file: ${file.path}');
    try {
      final exif = await Exif.fromPath(file.path);
      final latLong = await exif.getLatLong();
      if (latLong != null) {
        debugPrint(
            '[EXIF Fallback] LatLong found (auto): ${latLong.latitude}, ${latLong.longitude}');
        await exif.close();
        return {'latitude': latLong.latitude, 'longitude': latLong.longitude};
      }

      debugPrint(
          '[EXIF Fallback] getLatLong() failed, trying manual parsing...');
      final latValue = await exif.getAttribute('GPSLatitude');
      final latRef = await exif.getAttribute('GPSLatitudeRef');
      final lonValue = await exif.getAttribute('GPSLongitude');
      final lonRef = await exif.getAttribute('GPSLongitudeRef');

      debugPrint(
          '[EXIF Fallback] RAW EXIF latValue: $latValue (type: ${latValue.runtimeType})');
      debugPrint(
          '[EXIF Fallback] RAW EXIF lonValue: $lonValue (type: ${lonValue.runtimeType})');

      if (latValue != null &&
          latRef != null &&
          lonValue != null &&
          lonRef != null) {
        final latitude = _convertDmsToDecimal(latValue, latRef.toString());
        final longitude = _convertDmsToDecimal(lonValue, lonRef.toString());
        if (latitude != null && longitude != null) {
          debugPrint(
              '[EXIF Fallback] LatLong found (manual): $latitude, $longitude');
          await exif.close();
          return {'latitude': latitude, 'longitude': longitude};
        }
      }
      await exif.close();
    } catch (e) {
      debugPrint('[EXIF Fallback] Error reading EXIF from ${file.path}: $e');
    }
    debugPrint('[EXIF Fallback] No EXIF location found.');
    return null;
  }

  Future<void> _createTripRecordWithPhoto(
      BuildContext context, WidgetRef ref) async {
    await _ensureMediaLocationPermission();

    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    double? latitude;
    double? longitude;
    XFile? pickedFile;

    try {
      debugPrint('🟢 [list_screen] 1. Trying NativeGallery.pickImageWithGPS...');
      final native = await NativeGallery.pickImageWithGPS();
      if (native != null) {
        debugPrint('🟢 [list_screen] NativeGallery result=$native');
        final uri = native['uri'] as String?;
        final path = native['path'] as String?;
        latitude = native['latitude'] as double?;
        longitude = native['longitude'] as double?;

        String? finalPath = path;
        if ((finalPath == null || finalPath.isEmpty) && uri != null) {
          finalPath = Uri.parse(uri).path;
        }

        if (finalPath != null && finalPath.isNotEmpty) {
          pickedFile = XFile(finalPath);
          if (latitude != null) {
            debugPrint(
                '🟢 [list_screen] NativeGallery SUCCESS. lat=$latitude, lng=$longitude');
          } else {
            debugPrint(
                '🟢 [list_screen] NativeGallery SUCCESS (image only). No EXIF.');
          }
        } else {
          debugPrint(
              '🟥 [list_screen] native[path] 도 없고 uri 로 변환한 path 도 없음 → picker fallback');
        }
      } else {
        debugPrint(
            '🟥 [list_screen] NativeGallery returned null. Falling back to ImagePicker.');
      }

      if (pickedFile == null) {
        final picker = ImagePicker();
        pickedFile = await picker.pickImage(source: ImageSource.gallery);
        if (pickedFile == null) {
          debugPrint('🟥 [list_screen] ImagePicker also returned null.');
          if (context.mounted) Navigator.of(context).pop();
          return;
        }

        final location = await _getExifLocationFromXFile(pickedFile);
        if (location != null) {
          latitude = location['latitude'];
          longitude = location['longitude'];
        }
      }

      final repository = ref.read(uploadRepositoryProvider);
      final result = await repository.uploadPhoto(pickedFile);

      if (!context.mounted) return;
      Navigator.of(context).pop();

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateTripRecordScreen(
            initialPhotoKeys: [result.key],
            initialPhotoUrls: [result.url],
            initialLatitude: latitude,
            initialLongitude: longitude,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사진 업로드 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripRecordsAsyncValue = ref.watch(tripRecordsProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createTripRecordWithPhoto(context, ref),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('일기 쓰기'),
      ),
      appBar: AppBar(
        title: const Text('일기', style: heading2),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(color: borderColor, height: 1.0)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: textColor),
            tooltip: '검색',
            onPressed: () => _openSearch(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: textColor),
            tooltip: '필터',
            onPressed: () => _openFilter(context, ref),
          ),
        ],
      ),
      body: tripRecordsAsyncValue.when(
        data: (records) {
          if (records.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.article_outlined,
                      size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('작성된 일기가 없습니다.', style: bodyText1),
                  const SizedBox(height: 4),
                  const Text('새로운 여행 기록을 추가해보세요.', style: bodyText2),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _createTripRecordWithPhoto(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('일기 쓰기'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white),
                  )
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              await ref.refresh(tripRecordsProvider.future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 16, bottom: 80),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final TripRecord record = records[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                TripRecordDetailScreen(recordId: record.id)),
                      );
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: record.photoUrls.isNotEmpty
                              ? Image.network(
                            record.photoUrls.first,
                            fit: BoxFit.cover,
                            loadingBuilder:
                                (context, child, loadingProgress) =>
                            loadingProgress == null
                                ? child
                                : const Center(
                              child:
                              CircularProgressIndicator(
                                  strokeWidth: 2),
                            ),
                            errorBuilder:
                                (context, error, stackTrace) =>
                                Container(
                                  color: Colors.grey[200],
                                  child: const Icon(
                                      Icons.broken_image_outlined,
                                      color: Colors.grey),
                                ),
                          )
                              : Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.grey,
                              size: 40,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(record.title,
                                    style:
                                    heading2.copyWith(fontSize: 16),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('yyyy년 MM월 dd일 EEEE', 'ko_KR')
                                      .format(record.date),
                                  style: bodyText2.copyWith(fontSize: 12),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  record.content.isEmpty
                                      ? '(내용 없음)'
                                      : record.content,
                                  style: bodyText2,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('일기 목록 로딩 오류: $err')),
      ),
    );
  }
}

double? _convertDmsToDecimal(dynamic dmsValue, String ref) {
  try {
    List<String> parts;

    if (dmsValue is String) {
      parts = dmsValue.split(',');
    } else if (dmsValue is List) {
      parts = dmsValue.map((e) => e.toString()).toList();
    } else {
      debugPrint(
          '[_convertDmsToDecimal] Unknown DMS value type: ${dmsValue.runtimeType}');
      return null;
    }

    if (parts.length != 3) {
      debugPrint('[_convertDmsToDecimal] Invalid DMS parts length: $parts');
      return null;
    }

    List<double> dms = parts.map((part) {
      String cleanPart = part.trim();
      if (cleanPart.contains('/')) {
        List<String> div = cleanPart.split('/');
        if (div.length != 2) throw FormatException('Invalid DMS part: $cleanPart');
        double numerator = double.parse(div[0]);
        double denominator = double.parse(div[1]);
        if (denominator == 0) return 0.0;
        return numerator / denominator;
      } else {
        return double.parse(cleanPart);
      }
    }).toList();

    double decimal = dms[0] + (dms[1] / 60) + (dms[2] / 3600);

    if (ref == 'S' || ref == 'W') {
      decimal = -decimal;
    }
    return decimal;
  } catch (e) {
    debugPrint('Error converting DMS to decimal: $e (Input: $dmsValue)');
    return null;
  }
}
