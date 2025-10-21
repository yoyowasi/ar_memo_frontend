import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_memo_frontend/providers/trip_record_provider.dart';
import 'package:ar_memo_frontend/screens/trip_record_detail_screen.dart';
import 'package:ar_memo_frontend/theme/colors.dart';
import 'package:ar_memo_frontend/theme/text_styles.dart';
import 'package:intl/intl.dart';
// 생성 팝업 관련 import (HomeScreen에서 가져옴 - 분리 권장)
import 'package:ar_memo_frontend/screens/home_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:ar_memo_frontend/providers/upload_provider.dart';
import 'package:ar_memo_frontend/models/trip_record.dart'; // TripRecord import

class TripRecordListScreen extends ConsumerWidget {
  const TripRecordListScreen({super.key});

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

  // --- 생성 팝업 로직 (HomeScreen에서 가져옴) ---
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
              // TODO: 생성 시 위치 정보도 함께 저장하도록 수정 필요 (팝업에서 위치 입력 받거나, 현재 위치 사용)
              double? currentLat; // 임시
              double? currentLng; // 임시
              try {
                await ref.read(tripRecordsProvider.notifier).addTripRecord(
                  title: titleController.text, content: contentController.text,
                  date: selectedDate!, photoUrls: photoUrls,
                  latitude: currentLat, longitude: currentLng,
                );
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('일기가 저장되었습니다.')));
                // Provider watch로 목록 자동 갱신
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
  // --- 팝업 로직 끝 ---


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripRecordsAsyncValue = ref.watch(tripRecordsProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('일기', style: heading2),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(color: borderColor, height: 1.0)
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: textColor),
            tooltip: '검색',
            onPressed: () { /* TODO: 검색 기능 */ },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: textColor),
            tooltip: '필터',
            onPressed: () { /* TODO: 필터 기능 */ },
          ),
        ],
      ),
      body: tripRecordsAsyncValue.when(
        data: (records) {
          if (records.isEmpty) {
            // 빈 상태 UI
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.article_outlined, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('작성된 일기가 없습니다.', style: bodyText1),
                  const SizedBox(height: 4),
                  const Text('새로운 여행 기록을 추가해보세요.', style: bodyText2),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateTripPopup(context, ref), // 생성 팝업 호출
                    icon: const Icon(Icons.add),
                    label: const Text('일기 쓰기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  )
                ],
              ),
            );
          }
          // ListView 및 카드 디자인 적용
          return RefreshIndicator(
            onRefresh: () async { // async 추가
              // invalidate 대신 refresh 사용 (더 명확)
              await ref.refresh(tripRecordsProvider.future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80), // FAB 고려 하단 패딩
              itemCount: records.length,
              itemBuilder: (context, index) {
                final TripRecord record = records[index]; // 타입 명시
                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () { // 상세 화면 이동
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TripRecordDetailScreen(recordId: record.id),
                        ),
                      ).then((result) {
                        // 상세 화면에서 변경 시 목록 갱신 (선택적)
                        // if (result == true) {
                        //   ref.invalidate(tripRecordsProvider);
                        // }
                      });
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 이미지
                        SizedBox(
                          width: 100, height: 100,
                          child: record.photoUrls.isNotEmpty
                              ? Image.network(
                            _toAbsoluteUrl(record.photoUrls.first),
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) =>
                            loadingProgress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            errorBuilder: (context, error, stackTrace) =>
                                Container(color: Colors.grey[200], child: const Icon(Icons.broken_image_outlined, color: Colors.grey)),
                          )
                              : Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 40),
                          ),
                        ),
                        // 텍스트 정보
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  record.title,
                                  style: heading2.copyWith(fontSize: 16),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('yyyy년 MM월 dd일 EEEE', 'ko_KR').format(record.date), // 날짜 형식 변경
                                  style: bodyText2.copyWith(fontSize: 12),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  record.content.isEmpty ? '(내용 없음)' : record.content,
                                  style: bodyText2,
                                  maxLines: 2, overflow: TextOverflow.ellipsis,
                                ),
                                // 그룹 정보 (필요 시 추가)
                                // if (record.group != null) ...[ ],
                              ],
                            ),
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
        error: (err, stack) => Center(child: Text('일기 목록 로딩 오류: $err')),
      ),
    );
  }
}