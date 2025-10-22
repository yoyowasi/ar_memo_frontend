import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // dotenv import
import 'package:flutter_riverpod/flutter_riverpod.dart';
// kakao_map_sdk import 불필요
// import 'package:kakao_map_sdk/kakao_map_sdk.dart' as kakao_map_sdk; // Alias for clarity

import 'package:ar_memo_frontend/providers/group_provider.dart';
import 'package:ar_memo_frontend/providers/memory_provider.dart';
import 'package:ar_memo_frontend/theme/colors.dart';
import 'package:ar_memo_frontend/theme/text_styles.dart';

class GroupDetailScreen extends ConsumerWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  // --- _toAbsoluteUrl 헬퍼 함수 추가 (Image.network용) ---
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
  // ------------------------------------------------

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupDetailProvider(groupId));
    final memoriesAsync = ref.watch(groupMemoriesProvider(groupId));

    return Scaffold(
      // AppBar 배경색 및 아이콘 색상 조정
      appBar: AppBar(
        iconTheme: const IconThemeData(color: textColor), // 기본 아이콘 색상
        backgroundColor: Colors.white, // 흰색 배경
        elevation: 1, // 구분선
        title: groupAsync.when(
          data: (group) => Text(group.name, style: heading2),
          loading: () => const Text('그룹 정보 로딩 중...', style: heading2),
          error: (_, __) => const Text('오류', style: heading2),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(
              icon: const Icon(Icons.people_outline), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      // Stack 제거하고 바로 DraggableScrollableSheet 사용 또는 Column 등으로 배치
      body: DraggableScrollableSheet(
        initialChildSize: 0.9, // 초기 크기를 거의 전체 화면으로 조정
        minChildSize: 0.4,    // 최소 크기 조정
        maxChildSize: 1.0,    // 최대 크기를 전체 화면으로
        builder: (BuildContext context, ScrollController scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              // 지도 위에 올라가지 않으므로 상단 둥근 모서리 제거 가능
              // borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              boxShadow: [
                // 필요하다면 상단 그림자 유지 또는 제거
                BoxShadow(color: Colors.black12, blurRadius: 8.0, spreadRadius: 1.0, offset: Offset(0, -2))
              ],
            ),
            child: Column(
              children: [
                Container( // 핸들러 UI
                  width: 40, height: 5,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16.0), // 좌우 패딩 추가
                        itemBuilder: (context, index) {
                          final memory = memories[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 8.0), // 리스트 아이템 상하 패딩
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: (memory.thumbUrl?.isNotEmpty ?? false)
                                  ? Image.network(
                                  _toAbsoluteUrl(memory.thumbUrl!),
                                  width: 56, height: 56, fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                      width: 56, height: 56, color: mutedSurfaceColor,
                                      child: const Icon(Icons.broken_image, color: subTextColor)
                                  ),
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      width: 56, height: 56, color: mutedSurfaceColor,
                                      child: Center(child: CircularProgressIndicator(strokeWidth: 2, value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null)),
                                    );
                                  }
                              )
                                  : Container(
                                  width: 56, height: 56,
                                  color: mutedSurfaceColor,
                                  child: const Icon(Icons.image_not_supported, color: subTextColor)),
                            ),
                            title: Text(memory.text ?? '텍스트 없음', style: bodyText1), // 텍스트 스타일 적용
                            subtitle: Text('작성자 ID: ${memory.userId}', style: bodyText2), // 텍스트 스타일 적용
                            onTap: () {
                              // TODO: 메모 상세 페이지 이동
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('메모 ${memory.id} 상세 보기 구현 필요'))
                              );
                            },
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text('메모를 불러오는 데 실패했습니다.\n$err', textAlign: TextAlign.center)), // 중앙 정렬 추가
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}