import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_memo_frontend/models/memory.dart';
import 'package:ar_memo_frontend/models/memory_summary.dart';
import 'package:ar_memo_frontend/providers/memory_provider.dart';
import 'package:ar_memo_frontend/theme/text_styles.dart';
import 'package:ar_memo_frontend/theme/colors.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _refreshMemories(WidgetRef ref) async {
    await Future.wait([
      ref.refresh(myMemoriesProvider.future),
      ref.refresh(memorySummaryProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoriesAsyncValue = ref.watch(myMemoriesProvider);
    final summaryAsyncValue = ref.watch(memorySummaryProvider);
    final baseUrl = dotenv.env['API_BASE_URL']?.replaceAll('/api', '');

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _refreshMemories(ref),
          displacement: 24,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _HomeHeader(),
                      const SizedBox(height: 20),
                      const _SearchBar(),
                      const SizedBox(height: 20),
                      const _HeroBanner(),
                      const SizedBox(height: 24),
                      summaryAsyncValue.when(
                        data: (summary) => _SummaryStrip(summary: summary),
                        loading: () => const _SummaryStripSkeleton(),
                        error: (err, stack) => _SummaryError(
                          message: err.toString(),
                          onRetry: () => ref.refresh(memorySummaryProvider.future),
                        ),
                      ),
                      const SizedBox(height: 32),
                      memoriesAsyncValue.when(
                        data: (memories) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionTitle(
                              title: '주변의 AR 추억',
                              onTap: memories.isNotEmpty ? () {} : null,
                            ),
                            const SizedBox(height: 16),
                            if (memories.isEmpty)
                              const _EmptyPlaceholder(
                                icon: Icons.location_on_outlined,
                                title: '주변에 등록된 추억이 없어요',
                                description: '새로운 장소에서 첫 번째 메모를 남겨보세요.',
                              )
                            else
                              _NearbyMemoryCarousel(memories: memories, baseUrl: baseUrl),
                            const SizedBox(height: 32),
                            if (memories.isNotEmpty) ...[
                              const _SectionTitle(title: '인기 태그'),
                              const SizedBox(height: 16),
                              _PopularTagWrap(memories: memories),
                              const SizedBox(height: 32),
                              _SectionTitle(
                                title: '최근에 기록한 추억',
                                onTap: memories.length > 3 ? () {} : null,
                              ),
                              const SizedBox(height: 16),
                              _RecentMemoryList(memories: memories, baseUrl: baseUrl),
                            ],
                          ],
                        ),
                        loading: () => const _MemoriesLoading(),
                        error: (err, stack) => _EmptyPlaceholder(
                          icon: Icons.wifi_off,
                          title: '메모를 불러올 수 없어요',
                          description: '네트워크 상태를 확인하고 다시 시도해주세요.\n$err',
                          actionLabel: '다시 시도',
                          onActionPressed: () => ref.refresh(myMemoriesProvider.future),
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        onPressed: () {
          // TODO: AR 메모 생성 화면으로 이동하는 로직 구현
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('새 추억 남기기', style: buttonText),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: mutedSurfaceColor,
          ),
          child: const Icon(Icons.person, color: subTextColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('안녕하세요!', style: bodyText2),
              SizedBox(height: 4),
              Text('AR Memo 여행 일지를 시작해보세요', style: heading2),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none, color: textColor),
          splashRadius: 22,
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: const [
          Icon(Icons.search, color: subTextColor),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '장소나 태그로 추억을 검색해보세요',
              style: bodyText2,
            ),
          ),
          Icon(Icons.tune_rounded, color: subTextColor),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '여행 중 기록하고 싶은 순간을
AR로 생생하게 남겨보세요',
            style: heading2.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.camera_alt_outlined, color: Colors.white),
                SizedBox(width: 8),
                Text('AR 촬영 바로가기', style: buttonText),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  final MemorySummary summary;

  const _SummaryStrip({required this.summary});

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummaryItem('전체 메모', summary.total.toString(), Icons.bookmark_border),
      _SummaryItem('주변 메모', summary.nearby.toString(), Icons.near_me_outlined),
      _SummaryItem('이번 달', summary.thisMonth.toString(), Icons.calendar_today_outlined),
    ];

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(child: items[i]),
            if (i != items.length - 1)
              Container(
                height: 44,
                width: 1,
                color: borderColor,
              ),
          ],
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryItem(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: primaryColor, size: 24),
        const SizedBox(height: 8),
        Text(value, style: heading2),
        const SizedBox(height: 4),
        Text(label, style: bodyText2),
      ],
    );
  }
}

