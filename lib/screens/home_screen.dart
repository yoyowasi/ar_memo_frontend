import 'dart:io';
import 'package:ar_memo_frontend/models/trip_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:kakao_flutter_sdk_map/kakao_flutter_sdk_map.dart'; // 공식 SDK import
import 'package:ar_memo_frontend/providers/trip_record_provider.dart';
import 'package:ar_memo_frontend/providers/upload_provider.dart';
import 'package:ar_memo_frontend/screens/ar_viewer_screen.dart';
import 'package:ar_memo_frontend/screens/trip_record_detail_screen.dart';
import 'package:ar_memo_frontend/theme/colors.dart';
import 'package:ar_memo_frontend/theme/text_styles.dart';
import 'dart:math';

// KakaoMapController Provider 제거

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late MapController _mapController; // MapController 사용
  Set<Marker> _markers = {};
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // initState에서는 Provider를 직접 read하기 어려우므로
    // WidgetsBinding을 사용하여 첫 빌드 완료 후 마커 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) { // mounted 확인 추가
        _loadAndSetMarkers();
      }
    });
  }

  // 마커 로드 및 설정 로직
  Future<void> _loadAndSetMarkers() async {
    final recordsAsyncValue = ref.read(tripRecordsProvider);

    recordsAsyncValue.whenData((records) {
      final newMarkers = <Marker>{};
      for (final record in records) {
        double? lat, lng;
        bool hasLocation = false;
        String infoTitle = record.title; // InfoWindow 내용

        if (record.latitude != null && record.longitude != null) {
          lat = record.latitude!;
          lng = record.longitude!;
          hasLocation = true;
        } else {
          // 임시 위치
          lat = 37.5665 + (_random.nextDouble() * 0.01 - 0.005);
          lng = 126.9780 + (_random.nextDouble() * 0.01 - 0.005);
          infoTitle += " (위치 없음)"; // 위치 없을 때 표시
        }

        newMarkers.add(
          Marker(
            markerId: record.id,
            latLng: LatLng(lat, lng),
            // TODO: 커스텀 마커 이미지 적용 필요
            // markerImageSrc: 'assets/images/marker_pin.png', // 예시
            infoWindowContent: infoTitle, // InfoWindow 텍스트 설정
          ),
        );
      }
      if (mounted && _markers != newMarkers) {
        setState(() {
          _markers = newMarkers;
        });
      }
    });
  }

  /// 서버 URL 변환 함수
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

  /// 일기 생성 팝업
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
                  pickedFiles.forEach((file) => localFiles.remove(file));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('이미지 업로드 실패: $e')));
                }
              } finally {
                if (builderContext.mounted) setState(() => isUploading = false);
              }
            }
            Future<void> selectDate() async {
              final picked = await showDatePicker(
                context: builderContext, initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime(2000), lastDate: DateTime.now().add(const Duration(days: 1)),
              );
              if (picked != null && picked != selectedDate) setState(() => selectedDate = picked);
            }
            Future<void> submitRecord() async {
              if (titleController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('제목을 입력해주세요.'))); return;
              }
              if (selectedDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('날짜를 선택해주세요.'))); return;
              }
              setState(() => isLoading = true);
              double? currentLat;
              double? currentLng;
              if (mounted && this.mounted) {
                try {
                  final centerLatLng = await _mapController.getCenter();
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
                // 마커 갱신은 watch를 통해 처리
              } catch (e) {
                if (dialogContext.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
              } finally {
                if (dialogContext.mounted) setState(() => isLoading = false);
              }
            }

            // 팝업 UI
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.only(top: 24, bottom: 0),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              actionsPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              title: const Center(child: Text('일기 생성', style: heading2)),
              content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(height: 100, child: Row(children: [
                  AspectRatio(aspectRatio: 1, child: InkWell(onTap: isUploading ? null : pickAndUploadImage, child: Container(decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)), child: Center(child: isUploading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2,)) : const Icon(Icons.add_a_photo_outlined, color: subTextColor))))),
                  const SizedBox(width: 8),
                  Expanded(child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: localFiles.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (ctx, index) => SizedBox(width: 100, child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(localFiles[index].path), fit: BoxFit.cover))))),
                ],),
                ),
                const SizedBox(height: 16),
                TextField(controller: titleController, decoration: InputDecoration(labelText: '제목', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)), style: bodyText1),
                const SizedBox(height: 12),
                InkWell(onTap: selectDate, child: InputDecorator(decoration: InputDecoration(labelText: '날짜', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(selectedDate == null ? '날짜 선택' : DateFormat('yyyy. MM. dd').format(selectedDate!), style: bodyText1), const Icon(Icons.calendar_today_outlined, size: 20, color: subTextColor)]))),
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
    // Provider watch (동일)
    ref.watch(tripRecordsProvider).whenData((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadAndSetMarkers();
      });
    });

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: SpeedDial(
        icon: Icons.add, activeIcon: Icons.close,
        backgroundColor: primaryColor, foregroundColor: Colors.white,
        overlayColor: Colors.black, overlayOpacity: 0.4,
        spacing: 12, childrenButtonSize: const Size(56.0, 56.0),
        children: [
          SpeedDialChild(child: const Icon(Icons.article_outlined, color: primaryColor), backgroundColor: Colors.white, label: '일기 쓰기', labelStyle: bodyText1.copyWith(color: textColor), onTap: () => _showCreateTripPopup(context, ref)),
          SpeedDialChild(child: const Icon(Icons.view_in_ar_outlined, color: primaryColor), backgroundColor: Colors.white, label: 'AR 기록', labelStyle: bodyText1.copyWith(color: textColor), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ArViewerScreen()))),
        ],
      ),
      body: Stack(
        children: [
          // 카카오맵 위젯
          KakaoMap(
            onMapCreated: (controller) {
              _mapController = controller;
              // 컨트롤러가 준비되면 마커 로드
              _loadAndSetMarkers();
            },
            markers: _markers.toList(),
            onMarkerTap: (markerId, latLng, zoomLevel) {
              debugPrint('[onMarkerTap] markerId $markerId / $latLng');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TripRecordDetailScreen(recordId: markerId)),
              );
              // .then() 제거
            },
            center: LatLng(37.5665, 126.9780),
            currentLevel: 7,
            onMapTap: (latLng) {
              // InfoWindow 닫기 (새 SDK에서는 InfoWindow 탭 시 자동으로 닫힐 수 있음, 확인 필요)
              // _mapController.closeInfoWindow(); // 필요 시 사용
            },
          ),

          // 상단 검색 바
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))]), child: const TextField(decoration: InputDecoration(prefixIcon: Icon(Icons.search, color: subTextColor), hintText: '장소, 기록 검색...', hintStyle: TextStyle(color: subTextColor), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 14))))),
                  const SizedBox(width: 10),
                  FloatingActionButton(
                    onPressed: () async {
                      // TODO: geolocator 사용
                      final currentLatLng = LatLng(37.5665, 126.9780); // 임시
                      _mapController.setCenter(currentLatLng);
                      _mapController.setLevel(5);
                    },
                    mini: true, backgroundColor: Colors.white, elevation: 2,
                    child: const Icon(Icons.my_location, color: primaryColor),
                  )
                ],
              ),
            ),
          ),

          // 하단 슬라이딩 패널
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
                                margin: const EdgeInsets.symmetric(vertical: 6.0), elevation: 1.5,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () {
                                    // 지도 이동
                                    if (record.latitude != null && record.longitude != null) {
                                      final targetLatLng = LatLng(record.latitude!, record.longitude!);
                                      _mapController.setCenter(targetLatLng);
                                      _mapController.setLevel(5);
                                    }
                                    // 상세 화면 이동
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => TripRecordDetailScreen(recordId: record.id)));
                                  },
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(width: 80, height: 80, child: record.photoUrls.isNotEmpty
                                          ? Image.network(_toAbsoluteUrl(record.photoUrls.first), fit: BoxFit.cover, loadingBuilder: (context, child, loadingProgress) => loadingProgress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)), errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image_outlined, color: Colors.grey)))
                                          : Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey)),
                                      ),
                                      Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(record.title, style: bodyText1.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis), const SizedBox(height: 4),
                                        Text(DateFormat('yyyy.MM.dd').format(record.date), style: bodyText2), const SizedBox(height: 4),
                                        if (record.group != null) Row(children: [Icon(Icons.group, size: 14, color: Color(record.group!.colorValue)), const SizedBox(width: 4), Text(record.group!.name, style: bodyText2.copyWith(fontSize: 12, color: Color(record.group!.colorValue)), maxLines: 1, overflow: TextOverflow.ellipsis)]),
                                      ],),),
                                      ),
                                      const Padding(padding: EdgeInsets.only(right: 8.0), child: Icon(Icons.chevron_right, color: subTextColor)),
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