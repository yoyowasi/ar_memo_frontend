// lib/screens/trip_record_list_screen.dart
import 'dart:io';

import 'package:ar_memo_frontend/models/trip_record.dart';
import 'package:ar_memo_frontend/providers/group_provider.dart';
import 'package:ar_memo_frontend/providers/trip_record_provider.dart';
import 'package:ar_memo_frontend/providers/upload_provider.dart';
import 'package:ar_memo_frontend/screens/trip_record_detail_screen.dart';
import 'package:ar_memo_frontend/theme/colors.dart';
import 'package:ar_memo_frontend/theme/text_styles.dart';
import 'package:ar_memo_frontend/screens/create_trip_record_screen.dart';
import 'package:ar_memo_frontend/widgets/trip_record_search_delegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:native_exif/native_exif.dart';

enum TripRecordFilter {
  all,
  withPhotos,
  withGroup,
}

class TripRecordListScreen extends ConsumerWidget {
  const TripRecordListScreen({super.key});



  List<TripRecord> _applyFilter(List<TripRecord> records, TripRecordFilter filter) {
    switch (filter) {
      case TripRecordFilter.all:
        return records;
      case TripRecordFilter.withPhotos:
        return records.where((record) => record.photoUrls.isNotEmpty).toList();
      case TripRecordFilter.withGroup:
        return records
            .where((record) =>
        record.group != null ||
            (record.groupIdString != null &&
                record.groupIdString!.isNotEmpty))
            .toList();
    }
  }

  Future<void> _openSearch(BuildContext context, WidgetRef ref) async {
    final records = ref.read(tripRecordsProvider).asData?.value ?? [];
    if (records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('검색할 일기가 없습니다.')),
      );
      return;
    }

    final selected = await showSearch<TripRecord?>(
      context: context,
      delegate: TripRecordSearchDelegate(records),
    );

    if (selected != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TripRecordDetailScreen(recordId: selected.id),
        ),
      );
    }
  }

  Future<void> _openFilter(BuildContext context, WidgetRef ref) async {
    final records = ref.read(tripRecordsProvider).asData?.value ?? [];
    if (records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('필터링할 일기가 없습니다.')),
      );
      return;
    }

    final filter = await showModalBottomSheet<TripRecordFilter>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.all_inclusive),
                title: const Text('전체 보기'),
                onTap: () => Navigator.of(ctx).pop(TripRecordFilter.all),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('사진이 있는 일기'),
                onTap: () => Navigator.of(ctx).pop(TripRecordFilter.withPhotos),
              ),
              ListTile(
                leading: const Icon(Icons.group_outlined),
                title: const Text('그룹에 공유된 일기'),
                onTap: () => Navigator.of(ctx).pop(TripRecordFilter.withGroup),
              ),
            ],
          ),
        );
      },
    );

    if (filter == null) return;

    final filtered = _applyFilter(records, filter);
    if (filtered.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('조건에 맞는 일기가 없습니다.')),
        );
      }
      return;
    }

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final record = filtered[index];
              return ListTile(
                leading: const Icon(Icons.article_outlined),
                title: Text(record.title, style: bodyText1),
                subtitle: Text(
                  DateFormat('yyyy.MM.dd').format(record.date),
                  style: bodyText2,
                ),
                trailing: record.photoUrls.isNotEmpty
                    ? const Icon(Icons.photo, color: primaryColor)
                    : null,
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          TripRecordDetailScreen(recordId: record.id),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripRecordsAsyncValue = ref.watch(tripRecordsProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateTripRecordScreen()),
          );
        },
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('일기 쓰기'),
      ),
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
            onPressed: () => _openSearch(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: textColor),
            tooltip: '필터',
            onPressed: () => _openFilter(context, ref),
          ),
        ],
      ),
      body: tripRecordsAsyncValue.when(
        data: (records) {
          if (records.isEmpty) {
            // 빈 상태 UI
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.article_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text('작성된 일기가 없습니다.', style: bodyText1),
              const SizedBox(height: 4),
              const Text('새로운 여행 기록을 추가해보세요.', style: bodyText2),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CreateTripRecordScreen()),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('일기 쓰기'),
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
              )
            ],),);
          }
          // ListView 및 카드 디자인
          return RefreshIndicator(
            onRefresh: () async {
              // ignore: unused_result
              await ref.refresh(tripRecordsProvider.future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final TripRecord record = records[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => TripRecordDetailScreen(recordId: record.id)),
                      );
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 100, height: 100,
                          child: record.photoUrls.isNotEmpty
                          // 🟢 toAbsoluteUrl 제거 (Signed URL은 이미 절대 경로임)
                              ? Image.network(record.photoUrls.first, fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) => loadingProgress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image_outlined, color: Colors.grey)),
                          )
                              : Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 40)),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(record.title, style: heading2.copyWith(fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text(DateFormat('yyyy년 MM월 dd일 EEEE', 'ko_KR').format(record.date), style: bodyText2.copyWith(fontSize: 12)),
                                const SizedBox(height: 6),
                                Text(record.content.isEmpty ? '(내용 없음)' : record.content, style: bodyText2, maxLines: 2, overflow: TextOverflow.ellipsis),
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