class _SummaryStripSkeleton extends StatelessWidget {
  const _SummaryStripSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }
}

class _SummaryError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SummaryError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _EmptyPlaceholder(
      icon: Icons.error_outline,
      title: '통계를 불러오는 중 오류가 발생했어요',
      description: message,
      actionLabel: '다시 시도',
      onActionPressed: onRetry,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const _SectionTitle({required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: heading2,
          ),
        ),
        if (onTap != null)
          TextButton(
            onPressed: onTap,
            child: const Text('전체보기'),
          ),
      ],
    );
  }
}

class _NearbyMemoryCarousel extends StatelessWidget {
  final List<Memory> memories;
  final String? baseUrl;

  const _NearbyMemoryCarousel({required this.memories, required this.baseUrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: math.min(memories.length, 5),
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final memory = memories[index];
          final photoUrl = memory.thumbUrl?.isNotEmpty == true
              ? '${baseUrl ?? ''}${memory.thumbUrl}'
              : null;
          return Container(
            width: 200,
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: photoUrl != null
                      ? Image.network(
                          photoUrl,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 120,
                          width: double.infinity,
                          color: mutedSurfaceColor,
                          child: const Icon(Icons.image_outlined, color: subTextColor),
                        ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          memory.text ?? '내용이 없는 메모',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: bodyText1.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.place_outlined, size: 16, color: subTextColor),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                memory.groupId != null ? '그룹 공유 메모' : '개인 메모',
                                style: bodyText2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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

class _PopularTagWrap extends StatelessWidget {
  final List<Memory> memories;

  const _PopularTagWrap({required this.memories});

  @override
  Widget build(BuildContext context) {
    final tagCounts = <String, int>{};
    for (final memory in memories) {
      for (final tag in memory.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }

    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedTags.isEmpty) {
      return const _EmptyPlaceholder(
        icon: Icons.sell_outlined,
        title: '등록된 태그가 없어요',
        description: '메모에 태그를 추가하고 더 쉽게 찾아보세요.',
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final tag in sortedTags.take(8))
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
            ),
            child: Text('#${tag.key}', style: bodyText1.copyWith(fontWeight: FontWeight.w500)),
          ),
      ],
    );
  }
}

class _RecentMemoryList extends StatelessWidget {
  final List<Memory> memories;
  final String? baseUrl;

  const _RecentMemoryList({required this.memories, required this.baseUrl});

  @override
  Widget build(BuildContext context) {
    final recent = memories.take(5).toList();

    return Column(
      children: [
        for (final memory in recent)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: mutedSurfaceColor,
                      image: (memory.thumbUrl?.isNotEmpty ?? false)
                          ? DecorationImage(
                              fit: BoxFit.cover,
                              image: NetworkImage('${baseUrl ?? ''}${memory.thumbUrl}'),
                            )
                          : null,
                    ),
                    child: (memory.thumbUrl?.isNotEmpty ?? false)
                        ? null
                        : const Icon(Icons.photo_size_select_actual_outlined, color: subTextColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          memory.text ?? '내용이 없는 메모',
                          style: bodyText1.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          memory.tags.isNotEmpty ? '#${memory.tags.take(2).join(' #')}' : '태그 없음',
                          style: bodyText2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: subTextColor),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _MemoriesLoading extends StatelessWidget {
  const _MemoriesLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  const _EmptyPlaceholder({
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: subTextColor),
          const SizedBox(height: 16),
          Text(title, style: bodyText1.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: bodyText2,
          ),
          if (actionLabel != null && onActionPressed != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onActionPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: const BorderSide(color: primaryColor),
                minimumSize: const Size(120, 44),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
          Icon(Icons.search, color: subTextColor),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '태그나 키워드로 메모를 검색해보세요',
              style: bodyText2,
            ),
          ),
          Icon(Icons.tune, color: subTextColor),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 35,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '주변에 떠 있는 AR 메모',
            style: heading1.copyWith(color: Colors.white, fontSize: 26),
          ),
          const SizedBox(height: 12),
          Text(
            '가까운 친구들의 메모를 살펴보고 새로운 추억을 공유해보세요.',
            style: bodyText2.copyWith(color: Colors.white.withOpacity(0.85)),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 0,
            ),
            child: const Text('지금 확인하기'),
          ),
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  final MemorySummary summary;

  const _SummarySection({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: '전체 메모',
            value: summary.total,
            gradientColors: const [Color(0xFF4C6EF5), Color(0xFF79A6F6)],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: '주변 메모',
            value: summary.nearby,
            gradientColors: const [Color(0xFF51CF66), Color(0xFF94E1A1)],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: '이번 달',
            value: summary.thisMonth,
            gradientColors: const [Color(0xFFFF922B), Color(0xFFFFC078)],
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final int value;
  final List<Color> gradientColors;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: bodyText2.copyWith(color: Colors.white.withOpacity(0.9)),
          ),
          const SizedBox(height: 12),
          Text(
            value.toString(),
            style: heading1.copyWith(color: Colors.white, fontSize: 28),
          ),
        ],
      ),
    );
  }
}

