import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:ar_memo_frontend/providers/group_provider.dart';
import 'package:ar_memo_frontend/providers/memory_provider.dart';
import 'package:ar_memo_frontend/theme/colors.dart';
import 'package:ar_memo_frontend/theme/text_styles.dart';

class GroupDetailScreen extends ConsumerWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupDetailProvider(groupId));
    final memoriesAsync = ref.watch(groupMemoriesProvider(groupId));
    // JavaScript 키 초기화
    AuthRepository.initialize(appKey: 'd9a28c7813a47e45be144b0df7c27ccf');

    return Scaffold(
      body: Stack(
        children: [
          // 카카오맵 배경
          KakaoMap(
            center: LatLng(37.5665, 126.9780), // TODO: 그룹 메모 기반으로 중심 좌표 설정
          ),
          // 상단 앱 바
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              title: groupAsync.when(
                data: (group) => Text(group.name,
                    style: heading2.copyWith(
                        color: Colors.white,
                        shadows: const [Shadow(blurRadius: 2, color: Colors.black54)])),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const Text('오류', style: TextStyle(color: Colors.white)),
              ),
              actions: [
                IconButton(icon: const Icon(Icons.search), onPressed: () {}),
                IconButton(icon: const Icon(Icons.people_outline), onPressed: () {}),
                IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
              ],
            ),
          ),

          // 하단 슬라이딩 패널 (그룹의 기록)
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
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10.0)],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Expanded(
                      child: memoriesAsync.when(
                        data: (memories) {
                          if (memories.isEmpty) {
                            return const Center(child: Text("이 그룹에는 아직 기록이 없습니다."));
                          }
                          return ListView.builder(
                            controller: scrollController,
                            itemCount: memories.length,
                            itemBuilder: (context, index) {
                              final memory = memories[index];
                              return ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: (memory.thumbUrl?.isNotEmpty ?? false)
                                      ? Image.network(memory.thumbUrl!, width: 56, height: 56, fit: BoxFit.cover)
                                      : Container(width: 56, height: 56, color: mutedSurfaceColor, child: const Icon(Icons.image_not_supported, color: subTextColor)),
                                ),
                                title: Text(memory.text ?? '텍스트 없음'),
                                subtitle: Text('작성자: ${memory.userId}'), // TODO: 사용자 이름으로 변경
                                onTap: () {
                                  // TODO: 메모 상세 페이지로 이동
                                },
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, stack) => Center(child: Text('메모를 불러오는 데 실패했습니다.\n$err')),
                      ),
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
    );
  }
}