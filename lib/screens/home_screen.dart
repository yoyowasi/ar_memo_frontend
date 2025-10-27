import 'dart:io';
import 'package:ar_memo_frontend/models/trip_record.dart';
import 'package:ar_memo_frontend/services/api_service.dart';
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


class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  KakaoMapController? _mapController;
  final Random _random = Random();
  String? _selectedMarkerId;

  final Map<String, String> _markerInfoWindows = {};
  final Map<String, Poi> _pois = {};
  KImage? _poiIcon;

  // Photo marker cache and selection tracking
  String? _previouslySelectedMarkerId;
  final Map<String, KImage> _photoMarkerIcons = {};

  @override
  void initState() {
    super.initState();
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
                    color: Colors.black.withAlpha((255 * 0.3).round()), blurRadius: 5)
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
      _selectedMarkerId = recordId;
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
        animation: const CameraAnimation(500),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('현재 위치를 가져올 수 없습니다: $e')),
      );
    }
  }

  void _showCreateTripPopup(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    DateTime? selectedDate = DateTime.now();
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
              final XFile? pickedFile =
                  await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
              if (pickedFile == null || !builderContext.mounted) return;

              // ===== NEW DEBUGGING CHECKPOINT =====
              debugPrint("Image picked successfully. Proceeding to location search...");
              // ====================================

              setState(() {
                isProcessing = true;
                localFile = pickedFile; // Keep localFile set
                tripLatitude = null;
                tripLongitude = null;
                photoUrls.clear();
              });

              // --- Start Location Search (EXIF removed due to dependency issues) ---
              LatLng? foundLocation;
              String locationSource = "Unknown";

              // 1. Try Device GPS
              try {
                LocationPermission permission = await Geolocator.checkPermission();
                if (permission == LocationPermission.denied) {
                  permission = await Geolocator.requestPermission();
                }
                
                if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
                  final position = await Geolocator.getCurrentPosition();
                  foundLocation = LatLng(position.latitude, position.longitude);
                  locationSource = "Device GPS";
                } else {
                  debugPrint('Location permission was denied.');
                  if (builderContext.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('위치 권한이 없어 현재 지도 중앙을 사용합니다.')),
                    );
                  }
                }
              } catch (e) {
                debugPrint('Could not get device location. Error: $e');
              }

              // 2. Fallback to Map Center if GPS fails or is denied
              if (foundLocation == null && _mapController != null) {
                try {
                  // final cameraPosition = await _mapController!.getCameraPosition();
                  // foundLocation = cameraPosition.getPosition();
                  locationSource = "Map Center";
                  debugPrint('Falling back to map center.');
                } catch(e) {
                  debugPrint('Could not get map center. Error: $e');
                }
              }
              // --- End Location Search ---

              if (foundLocation != null) {
                debugPrint('Location found via $locationSource: ${foundLocation.latitude}, ${foundLocation.longitude}');
                setState(() {
                  tripLatitude = foundLocation!.latitude;
                  tripLongitude = foundLocation.longitude;
                });
              } else {
                 // Explicitly set Seoul City Hall coordinates if no location found
                 tripLatitude = 37.5665; // Seoul City Hall latitude
                 tripLongitude = 126.9780; // Seoul City Hall longitude
                 locationSource = "Default (Seoul City Hall)";
                 debugPrint('Could not determine any location. Using default: $tripLatitude, $tripLongitude');
                 if (builderContext.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('위치 정보를 가져오지 못하여 기본 위치(서울시청)를 사용합니다.')),
                    );
                  }
              }

              // After getting location, upload the photo
              if (builderContext.mounted) {
                try {
                  // ===== TEMPORARY DEBUGGING CODE =====
                  debugPrint("Attempting to fetch current user to test network...");
                  final apiService = ApiService(); // Use singleton instance
                  final response = await apiService.get('/auth/me');
                  debugPrint("Test request completed with status: ${response.statusCode}");
                  debugPrint("Test response body: ${response.body}");
                  // ===== END TEMPORARY DEBUGGING CODE =====

                  // final repository = ref.read(uploadRepositoryProvider);
                  // final result = await repository.uploadPhoto(pickedFile);
                  // photoUrls.add(result.url);
                } catch (e) {
                  if (builderContext.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('테스트 요청 실패: $e')));
                  }
                } finally {
                  if (builderContext.mounted) {
                    setState(() => isProcessing = false);
                  }
                }
              }
            }

            Future<void> selectDate() async {
              final picked = await showDatePicker(
                context: builderContext,
                initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now().add(const Duration(days: 1)),
              );
              if (picked != null && picked != selectedDate) {
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
              if (selectedDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('날짜를 선택해주세요.')),
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
                      date: selectedDate!,
                      photoUrls: photoUrls,
                      latitude: tripLatitude,
                      longitude: tripLongitude,
                    );
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('일기가 저장되었습니다.')));
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('저장 실패: $e')));
                }
              } finally {
                if (dialogContext.mounted) {
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
                                  image: localFile != null ? DecorationImage(image: FileImage(File(localFile!.path)), fit: BoxFit.cover) : null,
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
                                      : (localFile == null ? const Icon(
                                          Icons.add_a_photo_outlined,
                                          color: subTextColor,
                                        ) : null),
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
                              selectedDate == null
                                  ? '날짜 선택'
                                  : DateFormat('yyyy. MM. dd')
                                      .format(selectedDate!),
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
    final XFile? photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);

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
          if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
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
      next.whenData((records) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _mapController != null) {
            _loadAndSetMarkersFromProvider(records);
          }
        });
      });
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
            onMapReady: (controller) {
              _mapController = controller;
              debugPrint("Map controller is ready.");
              _moveToCurrentUserLocation();
              final records = ref.read(tripRecordsProvider).asData?.value;
              if (records != null) {
                _loadAndSetMarkersFromProvider(records);
              }
            },
            option: const KakaoMapOption(
              position: LatLng(37.5665, 126.9780),
              zoomLevel: 14,
            ),
          ),

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
                            color: Colors.black.withAlpha((255 * 0.1).round()),
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
                    onPressed: _moveToCurrentUserLocation,
                    mini: true,
                    backgroundColor: Colors.white,
                    elevation: 2,
                    child: const Icon(Icons.my_location, color: primaryColor),
                  )
                ],
              ),
            ),
          ),

          DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.15,
            maxChildSize: 0.8,
            builder: (BuildContext context,
                ScrollController scrollController) {
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
                      color: Colors.black.withAlpha((255 * 0.15).round()),
                      blurRadius: 12.0,
                      spreadRadius: 2.0,
                      offset: const Offset(0, -2),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.symmetric(vertical: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('나의 기록', style: heading2),
                          InkWell(
                            onTap: () {},
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
                                        animation:
                                        const CameraAnimation(500),
                                      );
                                      setState(
                                              () => _selectedMarkerId = record.id);
                                      ScaffoldMessenger.of(context)
                                          .hideCurrentSnackBar();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            _markerInfoWindows[record.id] ??
                                                '정보 없음',
                                          ),
                                          duration:
                                          const Duration(seconds: 3),
                                          action: SnackBarAction(
                                            label: '상세보기',
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      TripRecordDetailScreen(
                                                          recordId:
                                                          record.id),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    } else {
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
                                          loadingBuilder: (context,
                                              child,
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
                                                      color: record.groupColor ??
                                                          primaryColor,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      record.group!.name,
                                                      style: bodyText2.copyWith(
                                                        fontSize: 12,
                                                        color:
                                                        record.groupColor ??
                                                            primaryColor,
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
                              '기록 로딩 오류:\n$err',
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

class Group {
  final String id;
  final String name;
  Group({required this.id, required this.name});
}

extension TripRecordExtension on TripRecord {
  Color? get groupColor {
    if (group == null) return null;
    final hash = group!.name.hashCode;
    return Color((hash & 0x00FFFFFF) | 0xFF000000).withAlpha((255 * 0.8).round());
  }
}