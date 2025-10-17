import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_memo_frontend/providers/trip_record_provider.dart';
import 'package:ar_memo_frontend/screens/create_trip_record_screen.dart';
import 'package:ar_memo_frontend/screens/trip_record_detail_screen.dart';
import 'package:ar_memo_frontend/theme/colors.dart';
import 'package:ar_memo_frontend/theme/text_styles.dart';
import 'package:intl/intl.dart';

class TripRecordListScreen extends ConsumerWidget {
  const TripRecordListScreen({super.key});

  /// 서버의 상대 경로를 완전한 URL로 변환하는 함수
  String _toAbsoluteUrl(String relativeUrl) {
    // 1. 나중에 실제 서버 사용할 때, 아래 주석을 풀고 사용하세요.
    // const String productionUrl = "https://your-production-server.com";
    // if (relativeUrl.startsWith('http')) return relativeUrl;
    // return productionUrl + relativeUrl;

    // 2. 지금은 로컬 개발 서버용 URL을 생성합니다.
    final rawBaseUrl = dotenv.env['API_BASE_URL'];
    if (rawBaseUrl == null || rawBaseUrl.isEmpty) return relativeUrl;

    if (relativeUrl.startsWith('http')) return relativeUrl;

    final uri = Uri.parse(rawBaseUrl);
    final baseUrl = '${uri.scheme}://${uri.host}:${uri.port}';

    return '$baseUrl$relativeUrl';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripRecordsAsyncValue = ref.watch(tripRecordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('여행 기록', style: heading2),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: textColor),
            onPressed: () => ref.invalidate(tripRecordsProvider),
          )
        ],
      ),
      body: tripRecordsAsyncValue.when(
        data: (records) {
          if (records.isEmpty) {
            return const Center(
                child: Text('첫 여행 기록을 추가해보세요!', style: bodyText1));
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(tripRecordsProvider.future),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TripRecordDetailScreen(recordId: record.id),
                      ),
                    ).then((result) {
                      if (result == true) {
                        ref.invalidate(tripRecordsProvider);
                      }
                    });
                  },
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            color: secondaryColor.withAlpha(128),
                            child: record.photoUrls.isNotEmpty
                                ? Image.network(
                              _toAbsoluteUrl(record.photoUrls.first),
                              fit: BoxFit.cover,
                            )
                                : const Center(
                                child: Icon(Icons.photo_camera,
                                    size: 40, color: Colors.white)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(record.title,
                                  style: bodyText1.copyWith(
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis),
                              Text(DateFormat('yyyy.MM.dd').format(record.date),
                                  style: bodyText2),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTripRecordScreen()),
          ).then((result) {
            if (result == true) {
              ref.invalidate(tripRecordsProvider);
            }
          });
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}