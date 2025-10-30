import 'dart:async';
import 'dart:io';
import 'package:ar_memo_frontend/models/trip_record.dart';
import 'package:flutter/material.dart';
import 'package:ar_memo_frontend/utils/url_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:ar_memo_frontend/providers/trip_record_provider.dart';
import 'package:ar_memo_frontend/providers/upload_provider.dart';
import 'package:ar_memo_frontend/screens/trip_record_detail_screen.dart';
import 'package:ar_memo_frontend/theme/colors.dart';
import 'package:ar_memo_frontend/theme/text_styles.dart';
import 'dart:math';

import 'package:kakao_map_sdk/kakao_map_sdk.dart';
import 'package:geolocator/geolocator.dart';
import 'package:native_exif/native_exif.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

enum RecordSortOrder {
  latest,
  oldest,
  title,
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  KakaoMapController? _mapController;
  final Random _random = Random();

  final Map<String, String> _markerInfoWindows = {};
  final Map<String, Poi> _pois = {};
  KImage? _poiIcon;

  String? _previouslySelectedMarkerId;
  final Map<String, KImage> _photoMarkerIcons = {};
  LatLng? _currentMapCenter;
  late final PageController _recordPageController;
  late final ValueNotifier<int> _currentRecordPageNotifier;
  RecordSortOrder _sortOrder = RecordSortOrder.latest;