class _SummaryLoading extends StatelessWidget {
  const _SummaryLoading();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: _SummarySkeletonCard()),
        const SizedBox(width: 12),
        Expanded(child: _SummarySkeletonCard()),
        const SizedBox(width: 12),
        Expanded(child: _SummarySkeletonCard()),
      ],
    );
  }
}

class _SummarySkeletonCard extends StatelessWidget {
  const _SummarySkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
    );
  }
}

class _SummaryError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SummaryError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: subTextColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '통계 정보를 불러올 수 없어요.\n$message',
              style: bodyText2,
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: primaryColor,
            ),
            child: Text(
              '다시 시도',
              style: bodyText2.copyWith(
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback onTap;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: heading2.copyWith(fontSize: 18)),
        const Spacer(),
        if (actionLabel != null)
          TextButton(
            onPressed: onTap,
            child: Row(
              children: [
                Text(actionLabel!, style: bodyText2.copyWith(color: primaryColor)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios, size: 14, color: primaryColor),
              ],
            ),
          ),
      ],
    );
  }
}

class _MemoryCarousel extends StatelessWidget {
  final List<Memory> memories;
  final String? baseUrl;

  const _MemoryCarousel({required this.memories, required this.baseUrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: memories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 18),
        itemBuilder: (context, index) {
          final memory = memories[index];
          final imageUrl = memory.thumbUrl ?? memory.photoUrl;

          return Container(
            width: 220,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: imageUrl != null && baseUrl != null
                        ? Image.network(
                            '$baseUrl$imageUrl',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _ImagePlaceholder(icon: Icons.broken_image);
                            },
                          )
                        : const _ImagePlaceholder(icon: Icons.photo_camera_outlined),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          memory.text ?? '사진 메모',
                          style: bodyText1.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: memory.tags.take(3).map((tag) => _TagChip(tag: tag)).toList(),
                        ),
                      ],
                    ),
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

class _TagWrap extends StatelessWidget {
  final List<Memory> memories;

  const _TagWrap({required this.memories});

  @override
  Widget build(BuildContext context) {
    final tags = memories.expand((memory) => memory.tags).toSet().toList();

    if (tags.isEmpty) {
      return const _EmptyPlaceholder(
        icon: Icons.sell_outlined,
        title: '표시할 태그가 없어요',
        description: '메모에 태그를 추가하면 빠르게 찾아볼 수 있어요.',
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: tags
          .take(12)
          .map((tag) => _TagChip(tag: tag))
          .toList(),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String tag;

  const _TagChip({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        '#$tag',
        style: bodyText2.copyWith(color: textColor),
      ),
    );
  }
}

class _RecentMemoryList extends StatelessWidget {
  final List<Memory> memories;
  final String? baseUrl;

  const _RecentMemoryList({required this.memories, required this.baseUrl});

  @override
  Widget build(BuildContext context) {
    final recentMemories = memories.take(3).toList();

    return Column(
      children: recentMemories
          .map(
            (memory) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: 70,
                          width: 70,
                          child: _RecentMemoryThumbnail(
                            imageUrl: memory.thumbUrl ?? memory.photoUrl,
                            baseUrl: baseUrl,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              memory.text ?? '사진 메모',
                              style: bodyText1.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            if (memory.tags.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                children: memory.tags.take(3).map((tag) => _TagChip(tag: tag)).toList(),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.more_vert, color: subTextColor),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _RecentMemoryThumbnail extends StatelessWidget {
  final String? imageUrl;
  final String? baseUrl;

  const _RecentMemoryThumbnail({required this.imageUrl, required this.baseUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && baseUrl != null) {
      return Image.network(
        '$baseUrl$imageUrl',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const _ImagePlaceholder(icon: Icons.broken_image);
        },
      );
    }
    return const _ImagePlaceholder(icon: Icons.photo_camera_outlined);
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final IconData icon;

  const _ImagePlaceholder({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Icon(icon, color: subTextColor),
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _EmptyPlaceholder({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: subTextColor),
          const SizedBox(height: 16),
          Text(title, style: bodyText1.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: bodyText2,
          ),
        ],
      ),
    );
  }
}