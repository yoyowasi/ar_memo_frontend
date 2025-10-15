import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ar_memo_frontend/models/trip_record.dart';
import 'package:ar_memo_frontend/providers/trip_record_provider.dart';
import 'package:ar_memo_frontend/screens/create_trip_record_screen.dart';
import 'package:ar_memo_frontend/theme/colors.dart';
import 'package:ar_memo_frontend/theme/text_styles.dart';

// Provider to fetch a single trip record
final tripRecordDetailProvider =
FutureProvider.family<TripRecord, String>((ref, id) {
  final repo = ref.watch(tripRecordRepositoryProvider);
  return repo.getTripRecord(id);
});

class TripRecordDetailScreen extends ConsumerWidget {
  final String recordId;
  const TripRecordDetailScreen({super.key, required this.recordId});

  void _deleteRecord(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('정말로 이 일기를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            child: const Text('취소'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              // 비동기 작업 전에 context 관련 변수 선언
              final navigator = Navigator.of(ctx);
              final rootNavigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              try {
                await ref
                    .read(tripRecordsProvider.notifier)
                    .deleteTripRecord(recordId);
                navigator.pop(); // 다이얼로그 닫기
                rootNavigator.pop(true); // 상세 페이지 닫기
                messenger.showSnackBar(
                  const SnackBar(content: Text('일기가 삭제되었습니다.')),
                );
              } catch (e) {
                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(content: Text('삭제 실패: ${e.toString()}')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordAsync = ref.watch(tripRecordDetailProvider(recordId));

    return Scaffold(
      body: recordAsync.when(
        data: (record) => CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 250.0,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(record.title,
                    style: heading2.copyWith(color: Colors.white, shadows: [
                      const Shadow(blurRadius: 4, color: Colors.black54)
                    ])),
                background: record.photoUrls.isNotEmpty
                    ? Image.network(
                  record.photoUrls.first,
                  fit: BoxFit.cover,
                )
                    : Container(color: mutedSurfaceColor),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CreateTripRecordScreen(recordToEdit: record),
                      ),
                    ).then((result) {
                      if (result == true) {
                        ref.invalidate(tripRecordDetailProvider(recordId));
                      }
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteRecord(context, ref),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('yyyy년 M월 d일 EEEE', 'ko_KR')
                          .format(record.date),
                      style: bodyText2,
                    ),
                    const SizedBox(height: 8),
                    if (record.group != null)
                      Row(
                        children: [
                          Icon(Icons.group, color: Color(record.group!.colorValue), size: 16),
                          const SizedBox(width: 4),
                          Text(record.group!.name, style: bodyText1.copyWith(color: Color(record.group!.colorValue))),
                        ],
                      ),
                    const Divider(height: 32),
                    Text(record.content, style: bodyText1.copyWith(height: 1.6)),
                    const SizedBox(height: 24),
                    // 추가 사진들 (첫 번째 사진 제외)
                    if (record.photoUrls.length > 1)
                      ...record.photoUrls.skip(1).map((url) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(url),
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}