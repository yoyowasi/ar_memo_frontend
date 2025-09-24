import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ✨ AR 메모 데이터를 가져오기 위해 'memory_provider.dart'를 import 해야 합니다.
import 'package:ar_memo_frontend/providers/memory_provider.dart';
import 'package:ar_memo_frontend/theme/text_styles.dart';
import 'package:ar_memo_frontend/theme/colors.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✨ 여행 기록이 아닌 'myMemoriesProvider'를 사용하여 AR 메모 목록을 가져옵니다.
    final memoriesAsyncValue = ref.watch(myMemoriesProvider);
    // .env 파일에서 API 서버의 기본 URL을 가져옵니다.
    final baseUrl = dotenv.env['API_BASE_URL']!.replaceAll('/api', '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('AR 메모', style: heading2),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: memoriesAsyncValue.when(
        data: (memoryList) {
          if (memoryList.isEmpty) {
            return const Center(child: Text('주변에 AR 메모가 없습니다.', style: bodyText1));
          }

          // 피그마 디자인에 맞춰 그리드 뷰로 메모 목록을 표시합니다.
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: memoryList.length,
            itemBuilder: (context, index) {
              final memory = memoryList[index];
              // 썸네일이 있으면 썸네일을, 없으면 메인 사진을 사용합니다.
              final imageUrl = memory.thumbUrl ?? memory.photoUrl;

              return Card(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Container(
                        color: Colors.grey.shade200,
                        child: imageUrl != null
                        // '$baseUrl$imageUrl' 형태로 완전한 이미지 URL을 만듭니다.
                            ? Image.network(
                          "$baseUrl$imageUrl",
                          fit: BoxFit.cover,
                          // 이미지 로딩 중 에러가 발생하면 아이콘을 표시합니다.
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.broken_image, color: Colors.grey);
                          },
                        )
                            : const Icon(Icons.text_fields, size: 40, color: Colors.grey),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        // memory 객체의 text 필드를 사용합니다.
                        memory.text ?? '사진 메모',
                        style: bodyText1,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('메모를 불러오지 못했습니다: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: AR 메모 생성 화면으로 이동하는 로직 구현
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}