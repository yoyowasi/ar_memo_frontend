import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_memo_frontend/models/memory.dart';
import 'package:ar_memo_frontend/providers/memory_provider.dart';
import 'package:ar_memo_frontend/theme/text_styles.dart';
import 'package:ar_memo_frontend/theme/colors.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _refreshMemories(WidgetRef ref) {
    return ref.refresh(myMemoriesProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoriesAsyncValue = ref.watch(myMemoriesProvider);
    final baseUrl = dotenv.env['API_BASE_URL']?.replaceAll('/api', '');

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('오늘도 새로운 추억을 남겨보세요', style: bodyText2),
            SizedBox(height: 4),
            Text('AR Memo', style: heading2),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none, color: textColor),
          ),
        ],
      ),
      body: memoriesAsyncValue.when(
        data: (memoryList) {
          return RefreshIndicator(
            onRefresh: () => _refreshMemories(ref),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SearchField(),
                    const SizedBox(height: 24),
                    const _HeroCard(),
                    const SizedBox(height: 32),
                    _SectionHeader(
                      title: '내 주변 메모',
                      actionLabel: memoryList.isNotEmpty ? '전체보기' : null,
                      onTap: () {},
                    ),
                    const SizedBox(height: 16),
                    if (memoryList.isEmpty)
                      _EmptyPlaceholder(
                        icon: Icons.location_off,
                        title: '주변에 등록된 메모가 없어요',
                        description: '새로운 메모를 추가하거나 다른 지역을 탐색해보세요.',
                      )
                    else
                      _MemoryCarousel(memories: memoryList, baseUrl: baseUrl),
                    const SizedBox(height: 32),
                    _SectionHeader(
                      title: '인기 태그',
                      actionLabel: null,
                      onTap: () {},
                    ),
                    const SizedBox(height: 16),
                    _TagWrap(memories: memoryList),
                    const SizedBox(height: 32),
                    _SectionHeader(
                      title: '최근에 저장한 메모',
                      actionLabel: memoryList.length > 3 ? '더 보기' : null,
                      onTap: () {},
                    ),
                    const SizedBox(height: 16),
                    if (memoryList.isEmpty)
                      _EmptyPlaceholder(
                        icon: Icons.bookmark_border,
                        title: '아직 저장한 메모가 없어요',
                        description: '첫 번째 AR 메모를 등록해보세요.',
                      )
                    else
                      _RecentMemoryList(memories: memoryList, baseUrl: baseUrl),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: _EmptyPlaceholder(
            icon: Icons.wifi_off,
            title: '메모를 불러올 수 없어요',
            description: '잠시 후 다시 시도해주세요.\n$err',
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: AR 메모 생성 화면으로 이동하는 로직 구현
        },
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('메모 추가', style: buttonText),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 10),
            blurRadius: 30,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: const [
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