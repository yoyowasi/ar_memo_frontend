import 'package:flutter/material.dart';
import 'package:ar_memo_frontend/utils/url_utils.dart'; // url_utils import
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:ar_memo_frontend/models/group.dart';
import 'package:ar_memo_frontend/models/memory.dart';
import 'package:ar_memo_frontend/providers/group_provider.dart';
import 'package:ar_memo_frontend/providers/memory_provider.dart';
import 'package:ar_memo_frontend/theme/colors.dart';
import 'package:ar_memo_frontend/theme/text_styles.dart';


class GroupDetailScreen extends ConsumerWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  

  // Working implementation based on TripRecordDetailScreen
  void _deleteGroup(BuildContext context, WidgetRef ref) {
    // This context is the screen's context, passed down from _showMoreOptions.
    // First, pop the bottom sheet.
    Navigator.of(context).pop();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('그룹 삭제'),
          content: const Text('정말로 이 그룹을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
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
                Navigator.of(dialogContext).pop(); // Close dialog

                try {
                  // Call repository directly
                  await ref.read(groupRepositoryProvider).deleteGroup(groupId);

                  // Invalidate providers to refresh the list
                  ref.invalidate(myGroupsProvider);
                  ref.invalidate(groupDetailProvider(groupId));

                  // Pop the detail screen to go back
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

  void _showEditGroupDialog(BuildContext context, WidgetRef ref, Group group) {
    final nameController = TextEditingController(text: group.name);
    String selectedColor = group.colorHex ?? '#8D7BFD';
    bool isSaving = false;
    final messenger = ScaffoldMessenger.of(context);

    final palette = [
      '#FF8040', '#FFB380', '#FFC9A3', '#FFDBC2', '#FFE8D9',
      '#FF94AD', '#FFB3C4', '#FFD1DA', '#FFE0E7', '#FFEBF0',
      '#8D7BFD', '#ADA2FD', '#CDBFFD', '#DCD7FE', '#EAE6FE',
      '#7BC6FD', '#A1D6FE', '#C3E4FE', '#D9EFFE', '#EAF6FE',
      '#7BFDB9', '#A1FDBF', '#C3FDCE', '#D9FDDE', '#EAFEEC',
    ];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setState) {
            Future<void> submit() async {
              if (nameController.text.trim().isEmpty) {
                messenger.showSnackBar(const SnackBar(content: Text('그룹 이름을 입력하세요.')));
                return;
              }
              setState(() => isSaving = true);
              try {
                await ref.read(groupRepositoryProvider).updateGroup(
                      id: group.id,
                      name: nameController.text.trim(),
                      colorHex: selectedColor,
                    );
                ref.invalidate(groupDetailProvider(group.id));
                ref.invalidate(myGroupsProvider);
                if (context.mounted) {
                  Navigator.of(dialogContext).pop();
                  messenger.showSnackBar(const SnackBar(content: Text('그룹 정보가 수정되었습니다.')));
                }
              } catch (e) {
                if (context.mounted) {
                  messenger.showSnackBar(SnackBar(content: Text('수정 실패: $e')));
                }
              } finally {
                if (builderContext.mounted) {
                  setState(() => isSaving = false);
                }
              }
            }

            return AlertDialog(
              title: const Text('그룹 정보 수정'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: '그룹 이름',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('그룹 색상', style: bodyText1),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final colorHex in palette)
                          GestureDetector(
                            onTap: () => setState(() => selectedColor = colorHex),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Color(int.parse('0xFF${colorHex.replaceFirst('#', '')}')),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selectedColor == colorHex
                                      ? Colors.black
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : submit,
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => nameController.dispose());
  }

  void _showMoreOptions(BuildContext screenContext, WidgetRef ref, Group group) { // Use a specific name for the screen's context
    showModalBottomSheet(
      context: screenContext,
      builder: (BuildContext context) { // This is the sheet's context
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('그룹 정보 수정'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showEditGroupDialog(screenContext, ref, group);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('그룹 삭제', style: TextStyle(color: Colors.red)),
                onTap: () => _deleteGroup(screenContext, ref), // Pass the correct screenContext down
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openMemorySearch(BuildContext context, WidgetRef ref) async {
    final memoriesValue = ref.read(groupMemoriesProvider(groupId)).asData;
    final memories = memoriesValue?.value ?? [];
    if (memories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('검색할 메모가 없습니다.')),
      );
      return;
    }

    final selectedMemory = await showSearch<Memory?>(
      context: context,
      delegate: GroupMemorySearchDelegate(memories),
    );

    if (selectedMemory != null && context.mounted) {
      _showMemoryDetail(context, selectedMemory);
    }
  }

  void _showMemberList(BuildContext context, Group group) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('그룹 멤버', style: heading2),
                const SizedBox(height: 12),
                if (group.memberIds.isEmpty)
                  const Text('등록된 멤버가 없습니다.', style: bodyText2)
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: group.memberIds.length,
                      itemBuilder: (context, index) {
                        final member = group.memberIds[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.person_outline),
                          title: Text(member, style: bodyText1),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMemoryDetail(BuildContext context, Memory memory) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final createdAt = DateFormat('yyyy년 MM월 dd일 HH:mm').format(memory.createdAt);
        final photoUrl = memory.photoUrl ?? memory.thumbUrl;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('메모 상세', style: heading2),
                  const SizedBox(height: 16),
                  if (photoUrl != null && photoUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        toAbsoluteUrl(photoUrl),
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return SizedBox(
                            height: 200,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded /
                                        progress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => Container(
                          height: 200,
                          color: mutedSurfaceColor,
                          child: const Center(
                            child: Icon(Icons.broken_image, color: subTextColor),
                          ),
                        ),
                      ),
                    ),
                  if (photoUrl != null && photoUrl.isNotEmpty)
                    const SizedBox(height: 16),
                  Text(memory.text?.isNotEmpty == true ? memory.text! : '작성된 메모가 없습니다.', style: bodyText1),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.schedule, size: 16),
                        label: Text(createdAt),
                      ),
                      Chip(
                        avatar: const Icon(Icons.location_on_outlined, size: 16),
                        label: Text('${memory.latitude.toStringAsFixed(4)}, ${memory.longitude.toStringAsFixed(4)}'),
                      ),
                      if (memory.tags.isNotEmpty)
                        ...memory.tags
                            .map((tag) => Chip(label: Text('#$tag'), backgroundColor: mutedSurfaceColor)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupDetailProvider(groupId));
    final memoriesAsync = ref.watch(groupMemoriesProvider(groupId));
    final groupData = groupAsync.asData?.value;

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
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _openMemorySearch(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.people_outline),
            onPressed:
                groupData == null ? null : () => _showMemberList(context, groupData),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed:
                groupData == null ? null : () => _showMoreOptions(context, ref, groupData),
          ),
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
                                  toAbsoluteUrl(memory.thumbUrl!),
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
                            onTap: () => _showMemoryDetail(context, memory),
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

class GroupMemorySearchDelegate extends SearchDelegate<Memory?> {
  GroupMemorySearchDelegate(this.memories);

  final List<Memory> memories;

  @override
  List<Widget>? buildActions(BuildContext context) {
    if (query.isEmpty) return null;
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildResultList();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildResultList();
  }

  Widget _buildResultList() {
    final lowerQuery = query.toLowerCase();
    final filtered = lowerQuery.isEmpty
        ? memories
        : memories.where((memory) {
            final text = memory.text?.toLowerCase() ?? '';
            final matchesText = text.contains(lowerQuery);
            final matchesTag = memory.tags
                .any((tag) => tag.toLowerCase().contains(lowerQuery));
            return matchesText || matchesTag;
          }).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('일치하는 메모가 없습니다.'));
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final memory = filtered[index];
        return ListTile(
          leading: const Icon(Icons.image_outlined),
          title: Text(memory.text?.isNotEmpty == true ? memory.text! : '내용 없음'),
          subtitle: Text(
            DateFormat('yyyy.MM.dd').format(memory.createdAt),
          ),
          onTap: () => close(context, memory),
        );
      },
    );
  }
}