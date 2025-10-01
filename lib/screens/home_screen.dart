import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:ar_memo_frontend/providers/trip_record_provider.dart';
import 'package:ar_memo_frontend/screens/create_trip_record_screen.dart';
import 'package:ar_memo_frontend/screens/trip_record_detail_screen.dart';
import 'package:ar_memo_frontend/theme/text_styles.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // 여행 기록 생성 다이얼로그 (image_6627c4.png)
  void _showCreateTripDialog(BuildContext context, WidgetRef ref) {
    // create_trip_record_screen.dart 를 재사용합니다.
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateTripRecordScreen()),
    ).then((value) {
      if (value == true) {
        ref.invalidate(tripRecordsProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripRecordsAsync = ref.watch(tripRecordsProvider);

    return Scaffold(
      body: Stack(
        children: [
          // 카카오맵 배경
          KakaoMap(
            center: LatLng(37.5665, 126.9780), // 초기 중심 좌표 (서울 시청)
          ),

          // 상단 검색 바
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: '위치 검색...',
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: () {},
                    mini: true,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.my_location, color: Colors.black54),
                  )
                ],
              ),
            ),
          ),

          // 우측 플로팅 버튼 (image_6627a8.png 참고)
          Positioned(
              top: 120,
              right: 16,
              child: Column(
                children: [
                  FloatingActionButton(
                    heroTag: 'add_fab',
                    onPressed: () => _showCreateTripDialog(context, ref),
                    mini: true,
                    backgroundColor: Colors.white,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Colors.black54),
                        Text("생성", style: TextStyle(color: Colors.black54, fontSize: 10))
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'camera_fab',
                    onPressed: () { /* TODO: AR 카메라 로직 연결 */ },
                    mini: true,
                    backgroundColor: Colors.white,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, color: Colors.black54),
                        Text("카메라", style: TextStyle(color: Colors.black54, fontSize: 10))
                      ],
                    ),
                  ),
                ],
              )
          ),

          // 하단 슬라이딩 패널
          DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.15,
            maxChildSize: 0.8,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10.0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 패널 핸들
                    Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    // "나의 기록" 타이틀
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Text('나의 기록', style: heading1),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // 여행 기록 리스트
                    Expanded(
                      child: tripRecordsAsync.when(
                        data: (records) {
                          if (records.isEmpty) {
                            return const Center(child: Text("기록이 없습니다."));
                          }
                          return ListView.builder(
                            controller: scrollController,
                            itemCount: records.length,
                            itemBuilder: (context, index) {
                              final record = records[index];
                              return ListTile(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TripRecordDetailScreen(recordId: record.id),
                                    ),
                                  );
                                },
                                leading: record.photoUrls.isNotEmpty
                                    ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.network(
                                    record.photoUrls.first,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                    : Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: const Icon(Icons.photo_camera, color: Colors.grey),
                                ),
                                title: Text(record.title, style: bodyText1.copyWith(fontWeight: FontWeight.bold)),
                                subtitle: Text(DateFormat('yyyy.MM.dd').format(record.date)),
                                trailing: record.group != null ? const Icon(Icons.group, size: 16, color: Colors.purple) : null,
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, stack) => Center(child: Text('Error: $err')),
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