  @override
  void initState() {
    super.initState();
    _recordPageController = PageController(viewportFraction: 0.88);
    _currentRecordPageNotifier = ValueNotifier<int>(0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // onMapReady에서 마커 로딩
      }
    });
  }

  @override
  void dispose() {
    _recordPageController.dispose();
    _currentRecordPageNotifier.dispose();
    super.dispose();
  }

  List<TripRecord> _sortRecords(List<TripRecord> records) {
    final sorted = List<TripRecord>.from(records);
    switch (_sortOrder) {
      case RecordSortOrder.latest:
        sorted.sort((a, b) => b.date.compareTo(a.date));
        break;
      case RecordSortOrder.oldest:
        sorted.sort((a, b) => a.date.compareTo(b.date));
        break;
      case RecordSortOrder.title:
        sorted.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }
    return sorted;
  }

  String get _sortOrderLabel {
    switch (_sortOrder) {
      case RecordSortOrder.latest:
        return '최신순';
      case RecordSortOrder.oldest:
        return '오래된순';
      case RecordSortOrder.title:
        return '제목순';
    }
  }

  Future<void> _showSortBottomSheet() async {
    final selected = await showModalBottomSheet<RecordSortOrder>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('최신순'),
                trailing: _sortOrder == RecordSortOrder.latest
                    ? const Icon(Icons.check, color: primaryColor)
                    : null,
                onTap: () => Navigator.of(context).pop(RecordSortOrder.latest),
              ),
              ListTile(
                title: const Text('오래된순'),
                trailing: _sortOrder == RecordSortOrder.oldest
                    ? const Icon(Icons.check, color: primaryColor)
                    : null,
                onTap: () => Navigator.of(context).pop(RecordSortOrder.oldest),
              ),
              ListTile(
                title: const Text('제목순'),
                trailing: _sortOrder == RecordSortOrder.title
                    ? const Icon(Icons.check, color: primaryColor)
                    : null,
                onTap: () => Navigator.of(context).pop(RecordSortOrder.title),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || selected == null || selected == _sortOrder) return;

    setState(() {
      _sortOrder = selected;
      _currentRecordPageNotifier.value = 0;
      if (_recordPageController.hasClients) {
        _recordPageController.jumpToPage(0);
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
    final c = _mapController;
    if (c == null) return;
    await Future.wait(_pois.values.map((poi) => c.labelLayer.removePoi(poi)));
    _pois.clear();
    _markerInfoWindows.clear();
    _previouslySelectedMarkerId = null;
    _photoMarkerIcons.clear();
  }

  Future<void> _loadAndSetMarkersFromProvider(List<TripRecord> records) async {
    final c = _mapController;
    if (c == null) return;

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

      final poi = await c.labelLayer.addPoi(
        LatLng(lat, lng),
        style: style,
        id: markerId,
        text: infoTitle,
        onClick: () => _onMarkerTapped(markerId),
      );

      _pois[markerId] = poi;
    }

    debugPrint("${(_pois.length)} pois prepared for map.");
  }

  Future<void> _onMarkerTapped(String recordId) async {
    final c = _mapController;
    if (c == null) return;

    if (_previouslySelectedMarkerId != null &&
        _previouslySelectedMarkerId != recordId) {
      final oldPoi = _pois[_previouslySelectedMarkerId];
      if (oldPoi != null) {
        final defaultStyle = PoiStyle(icon: _poiIcon);
        await c.labelLayer.removePoi(oldPoi);
        final newPoi = await c.labelLayer.addPoi(
          oldPoi.position,
          style: defaultStyle,
          id: oldPoi.id,
          text: oldPoi.text,
          onClick: () => _onMarkerTapped(oldPoi.id),
        );
        _pois[oldPoi.id] = newPoi;
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
        await c.labelLayer.removePoi(poiToUpdate);
        final newPoi = await c.labelLayer.addPoi(
          poiToUpdate.position,
          style: photoStyle,
          id: poiToUpdate.id,
          text: poiToUpdate.text,
          onClick: () => _onMarkerTapped(poiToUpdate.id),
        );
        _pois[poiToUpdate.id] = newPoi;
      }
    }

    setState(() {
      _previouslySelectedMarkerId = recordId;
    });
    debugPrint('Poi Tapped: $recordId');
  }

  Future<void> _moveToCurrentUserLocation() async {
    final c = _mapController;
    if (c == null) return;

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

      await c.moveCamera(
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

  Future<void> _refreshCenter() async {
    final c = _mapController;
    if (c == null) return;
    try {
      final cam = await c.getCameraPosition();
      _currentMapCenter = cam.position;
    } catch (_) {}
  }

  Future<void> _openTripRecord(TripRecord record) async {
    if (record.latitude != null && record.longitude != null) {
      final targetLatLng = LatLng(record.latitude!, record.longitude!);
      await _mapController?.moveCamera(
        CameraUpdate.newCenterPosition(targetLatLng),
        animation: CameraAnimation(500),
      );
      await _refreshCenter();
      await _onMarkerTapped(record.id);
    } else {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TripRecordDetailScreen(recordId: record.id),
        ),
      );
    }
  }

  Future<LatLng?> _latLngFromExifPath(String filePath) async {
    try {
      final exif = await Exif.fromPath(filePath);
      final coords = await exif.getLatLong();
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
    DateTime selectedDate = DateTime.now();
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

              LatLng? foundLocation = await _latLngFromExifPath(pickedFile.path);
              if (foundLocation != null) {
                debugPrint(
                    'EXIF GPS found: ${foundLocation.latitude}, ${foundLocation.longitude}');
              }

              if (foundLocation == null) {
                try {
                  LocationPermission permission =
                  await Geolocator.checkPermission();
                  if (permission == LocationPermission.denied) {
                    permission = await Geolocator.requestPermission();
                  }
                  if (permission == LocationPermission.always ||
                      permission == LocationPermission.whileInUse) {
                    final position = await Geolocator.getCurrentPosition();
                    foundLocation =
                        LatLng(position.latitude, position.longitude);
                    debugPrint(
                        'Fallback to device GPS: ${position.latitude}, ${position.longitude}');
                  }
                } catch (e) {
                  debugPrint('Device GPS failed: $e');
                }
              }

              if (foundLocation == null) {
                await _refreshCenter();
                if (_currentMapCenter != null) {
                  foundLocation = _currentMapCenter;
                  debugPrint(
                      'Fallback to map center: ${foundLocation!.latitude}, ${foundLocation.longitude}');
                }
              }

              foundLocation ??= const LatLng(37.5665, 126.9780);

              setState(() {
                tripLatitude = foundLocation!.latitude;
                tripLongitude = foundLocation.longitude;
              });

              if (builderContext.mounted) {
                try {
                  final repository = ref.read(uploadRepositoryProvider);
                  final result = await repository.uploadPhoto(pickedFile);
                  photoUrls.add(result.url);
                } catch (e) {
                  if (builderContext.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('사진 업로드 실패: $e')));
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

              debugPrint(
                  'DEBUG: Before addTripRecord - Lat: $tripLatitude, Lng: $tripLongitude');

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
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('일기가 저장되었습니다.')));
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('저장 실패: $e')));
                }
              } finally {
                if (mounted && dialogContext.mounted) {
                  setState(() => isLoading = false);
                }
              }
            }

            return AlertDialog(
              shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTripPopup(context, ref),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('일기 쓰기'),
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
                            onTap: _showSortBottomSheet,
                            child: Row(
                              children: [
                                Text(_sortOrderLabel, style: bodyText2),
                                const Icon(Icons.arrow_drop_down,
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

                          final sortedRecords = _sortRecords(records);

                          final currentIndex = _currentRecordPageNotifier.value;
                          final clampedIndex = currentIndex.clamp(0, sortedRecords.length - 1).toInt();
                          if (clampedIndex != currentIndex) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              if (_recordPageController.hasClients) {
                                _recordPageController.jumpToPage(clampedIndex);
                              }
                              _currentRecordPageNotifier.value = clampedIndex;
                            });
                          }

                          return ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.only(bottom: 24),
                            children: [
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 320,
                                child: PageView.builder(
                                  controller: _recordPageController,
                                  itemCount: sortedRecords.length,
                                  onPageChanged: (index) {
                                    _currentRecordPageNotifier.value = index;
                                  },
                                  itemBuilder: (context, index) {
                                    final record = sortedRecords[index];
                                    final horizontalPadding = index == 0
                                        ? 24.0
                                        : index == sortedRecords.length - 1
                                            ? 24.0
                                            : 12.0;
                                    return Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: horizontalPadding,
                                      ),
                                      child: _TripRecordSlideCard(
                                        record: record,
                                        onTap: () => _openTripRecord(record),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              ValueListenableBuilder<int>(
                                valueListenable: _currentRecordPageNotifier,
                                builder: (_, currentPage, __) {
                                  final safePage = sortedRecords.isEmpty
                                      ? 0
                                      : currentPage.clamp(0, sortedRecords.length - 1).toInt();
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(sortedRecords.length, (index) {
                                      final isActive = index == safePage;
                                      return AnimatedContainer(
                                        duration: const Duration(milliseconds: 250),
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        height: 8,
                                        width: isActive ? 18 : 8,
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? primaryColor
                                              : Colors.grey.shade300,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      );
                                    }),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                            ],
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

class _TripRecordSlideCard extends StatelessWidget {
  const _TripRecordSlideCard({
    required this.record,
    required this.onTap,
  });

  final TripRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final group = record.group;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: record.photoUrls.isNotEmpty
                    ? Image.network(
                        toAbsoluteUrl(record.photoUrls.first),
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          final expected = loadingProgress.expectedTotalBytes;
                          final loaded = loadingProgress.cumulativeBytesLoaded;
                          final progress = expected != null ? loaded / expected : null;
                          return Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: progress,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.grey,
                            size: 42,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.grey,
                            size: 42,
                          ),
                        ),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('yyyy.MM.dd').format(record.date),
                      style: bodyText2.copyWith(color: subTextColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      record.title,
                      style: bodyText1.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      record.content.isNotEmpty ? record.content : '내용이 없습니다.',
                      style: bodyText2.copyWith(height: 1.4),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          record.latitude != null && record.longitude != null
                              ? Icons.place
                              : Icons.notes,
                          size: 18,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            record.latitude != null && record.longitude != null
                                ? '지도에서 보기'
                                : '상세 정보 보기',
                            style: bodyText2.copyWith(color: primaryColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (group != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: record.groupColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              group.name,
                              style: bodyText2.copyWith(
                                fontSize: 12,
                                color: record.groupColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
