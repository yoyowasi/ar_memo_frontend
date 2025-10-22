import 'dart:async'; // Completer 사용 위해 추가
import 'dart:io'; // Image.file 사용 위해 추가
import 'package:ar_memo_frontend/models/trip_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; // DateFormat 사용 위해 주석 해제
import 'package:ar_memo_frontend/providers/trip_record_provider.dart';
import 'package:ar_memo_frontend/providers/upload_provider.dart';
import 'package:ar_memo_frontend/screens/ar_viewer_screen.dart';
import 'package:ar_memo_frontend/screens/trip_record_detail_screen.dart';
import 'package:ar_memo_frontend/theme/colors.dart';
import 'package:ar_memo_frontend/theme/text_styles.dart';
import 'dart:math';

import 'package:kakao_map_sdk/kakao_map_sdk.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // KakaoMapController는 ^1.2.1 버전에 없음 -> Completer로 대체하여 비동기 처리
  final Completer<KakaoMapController> _controllerCompleter = Completer();
  // KakaoMapController 타입 대신 dynamic 또는 KakaoMapController (의존성 추가 후) 사용 고려
  KakaoMapController? _mapController; // 실제 컨트롤러 인스턴스 저장용

  Set<Marker> _markers = {}; // Marker 타입 사용
  final Random _random = Random();
  String? _selectedMarkerId;

  // 마커 ID와 InfoWindow 텍스트 매핑
  final Map<String, String> _markerInfoWindows = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadAndSetMarkersFromProvider(); // 초기 데이터 로드 시도
      }
    });
  }

  // Provider로부터 데이터를 읽어와 마커 설정 (^1.2.1 API 기준)
  Future<void> _loadAndSetMarkersFromProvider() async {
    final recordsAsyncValue = ref.read(tripRecordsProvider);

    recordsAsyncValue.whenData((records) {
      final newMarkers = <Marker>{}; // Set<Marker> 타입 사용
      _markerInfoWindows.clear();

      for (final record in records) {
        double? lat, lng;
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
        // Marker 클래스 생성자 사용
        newMarkers.add(
          Marker(
            markerId: markerId,
            latLng: LatLng(lat, lng),
            // ^1.2.1 마커 생성자 옵션 확인 필요
          ),
        );
        _markerInfoWindows[markerId] = infoTitle;
      }

      // 마커 상태 업데이트 -> KakaoMap 위젯이 rebuild 되면서 반영됨
      if (mounted) {
        setState(() {
          _markers = newMarkers;
        });
        debugPrint("${newMarkers.length} markers prepared for map.");
      }
    });
  }

  /// 서버 URL 변환 함수 (변경 없음)
  String _toAbsoluteUrl(String relativeUrl) {
    if (relativeUrl.startsWith('http')) return relativeUrl;
    final rawBaseUrl = dotenv.env['API_BASE_URL'];
    if (rawBaseUrl == null || rawBaseUrl.isEmpty) {
      debugPrint("Warning: API_BASE_URL is not set in .env file.");
      return relativeUrl;
    }
    final baseUrl = rawBaseUrl.endsWith('/')
        ? rawBaseUrl.substring(0, rawBaseUrl.length - 1)
        : rawBaseUrl;
    return '$baseUrl$relativeUrl';
  }

  /// 일기 생성 팝업 (^1.2.1 getCenter 사용)
  void _showCreateTripPopup(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    DateTime? selectedDate = DateTime.now();
    List<XFile> localFiles = [];
    List<String> photoUrls = [];
    bool isUploading = false;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setState) {
            // pickAndUploadImage 함수
            Future<void> pickAndUploadImage() async {
              final picker = ImagePicker();
              final List<XFile> pickedFiles = await picker.pickMultiImage(imageQuality: 85);
              if (pickedFiles.isEmpty || !builderContext.mounted) return;
              setState(() { isUploading = true; localFiles.addAll(pickedFiles); });
              try {
                final repository = ref.read(uploadRepositoryProvider);
                final results = await Future.wait(pickedFiles.map((file) => repository.uploadPhoto(file)));
                photoUrls.addAll(results.map((result) => result.url));
              } catch (e) {
                if (builderContext.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('이미지 업로드 실패: $e')));
                  localFiles.removeWhere((lf) => pickedFiles.any((pf) => pf.path == lf.path));
                }
              } finally {
                if (builderContext.mounted) setState(() => isUploading = false);
              }
            }
            // selectDate 함수
            Future<void> selectDate() async {
              final picked = await showDatePicker(
                context: builderContext, initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime(2000), lastDate: DateTime.now().add(const Duration(days: 1)),
              );
              if (picked != null && picked != selectedDate) setState(() => selectedDate = picked);
            }
            // submitRecord 함수 (^1.2.1 getCenter 사용)
            Future<void> submitRecord() async {
              if (titleController.text.isEmpty) { /* ... */ }
              if (selectedDate == null) { /* ... */ }
              setState(() => isLoading = true);
              double? currentLat;
              double? currentLng;

              // 컨트롤러가 준비되었는지 확인 후 getCenter 호출
              if (_mapController != null) {
                try {
                  // ^1.2.1 에서는 getCenter 가 Future 가 아닐 수 있음 (문서 확인 필요)
                  // final centerLatLng = await _mapController!.getCenter(); // Future 인 경우
                  final centerLatLng = _mapController!.getCenter(); // Future 가 아닌 경우
                  currentLat = centerLatLng.latitude;
                  currentLng = centerLatLng.longitude;
                } catch (e) { debugPrint("지도 중심 좌표 가져오기 실패: $e"); }
              }

              try {
                await ref.read(tripRecordsProvider.notifier).addTripRecord(
                  title: titleController.text, content: contentController.text,
                  date: selectedDate!, photoUrls: photoUrls,
                  latitude: currentLat, longitude: currentLng,
                );
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('일기가 저장되었습니다.')));
              } catch (e) {
                if (dialogContext.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
              } finally {
                if (dialogContext.mounted && mounted) setState(() => isLoading = false);
              }
            }

            // 팝업 UI
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.only(top: 24, bottom: 0),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              actionsPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              title: const Center(child: Text('일기 생성', style: heading2)), // heading2 사용 (text_styles.dart import 필요)
              content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(height: 100, child: Row(children: [
                  AspectRatio(aspectRatio: 1, child: InkWell(onTap: isUploading ? null : pickAndUploadImage, child: Container(decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)), child: Center(child: isUploading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2,)) : const Icon(Icons.add_a_photo_outlined, color: subTextColor))))),
                  const SizedBox(width: 8),
                  Expanded(child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: localFiles.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (ctx, index) => SizedBox(width: 100, child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(localFiles[index].path), fit: BoxFit.cover))))), // Image.file 사용 위해 dart:io import 필요
                ],),
                ),
                const SizedBox(height: 16),
                TextField(controller: titleController, decoration: InputDecoration(labelText: '제목', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)), style: bodyText1), // bodyText1 사용
                const SizedBox(height: 12),
                InkWell(onTap: selectDate, child: InputDecorator(decoration: InputDecoration(labelText: '날짜', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(selectedDate == null ? '날짜 선택' : DateFormat('yyyy. MM. dd').format(selectedDate!), style: bodyText1), const Icon(Icons.calendar_today_outlined, size: 20, color: subTextColor)]))), // DateFormat 사용
                const SizedBox(height: 12),
                TextField(controller: contentController, decoration: InputDecoration(labelText: '내용 (선택)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), alignLabelWithHint: true), maxLines: 3, style: bodyText1),
              ],),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: <Widget>[
                TextButton(child: const Text('취소', style: TextStyle(color: subTextColor)), onPressed: () => Navigator.pop(dialogContext)),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: isLoading ? null : submitRecord, style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 24)), child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white,)) : const Text('저장하기')),
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
      if (next is AsyncData) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _loadAndSetMarkersFromProvider();
          }
        });
      }
    });

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: SpeedDial(
        icon: Icons.add, activeIcon: Icons.close,
        backgroundColor: primaryColor, foregroundColor: Colors.white,
        overlayColor: Colors.black, overlayOpacity: 0.4,
        spacing: 12, childrenButtonSize: const Size(56.0, 56.0),
        children: [
          SpeedDialChild(
              child: const Icon(Icons.article_outlined, color: primaryColor),
              backgroundColor: Colors.white,
              label: '일기 쓰기',
              labelStyle: bodyText1.copyWith(color: textColor),
              onTap: () => _showCreateTripPopup(context, ref)
          ),
          SpeedDialChild(
              child: const Icon(Icons.view_in_ar_outlined, color: primaryColor),
              backgroundColor: Colors.white,
              label: 'AR 기록',
              labelStyle: bodyText1.copyWith(color: textColor),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ArViewerScreen()))
          ),
        ],
      ),
      body: Stack(
        children: [
          // KakaoMap 위젯 (^1.2.1 API 기준)
          KakaoMap(
            // onMapReady -> onMapCreated
            onMapCreated: (controller) async {
              // Completer 또는 직접 인스턴스 저장
              _mapController = controller;
              // _controllerCompleter.complete(controller); // Completer 사용 시
              debugPrint("Map controller is created.");
              // 컨트롤러 준비 후 마커 로드
              _loadAndSetMarkersFromProvider();
            },
            // initialCenter -> center
            center: LatLng(37.5665, 126.9780),
            // initialLevel -> currentLevel
            currentLevel: 7,
            // markers 파라미터에 상태(_markers) 전달
            markers: _markers.toList(),

            // onMarkerTap -> onMarkerTap (파라미터 타입 확인 필요, ^1.2.1은 markerId만 전달할 수 있음)
            onMarkerTap: (String markerId, LatLng latLng, int zoomLevel) { // ^1.2.1 파라미터에 맞춤
              setState(() {
                _selectedMarkerId = markerId;
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  // SnackBar 위젯 인자 전달
                  SnackBar(
                    content: Text(_markerInfoWindows[markerId] ?? '정보 없음'),
                    duration: const Duration(seconds: 3),
                    action: SnackBarAction(
                      label: '상세보기',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => TripRecordDetailScreen(recordId: markerId)),
                        );
                      },
                    ),
                  ),
                );
              });
              debugPrint('Marker Tapped: $markerId at $latLng');
            },
            // onMapTap 은 동일
            onMapTap: (LatLng latLng) { // 파라미터 타입 명시
              if (_selectedMarkerId != null) {
                setState(() {
                  _selectedMarkerId = null;
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  debugPrint('Map Tapped, deselected marker');
                });
              }
            },
            // ^1.2.1 에 onCustomMarkerTap 없음
          ),

          // 상단 검색 바 (CameraUpdate 수정)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))]), child: const TextField(decoration: InputDecoration(prefixIcon: Icon(Icons.search, color: subTextColor), hintText: '장소, 기록 검색...', hintStyle: TextStyle(color: subTextColor), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 14))))),
                  const SizedBox(width: 10),
                  FloatingActionButton(
                    onPressed: () async {
                      // TODO: geolocator
                      final currentLatLng = LatLng(37.5665, 126.9780);
                      // moveCamera 와 CameraUpdate.newCameraPosition 사용
                      _mapController?.moveCamera(
                        CameraUpdate.newCameraPosition( // newCameraPosition 사용
                            CameraPosition(target: currentLatLng, zoom: 5) // CameraPosition 생성자 사용
                        ),
                        // ^1.2.1 moveCamera 에는 animation 파라미터 없음
                        // animation: MapAnimation(duration: 300), // 제거
                      );
                    },
                    mini: true, backgroundColor: Colors.white, elevation: 2,
                    child: const Icon(Icons.my_location, color: primaryColor),
                  )
                ],
              ),
            ),
          ),

          // 하단 슬라이딩 패널 (CameraUpdate 수정)
          DraggableScrollableSheet(
            initialChildSize: 0.3, minChildSize: 0.15, maxChildSize: 0.8,
            builder: (BuildContext context, ScrollController scrollController) {
              final recordsAsync = ref.watch(tripRecordsProvider);
              return Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12.0, spreadRadius: 2.0, offset: const Offset(0, -2))]),
                child: Column(
                  children: [
                    Container(width: 50, height: 5, margin: const EdgeInsets.symmetric(vertical: 12.0), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 20.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('나의 기록', style: heading2),
                      InkWell(onTap: () { /* TODO: 필터/정렬 */ }, child: const Row(children: [Text('최신순', style: bodyText2), Icon(Icons.arrow_drop_down, color: subTextColor)]))
                    ],),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: recordsAsync.when(
                        data: (records) {
                          if (records.isEmpty) {
                            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.map_outlined, size: 48, color: Colors.grey[400]), const SizedBox(height: 16),
                              const Text("기록된 추억이 없습니다.", style: bodyText1), const SizedBox(height: 4),
                              const Text("지도에 나만의 기록을 추가해보세요.", style: bodyText2),
                            ],));
                          }
                          return ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                            itemCount: records.length,
                            itemBuilder: (context, index) {
                              final TripRecord record = records[index];
                              return Card(
                                margin: EdgeInsets.only(top: index == 0 ? 8.0 : 6.0, bottom: 6.0),
                                elevation: 1.5,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () {
                                    if (record.latitude != null && record.longitude != null) {
                                      final targetLatLng = LatLng(record.latitude!, record.longitude!);
                                      // moveCamera 와 CameraUpdate.newCameraPosition 사용
                                      _mapController?.moveCamera(
                                        CameraUpdate.newCameraPosition( // newCameraPosition 사용
                                            CameraPosition(target: targetLatLng, zoom: 5) // CameraPosition 생성자 사용
                                        ),
                                        // ^1.2.1 moveCamera 에는 animation 파라미터 없음
                                        // animation: MapAnimation(duration: 300), // 제거
                                      );
                                      // 마커 선택 및 스낵바 표시
                                      setState(() => _selectedMarkerId = record.id);
                                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar( // SnackBar 인자 전달
                                          content: Text(_markerInfoWindows[record.id] ?? '정보 없음'),
                                          duration: const Duration(seconds: 3),
                                          action: SnackBarAction(
                                            label: '상세보기',
                                            onPressed: () {
                                              Navigator.push(context, MaterialPageRoute(builder: (context) => TripRecordDetailScreen(recordId: record.id)));
                                            },
                                          ),
                                        ),
                                      );
                                    } else {
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => TripRecordDetailScreen(recordId: record.id)));
                                    }
                                  },
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(width: 80, height: 80, child: record.photoUrls.isNotEmpty
                                          ? Image.network(_toAbsoluteUrl(record.photoUrls.first), fit: BoxFit.cover, loadingBuilder: (context, child, loadingProgress) => loadingProgress == null ? child : Center(child: CircularProgressIndicator(strokeWidth: 2, value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null)), errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image_outlined, color: Colors.grey)))
                                          : Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 32)),
                                      ),
                                      Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(record.title, style: bodyText1.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis), const SizedBox(height: 4),
                                          Text(DateFormat('yyyy.MM.dd').format(record.date), style: bodyText2), const SizedBox(height: 4), // DateFormat 사용
                                          if (record.group != null) Row(children: [Icon(Icons.group, size: 14, color: record.groupColor ?? primaryColor), const SizedBox(width: 4), Text(record.group!.name, style: bodyText2.copyWith(fontSize: 12, color: record.groupColor ?? primaryColor), maxLines: 1, overflow: TextOverflow.ellipsis)]),
                                        ],),),
                                      ),
                                      const Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Icon(Icons.chevron_right, color: subTextColor)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, stack) => Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text('기록 로딩 오류:\n$err', textAlign: TextAlign.center))),
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