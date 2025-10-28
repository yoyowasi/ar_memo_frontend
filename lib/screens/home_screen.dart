import 'dart:io';
import 'package:ar_memo_frontend/models/trip_record.dart';
// exif 패키지 제거
import 'package:flutter/material.dart';
import 'package:ar_memo_frontend/utils/url_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:ar_memo_frontend/providers/trip_record_provider.dart';
import 'package:ar_memo_frontend/providers/upload_provider.dart';
import 'package:ar_memo_frontend/screens/create_trip_record_screen.dart';
import 'package:ar_memo_frontend/screens/trip_record_detail_screen.dart';
import 'package:ar_memo_frontend/theme/colors.dart';
import 'package:ar_memo_frontend/theme/text_styles.dart';
import 'dart:math';

import 'package:kakao_map_sdk/kakao_map_sdk.dart';
import 'package:geolocator/geolocator.dart';
import 'package:native_exif/native_exif.dart'; // ✅ 교체: 네이티브 EXIF

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  KakaoMapController? _mapController;
  final Random _random = Random();

  final Map<String, String> _markerInfoWindows = {};
  final Map<String, Poi> _pois = {};
  KImage? _poiIcon;

  // Photo marker cache and selection tracking
  String? _previouslySelectedMarkerId;
  final Map<String, KImage> _photoMarkerIcons = {};
  LatLng? _currentMapCenter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // onMapReady에서 마커 로딩
      }
    });
  }

  Future<void> _preparePoiIcon() async {
    if (_poiIcon != null) return;
    _poiIcon = await KImage.fromWidget(
      const Icon(Icons.place, size: 28),
      const Size(36, 36),
    );
  }

  Future<void> _clearAllPois() async {
    if (_mapController == null) return;
    await Future.wait(_pois.values.map((poi) => _mapController!.labelLayer.removePoi(poi)));
    _pois.clear();
    _markerInfoWindows.clear();
    _previouslySelectedMarkerId = null;
    _photoMarkerIcons.clear();
  }

  Future<void> _loadAndSetMarkersFromProvider(List<TripRecord> records) async {
    if (_mapController == null) return;

    await _clearAllPois();
    await _preparePoiIcon();

    final style = PoiStyle(icon: _poiIcon!);

    for (final record in records) {
      double lat, lng;
      String infoTitle = record.title;

      if (record.latitude != null && record.longitude != null) {
        lat = record.latitude!;
        lng = record.longitude!;
      } else {
        lat = 37.5665 + (_random.nextDouble() * 0.01 - 0.005);
        lng = 126.9780 + (_random.nextDouble() * 0.01 - 0.005);
        infoTitle += " (위치 없음)";
      }

      final markerId = record.id;
      _markerInfoWindows[markerId] = infoTitle;

      final poi = await _mapController!.labelLayer.addPoi(
        LatLng(lat, lng),
        style: style,
        id: markerId,
        text: infoTitle,
        onClick: () => _onMarkerTapped(markerId),
      );

      _pois[markerId] = poi;
    }

    debugPrint("${_pois.length} pois prepared for map.");
  }

  Future<void> _onMarkerTapped(String recordId) async {
    if (_mapController == null) return;

    if (_previouslySelectedMarkerId != null &&
        _previouslySelectedMarkerId != recordId) {
      final oldPoi = _pois[_previouslySelectedMarkerId!];
      if (oldPoi != null) {
        final defaultStyle = PoiStyle(icon: _poiIcon!);
        await _mapController?.labelLayer.removePoi(oldPoi);
        final newPoi = await _mapController!.labelLayer.addPoi(
          oldPoi.position,
          style: defaultStyle,
          id: oldPoi.id,
          text: oldPoi.text,
          onClick: () => _onMarkerTapped(oldPoi.id!),
        );
        _pois[oldPoi.id!] = newPoi;
      }
    }

    final records = ref.read(tripRecordsProvider).asData?.value ?? [];
    final record = records.firstWhere((r) => r.id == recordId,
        orElse: () => throw Exception("Record not found for ID: $recordId"));

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_markerInfoWindows[recordId] ?? '정보 없음'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: '상세보기',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    TripRecordDetailScreen(recordId: recordId),
              ),
            );
          },
        ),
      ),
    );

    if (record.photoUrls.isNotEmpty) {
      KImage? photoIcon = _photoMarkerIcons[recordId];

      if (photoIcon == null) {
        photoIcon = await KImage.fromWidget(
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                  image: NetworkImage(toAbsoluteUrl(record.photoUrls.first)),
                  fit: BoxFit.cover),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.3), blurRadius: 5)
              ],
            ),
          ),
          const Size(70, 70),
        );
        _photoMarkerIcons[recordId] = photoIcon;
      }

      final poiToUpdate = _pois[recordId];
      if (poiToUpdate != null) {
        final photoStyle = PoiStyle(icon: photoIcon);
        await _mapController?.labelLayer.removePoi(poiToUpdate);
        final newPoi = await _mapController!.labelLayer.addPoi(
          poiToUpdate.position,
          style: photoStyle,
          id: poiToUpdate.id,
          text: poiToUpdate.text,
          onClick: () => _onMarkerTapped(poiToUpdate.id!),
        );
        _pois[poiToUpdate.id!] = newPoi;
      }
    }

    setState(() {
      _previouslySelectedMarkerId = recordId;
    });
    debugPrint('Poi Tapped: $recordId');
  }

  Future<void> _moveToCurrentUserLocation() async {
    if (_mapController == null) return;

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('위치 정보 권한이 필요합니다.')),
          );
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition();
      final currentLatLng = LatLng(position.latitude, position.longitude);

      await _mapController!.moveCamera(
        CameraUpdate.newCenterPosition(currentLatLng),
        animation: CameraAnimation(500),
      );
      _currentMapCenter = currentLatLng;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('현재 위치를 가져올 수 없습니다: $e')),
      );
    }
  }

  // ✅ 현재 카메라 중심을 SDK에서 읽어 _currentMapCenter에 반영
  Future<void> _refreshCenter() async {
    if (_mapController == null) return;
    try {
      final cam = await _mapController!.getCameraPosition();
      _currentMapCenter = cam.position; // kakao_map_sdk 1.2.x
    } catch (_) {
      // 무시
    }
  }

  // ✅ EXIF GPS를 네이티브로 읽기 (Android 10+는 ACCESS_MEDIA_LOCATION 권한 필요)
  Future<LatLng?> _latLngFromExifPath(String filePath) async {
    try {
      final exif = await Exif.fromPath(filePath);
      final coords = await exif.getLatLong(); // ExifLatLong?
      await exif.close();
      if (coords == null) return null;
      return LatLng(coords.latitude, coords.longitude);
    } catch (e) {
      debugPrint('native_exif read failed: $e');
      return null;
    }
  }

  void _showCreateTripPopup(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    DateTime selectedDate = DateTime.now(); // non-null 유지
    XFile? localFile;
    List<String> photoUrls = [];
    bool isProcessing = false;
    bool isLoading = false;
    double? tripLatitude;
    double? tripLongitude;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setState) {
            Future<void> pickImageAndSetLocation() async {
              final picker = ImagePicker();

              // 재인코딩 금지: imageQuality 옵션 제거 (EXIF 보존)
              final XFile? pickedFile =
              await picker.pickImage(source: ImageSource.gallery);
              if (pickedFile == null || !builderContext.mounted) return;

              debugPrint("Image picked. Trying EXIF(native) first...");
              setState(() {
                isProcessing = true;
                localFile = pickedFile;
                tripLatitude = null;
                tripLongitude = null;
                photoUrls.clear();
              });

              // 1) ✅ 사진 EXIF에서 위도/경도 추출 (native_exif)
              LatLng? foundLocation = await _latLngFromExifPath(pickedFile.path);
              if (foundLocation != null) {
                debugPrint('EXIF GPS found: ${foundLocation.latitude}, ${foundLocation.longitude}');
              }

              // 2) 폴백: 기기 현재 위치
              if (foundLocation == null) {
                try {
                  LocationPermission permission = await Geolocator.checkPermission();
                  if (permission == LocationPermission.denied) {
                    permission = await Geolocator.requestPermission();
                  }
                  if (permission == LocationPermission.always ||
                      permission == LocationPermission.whileInUse) {
                    final position = await Geolocator.getCurrentPosition();
                    foundLocation = LatLng(position.latitude, position.longitude);
                    debugPrint('Fallback to device GPS: ${position.latitude}, ${position.longitude}');
                  }
                } catch (e) {
                  debugPrint('Device GPS failed: $e');
                }
              }

              // 3) 폴백: 지도 중심 (최신 중심값 보정)
              if (foundLocation == null) {
                await _refreshCenter();
                if (_currentMapCenter != null) {
                  foundLocation = _currentMapCenter;
                  debugPrint('Fallback to map center: ${foundLocation!.latitude}, ${foundLocation.longitude}');
                }
              }

              // 4) 폴백: 서울시청
              foundLocation ??= const LatLng(37.5665, 126.9780);

              setState(() {
                tripLatitude = foundLocation!.latitude;
                tripLongitude = foundLocation.longitude;
              });

              // 업로드
              if (builderContext.mounted) {
                try {
                  final repository = ref.read(uploadRepositoryProvider);
                  final result = await repository.uploadPhoto(pickedFile);
                  photoUrls.add(result.url);
                } catch (e) {
                  if (builderContext.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('사진 업로드 실패: $e')));
                  }
                } finally {
                  if (builderContext.mounted) setState(() => isProcessing = false);
                }
              }
            }

            Future<void> selectDate() async {
              final picked = await showDatePicker(
                context: builderContext,
                initialDate: selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now().add(const Duration(days: 1)),
              );
              if (picked != null) {
                setState(() => selectedDate = picked);
              }
            }

            Future<void> submitRecord() async {
              if (titleController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('제목을 입력해주세요.')),
                );
                return;
              }
              if (photoUrls.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('사진이 업로드되지 않았습니다.')),
                );
                return;
              }

              setState(() => isLoading = true);

              debugPrint('DEBUG: Before addTripRecord - Lat: $tripLatitude, Lng: $tripLongitude');

              try {
                await ref.read(tripRecordsProvider.notifier).addTripRecord(
                  title: titleController.text,
                  content: contentController.text,
                  date: selectedDate,
                  photoUrls: photoUrls,
                  latitude: tripLatitude,
                  longitude: tripLongitude,
                );
                if (mounted) Navigator.pop(dialogContext);
                if (mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('일기가 저장되었습니다.')));
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('저장 실패: $e')));
                }
              } finally {
                if (mounted && dialogContext.mounted) {
                  setState(() => isLoading = false);
                }
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.only(top: 24, bottom: 0),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              actionsPadding:
              const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              title: const Center(child: Text('일기 생성', style: heading2)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 100,
                      child: Row(
                        children: [
                          AspectRatio(
                            aspectRatio: 1,
                            child: InkWell(
                              onTap: isProcessing ? null : pickImageAndSetLocation,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                  image: localFile != null
                                      ? DecorationImage(
                                      image: FileImage(File(localFile!.path)),
                                      fit: BoxFit.cover)
                                      : null,
                                ),
                                child: Center(
                                  child: isProcessing
                                      ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                      : (localFile == null
                                      ? const Icon(
                                    Icons.add_a_photo_outlined,
                                    color: subTextColor,
                                  )
                                      : null),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: '제목',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      style: bodyText1,
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: selectDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: '날짜',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('yyyy. MM. dd').format(selectedDate),
                              style: bodyText1,
                            ),
                            const Icon(Icons.calendar_today_outlined,
                                size: 20, color: subTextColor),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contentController,
                      decoration: InputDecoration(
                        labelText: '내용 (선택)',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                      style: bodyText1,
                    ),
                  ],
                ),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: <Widget>[
                TextButton(
                  child: const Text('취소', style: TextStyle(color: subTextColor)),
                  onPressed: () => Navigator.pop(dialogContext),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isLoading ? null : submitRecord,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                  child: isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('저장하기'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleArRecordCreation() async {
    final picker = ImagePicker();
    // imageQuality 옵션을 주면 재인코딩되면서 EXIF GPS가 제거되므로 그대로 사용한다.
    final XFile? photo =
        await picker.pickImage(source: ImageSource.camera);

    if (photo == null || !mounted) return;

    final bool? usePhoto = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('사진 사용'),
        content: Image.file(File(photo.path)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('다시 찍기'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('이 사진 사용'),
          ),
        ],
      ),
    );

    if (usePhoto == true && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied ||
              permission == LocationPermission.deniedForever) {
            throw Exception('위치 정보 권한이 거부되었습니다.');
          }
        }
        final position = await Geolocator.getCurrentPosition();

        final repository = ref.read(uploadRepositoryProvider);
        final result = await repository.uploadPhoto(photo);
        final newUrl = result.url;

        if (!mounted) return;
        Navigator.of(context).pop();

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CreateTripRecordScreen(
              initialPhotoUrls: [newUrl],
              initialLatitude: position.latitude,
              initialLongitude: position.longitude,
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(tripRecordsProvider, (_, next) {
      if (next is AsyncData<List<TripRecord>>) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _mapController != null) {
            _loadAndSetMarkersFromProvider(next.value);
          }
        });
      }
    });

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        overlayColor: Colors.black,
        overlayOpacity: 0.4,
        spacing: 12,
        childrenButtonSize: const Size(56.0, 56.0),
        children: [
          SpeedDialChild(
            child: const Icon(Icons.article_outlined, color: primaryColor),
            backgroundColor: Colors.white,
            label: '일기 쓰기',
            labelStyle: bodyText1.copyWith(color: textColor),
            onTap: () => _showCreateTripPopup(context, ref),
          ),
          SpeedDialChild(
            child: const Icon(Icons.view_in_ar_outlined, color: primaryColor),
            backgroundColor: Colors.white,
            label: 'AR 기록',
            labelStyle: bodyText1.copyWith(color: textColor),
            onTap: _handleArRecordCreation,
          ),
        ],
      ),
      body: Stack(
        children: [
          KakaoMap(
            onMapReady: (controller) async {
              _mapController = controller;
              _currentMapCenter = const LatLng(37.5665, 126.9780);
              debugPrint("Map controller is ready.");
              await _moveToCurrentUserLocation();
              final records = ref.read(tripRecordsProvider).asData?.value;
              if (records != null) {
                _loadAndSetMarkersFromProvider(records);
              }
            },
            // onCameraIdle 미지원 → 필요 시 버튼/제스처 후 _refreshCenter 호출로 보정
            option: const KakaoMapOption(
              position: LatLng(37.5665, 126.9780),
              zoomLevel: 14,
            ),
          ),

          // 상단 검색 바
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          prefixIcon:
                          Icon(Icons.search, color: subTextColor),
                          hintText: '장소, 기록 검색...',
                          hintStyle: TextStyle(color: subTextColor),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FloatingActionButton(
                    onPressed: () async {
                      await _moveToCurrentUserLocation();
                      await _refreshCenter();
                    },
                    mini: true,
                    backgroundColor: Colors.white,
                    elevation: 2,
                    child: const Icon(Icons.my_location, color: primaryColor),
                  )
                ],
              ),
            ),
          ),

          // 하단 슬라이딩 패널
          DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.15,
            maxChildSize: 0.8,
            builder: (BuildContext context, ScrollController scrollController) {
              final recordsAsync = ref.watch(tripRecordsProvider);
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12.0,
                      spreadRadius: 2.0,
                      offset: const Offset(0, -2),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    // 핸들 UI
                    Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.symmetric(vertical: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    // "나의 기록" 타이틀 및 정렬 버튼
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('나의 기록', style: heading2),
                          InkWell(
                            onTap: () {
                              /* TODO: 필터/정렬 */
                            },
                            child: const Row(
                              children: [
                                Text('최신순', style: bodyText2),
                                Icon(Icons.arrow_drop_down,
                                    color: subTextColor),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 기록 목록 또는 빈 상태 UI
                    Expanded(
                      child: recordsAsync.when(
                        data: (records) {
                          if (records.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.map_outlined,
                                      size: 48, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  const Text("기록된 추억이 없습니다.",
                                      style: bodyText1),
                                  const SizedBox(height: 4),
                                  const Text("지도에 나만의 기록을 추가해보세요.",
                                      style: bodyText2),
                                ],
                              ),
                            );
                          }
                          return ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.only(
                                left: 16, right: 16, bottom: 16),
                            itemCount: records.length,
                            itemBuilder: (context, index) {
                              final TripRecord record = records[index];
                              return Card(
                                margin: EdgeInsets.only(
                                  top: index == 0 ? 8.0 : 6.0,
                                  bottom: 6.0,
                                ),
                                elevation: 1.5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () async {
                                    if (record.latitude != null &&
                                        record.longitude != null) {
                                      final targetLatLng = LatLng(
                                        record.latitude!,
                                        record.longitude!,
                                      );
                                      await _mapController?.moveCamera(
                                        CameraUpdate.newCenterPosition(
                                            targetLatLng),
                                        animation: CameraAnimation(500),
                                      );
                                      await _refreshCenter();
                                      _onMarkerTapped(record.id);
                                    } else {
                                      // 위치 정보 없을 시 상세 화면만 이동
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              TripRecordDetailScreen(
                                                  recordId: record.id),
                                        ),
                                      );
                                    }
                                  },
                                  child: Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 80,
                                        height: 80,
                                        child: record.photoUrls.isNotEmpty
                                            ? Image.network(
                                          toAbsoluteUrl(
                                              record.photoUrls.first),
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child,
                                              loadingProgress) =>
                                          loadingProgress == null
                                              ? child
                                              : Center(
                                            child:
                                            CircularProgressIndicator(
                                              strokeWidth: 2,
                                              value: loadingProgress
                                                  .expectedTotalBytes !=
                                                  null
                                                  ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                                  : null,
                                            ),
                                          ),
                                          errorBuilder: (context, error,
                                              stackTrace) =>
                                              Container(
                                                color: Colors.grey[200],
                                                child: const Icon(
                                                  Icons
                                                      .broken_image_outlined,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                        )
                                            : Container(
                                          color: Colors.grey[200],
                                          child: const Icon(
                                            Icons
                                                .image_not_supported_outlined,
                                            color: Colors.grey,
                                            size: 32,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12.0, vertical: 8.0),
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                record.title,
                                                style: bodyText1.copyWith(
                                                    fontWeight:
                                                    FontWeight.w600),
                                                maxLines: 1,
                                                overflow:
                                                TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                DateFormat('yyyy.MM.dd')
                                                    .format(record.date),
                                                style: bodyText2,
                                              ),
                                              const SizedBox(height: 4),
                                              if (record.group != null)
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.group,
                                                      size: 14,
                                                      color: record.groupColor,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      record.group!.name,
                                                      style: bodyText2.copyWith(
                                                        fontSize: 12,
                                                        color:
                                                        record.groupColor,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        child: Icon(Icons.chevron_right,
                                            color: subTextColor),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        loading: () =>
                        const Center(child: CircularProgressIndicator()),
                        error: (err, stack) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              '''기록 로딩 오류:
$err''',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Group 모델 (임시 - 실제 모델 import 필요)
class Group {
  final String id;
  final String name;
  Group({required this.id, required this.name});
}

