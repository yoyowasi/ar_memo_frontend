import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ✨ AR 메모 데이터를 가져오기 위해 'memory_provider.dart'를 import 합니다.
import 'package:ar_memo_frontend/providers/memory_provider.dart';
import 'package:ar_memo_frontend/theme/text_styles.dart';
import 'package:ar_memo_frontend/theme/colors.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✨✨✨
    // ✨ 이 부분이 가장 중요합니다. 'myMemoriesProvider'를 사용해야 합니다.
    // ✨✨✨
    final memoriesAsyncValue = ref.watch(myMemoriesProvider);
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
              // 이제 'memory'는 'Memory' 타입이므로 오류가 발생하지 않습니다.
              final memory = memoryList[index];
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
                            ? Image.network(
                          "$baseUrl$imageUrl",
                          fit: BoxFit.cover,
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
                        // memory.text 필드를 정상적으로 사용할 수 있습니다.
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