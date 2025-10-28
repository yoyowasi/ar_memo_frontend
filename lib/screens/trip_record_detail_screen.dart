import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ar_memo_frontend/utils/url_utils.dart';
import 'package:ar_memo_frontend/providers/trip_record_provider.dart';
import 'package:ar_memo_frontend/theme/colors.dart';
import 'package:ar_memo_frontend/theme/text_styles.dart';
import 'package:ar_memo_frontend/screens/create_trip_record_screen.dart';

class TripRecordDetailScreen extends ConsumerWidget {
  final String recordId;
  const TripRecordDetailScreen({super.key, required this.recordId});

  void _deleteRecord(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('기록 삭제'),
          content: const Text('정말로 이 기록을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('삭제'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await ref.read(tripRecordsProvider.notifier).deleteTripRecord(recordId);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('삭제 실패: $e')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordAsync = ref.watch(tripRecordDetailProvider(recordId));

    return Scaffold(
      backgroundColor: backgroundColor,
      body: recordAsync.when(
        data: (record) {
          final Color groupDisplayColor = (record.group?.color != null && record.group!.color!.isNotEmpty)
              ? (_parseHexColor(record.group!.color!) ?? primaryColor)
              : primaryColor;

          return RefreshIndicator(
            onRefresh: () => ref.refresh(tripRecordDetailProvider(recordId).future),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 250.0,
                  floating: false,
                  pinned: true,
                  stretch: true,
                  backgroundColor: Colors.white,
                  foregroundColor: textColor,
                  iconTheme: const IconThemeData(color: Colors.white),
                  actionsIconTheme: const IconThemeData(color: Colors.white),
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.symmetric(horizontal: 56, vertical: 12),
                    centerTitle: false,
                    title: Text(
                      record.title,
                      style: heading2.copyWith(
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 2, color: Colors.black.withOpacity(0.5))],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    background: record.photoUrls.isNotEmpty
                        ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          toAbsoluteUrl(record.photoUrls.first),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: mutedSurfaceColor,
                            child: const Center(
                              child: Icon(Icons.broken_image_outlined, color: subTextColor),
                            ),
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.1),
                                Colors.black.withOpacity(0.5),
                              ],
                              stops: const [0.5, 0.7, 1.0],
                            ),
                          ),
                        ),
                      ],
                    )
                        : Container(
                      color: mutedSurfaceColor,
                      child: const Center(
                        child: Icon(Icons.image_not_supported_outlined, color: subTextColor, size: 60),
                      ),
                    ),
                    stretchModes: const [StretchMode.zoomBackground],
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: '수정',
                      onPressed: () {
                        Navigator
                            .push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateTripRecordScreen(recordToEdit: record),
                          ),
                        )
                            .then((result) {
                          if (result == true) {
                            ref.invalidate(tripRecordDetailProvider(recordId));
                          }
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: '삭제',
                      onPressed: () => _deleteRecord(context, ref),
                    ),
                  ],
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(20.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('yyyy년 MM월 dd일 EEEE', 'ko_KR').format(record.date),
                              style: bodyText2,
                            ),
                            if (record.group != null)
                              Row(
                                children: [
                                  Icon(Icons.group, color: groupDisplayColor, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    record.group!.name,
                                    style: bodyText1.copyWith(color: groupDisplayColor, fontSize: 14),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const Divider(height: 32),
                        Text(
                          record.content.isEmpty ? '(작성된 내용이 없습니다)' : record.content,
                          style: bodyText1.copyWith(height: 1.6, fontSize: 15),
                        ),
                        const SizedBox(height: 24),
                        if (record.photoUrls.length > 1)
                          ...record.photoUrls.skip(1).map(
                                (url) => Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  toAbsoluteUrl(url),
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    height: 200,
                                    color: mutedSurfaceColor,
                                    child: const Center(
                                      child: Icon(Icons.error_outline, color: subTextColor),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Scaffold(
          appBar: AppBar(title: const Text('오류')),
          body: Center(
            child: Text('일기 상세 정보를 불러오는 중 오류 발생:\n$err'),
          ),
        ),
      ),
    );
  }
}

Color? _parseHexColor(String input) {
  var hex = input.trim();
  if (hex.startsWith('#')) hex = hex.substring(1);
  if (hex.length == 6) {
    hex = 'FF$hex';
  }
  if (hex.length != 8) return null;
  final intVal = int.tryParse(hex, radix: 16);
  if (intVal == null) return null;
  return Color(intVal);
}
