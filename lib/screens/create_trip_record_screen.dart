// lib/screens/create_trip_record_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:ar_memo_frontend/models/trip_record.dart';
import 'package:ar_memo_frontend/providers/group_provider.dart';
import 'package:ar_memo_frontend/providers/trip_record_provider.dart';
import 'package:ar_memo_frontend/providers/upload_provider.dart';
import 'package:ar_memo_frontend/theme/colors.dart';
import 'package:ar_memo_frontend/theme/text_styles.dart';
import 'package:ar_memo_frontend/screens/group_screen.dart';

class CreateTripRecordScreen extends ConsumerStatefulWidget {
  final TripRecord? recordToEdit; // 수정 모드를 위한 데이터

  // 🟢 (수정) 생성 모드 진입 시 key/url을 받음
  //    (이전 화면에서 uploadPhoto()를 호출하고 그 결과를 넘겨줌)
  final List<String>? initialPhotoKeys;
  final List<String>? initialPhotoUrls;

  final double? initialLatitude;
  final double? initialLongitude;

  const CreateTripRecordScreen({
    super.key,
    this.recordToEdit,
    this.initialPhotoKeys,
    this.initialPhotoUrls,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  ConsumerState<CreateTripRecordScreen> createState() =>
      _CreateTripRecordScreenState();
}

class _CreateTripRecordScreenState
    extends ConsumerState<CreateTripRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false; // 저장 로딩 상태
  bool _isUploading = false; // 이미지 업로드 로딩 상태
  String? _selectedGroupId;

  // 🟢 _photoKeys: DB에 저장될 최종 GCS 'key' 목록 (기존 + 신규)
  final List<String> _photoKeys = [];
  // 🟢 _tempPhotoUrls: 화면 표시에 사용할 임시 URL 목록 (기존 + 신규)
  final List<String> _tempPhotoUrls = [];

  final List<XFile> _localFiles = []; // 새로 추가한 로컬 파일 목록

  // 🟢 _removedKeys: 삭제된 *기존* GCS 'key' 목록 (수정 모드용)
  final List<String> _removedKeys = [];
  // 🟢 _removedUrls: [오류 수정] 삭제된 *기존* 임시 URL 목록 (수정 모드용)
  final List<String> _removedUrls = [];

  // 🟢 로컬 파일 ↔ 업로드된 key/url 매핑
  final Map<String, String> _localFileToKey = {};
  final Map<String, String> _localFileToUrl = {};
  // 🟢 (수정모드) 기존 Key ↔ 기존 Url 매핑
  final Map<String, String> _keyToUrl = {};


  bool get _isEditMode => widget.recordToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final record = widget.recordToEdit!;
      _titleController.text = record.title;
      _contentController.text = record.content;
      _selectedDate = record.date;

      // 🟢 (수정) 수정 모드에서는 record의 key와 url 목록을 모두 가져온다.
      _photoKeys.addAll(record.photoKeys);
      _tempPhotoUrls.addAll(record.photoUrls);

      // 🟢 key-url 매핑을 미리 만들어둔다 (삭제 시 사용)
      for(int i = 0; i < record.photoKeys.length; i++) {
        if (i < record.photoUrls.length) {
          _keyToUrl[record.photoKeys[i]] = record.photoUrls[i];
        }
      }

      _selectedGroupId = record.group?.id ?? record.groupIdString;
      if (_selectedGroupId != null && _selectedGroupId!.isEmpty) {
        _selectedGroupId = null;
      }
    } else {
      _selectedDate = DateTime.now(); // 생성 모드는 오늘 날짜
      // 🟢 (수정) 생성 모드 진입 시 key/url을 받음
      if (widget.initialPhotoUrls != null) {
        _tempPhotoUrls.addAll(widget.initialPhotoUrls!);
      }
      if (widget.initialPhotoKeys != null) {
        _photoKeys.addAll(widget.initialPhotoKeys!);
      }

      // 🟢 key-url 매핑
      if(widget.initialPhotoKeys != null && widget.initialPhotoUrls != null) {
        for(int i = 0; i < widget.initialPhotoKeys!.length; i++) {
          if (i < widget.initialPhotoUrls!.length) {
            _keyToUrl[widget.initialPhotoKeys![i]] = widget.initialPhotoUrls![i];
          }
        }
      }
      _selectedGroupId = null;
    }
  }

  // 이미지 선택 및 업로드
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final List<XFile> pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isEmpty || !mounted) return;

    setState(() {
      _isUploading = true;
      _localFiles.addAll(pickedFiles);
    });

    try {
      final repository = ref.read(uploadRepositoryProvider);
      final results = await Future.wait(
        pickedFiles.map((file) => repository.uploadPhoto(file)),
      );
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < pickedFiles.length; i++) {
          final file = pickedFiles[i];
          final result = results[i];

          // 🟢 key와 url을 각각의 목록에 추가
          _photoKeys.add(result.key);
          _tempPhotoUrls.add(result.url); // 임시 보기용 URL
          _localFileToKey[file.path] = result.key;
          _localFileToUrl[file.path] = result.url;
          _keyToUrl[result.key] = result.url; // key-url 매핑 추가
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          for (final file in pickedFiles) {
            _localFiles.remove(file);
            final removedKey = _localFileToKey.remove(file.path);
            if (removedKey != null) {
              _photoKeys.remove(removedKey);
              _keyToUrl.remove(removedKey);
            }
            final removedUrl = _localFileToUrl.remove(file.path);
            if(removedUrl != null) {
              _tempPhotoUrls.remove(removedUrl);
            }
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('이미지 업로드 중 오류 발생: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _openGroupManagement() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GroupScreen()),
    );

    if (!mounted) return;

    ref.invalidate(myGroupsProvider);
    try {
      // ignore: unused_result
      await ref.refresh(myGroupsProvider.future);
    } catch (_) {
      // 새로고침 실패 시에도 조용히 무시하고 기존 데이터 유지
    }
  }

  // 일기 저장/수정
  Future<void> _submitTripRecord() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('날짜를 선택해주세요.')));
        return;
      }
      setState(() => _isLoading = true);
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);

      double? currentLat = _isEditMode ? widget.recordToEdit!.latitude : widget.initialLatitude;
      double? currentLng = _isEditMode ? widget.recordToEdit!.longitude : widget.initialLongitude;

      // 🟢 (수정) 최종 GCS 'key' 목록을 계산합니다.
      List<String> finalPhotoKeys = [];

      if (_isEditMode) {
        // 1. 기존 key 목록 (recordToEdit.photoKeys)에서
        final Set<String> keys = Set.from(widget.recordToEdit!.photoKeys);

        // 2. 삭제된 key (_removedKeys)를 제거
        for (final removedKey in _removedKeys) {
          keys.remove(removedKey);
        }

        // 3. 새로 추가된 key (_localFileToKey.values)를 추가
        keys.addAll(_localFileToKey.values);

        finalPhotoKeys = keys.toList();

      } else {
        // 생성 모드 (초기 key + 새로 추가된 key)
        final Set<String> keys = Set.from(widget.initialPhotoKeys ?? []);
        keys.addAll(_localFileToKey.values); // _localFileToKey에 있는 모든 key 추가
        finalPhotoKeys = keys.toList();
      }

      try {
        final notifier = ref.read(tripRecordsProvider.notifier);
        if (_isEditMode) {
          // 수정 로직
          await notifier.updateTripRecord(
            id: widget.recordToEdit!.id,
            title: _titleController.text,
            content: _contentController.text,
            date: _selectedDate!,
            groupId: _selectedGroupId,
            photoUrls: finalPhotoKeys, // 🟢 최종 key 목록
            latitude: currentLat,
            longitude: currentLng,
          );
          messenger.showSnackBar(const SnackBar(content: Text('일기가 수정되었습니다.')));
        } else {
          // 생성 로직
          await notifier.addTripRecord(
            title: _titleController.text,
            content: _contentController.text,
            date: _selectedDate!,
            groupId: _selectedGroupId,
            photoUrls: finalPhotoKeys, // 🟢 최종 key 목록
            latitude: currentLat,
            longitude: currentLng,
          );
          messenger.showSnackBar(const SnackBar(content: Text('일기가 저장되었습니다.')));
        }
        navigator.pop(true); // 변경사항 알림
      } catch (e, stackTrace) {
        debugPrint('!!!!!!!!!!!! 저장 실패 오류 !!!!!!!!!!!!'); debugPrint('오류: $e'); debugPrint('스택: $stackTrace'); debugPrint('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
        if (navigator.mounted) messenger.showSnackBar(SnackBar(content: Text('저장 실패: $e'), duration: const Duration(seconds: 3)));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final record = widget.recordToEdit;
    if (record == null || _isLoading) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('일기 삭제'),
        content: const Text('정말로 이 일기를 삭제하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await ref.read(tripRecordsProvider.notifier).deleteTripRecord(record.id);
      messenger.showSnackBar(const SnackBar(content: Text('일기가 삭제되었습니다.')));
      navigator.pop(true);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // 사진 Grid
  Widget _buildPhotoGrid() {
    final List<Widget> imageWidgets = [];

    // 1. 기존 서버 이미지 (임시 URL 목록, _tempPhotoUrls)
    imageWidgets.addAll(_tempPhotoUrls
        .where((url) => !_removedUrls.contains(url)) // 🟢 삭제된 URL 제외
        .map((url) => _buildGridItem(
      key: ValueKey(url),
      imageProvider: NetworkImage(url),
      onDelete: () => setState(() {
        _tempPhotoUrls.remove(url);
        _removedUrls.add(url); // 🟢 삭제된 URL로 기록 (수정 모드용)

        // 🟢 이 URL에 매핑되는 KEY를 찾아서 _removedKeys에도 추가
        String? keyToRemove;
        _keyToUrl.forEach((key, value) {
          if (value == url) keyToRemove = key;
        });
        if (keyToRemove != null) {
          _removedKeys.add(keyToRemove!);
          _photoKeys.remove(keyToRemove);
          _keyToUrl.remove(keyToRemove);
        }
      }),
    )));

    // 2. 새로 추가한 로컬 이미지
    imageWidgets.addAll(_localFiles.map((file) => _buildGridItem(
      key: ValueKey(file.path),
      imageProvider: FileImage( File(file.path)),
      onDelete: () {
        setState(() {
          _localFiles.remove(file);
          final removedKey = _localFileToKey.remove(file.path);
          final removedUrl = _localFileToUrl.remove(file.path);
          if (removedKey != null) {
            _photoKeys.remove(removedKey);
            _keyToUrl.remove(removedKey);
          }
          if (removedUrl != null) {
            _tempPhotoUrls.remove(removedUrl);
          }
        });
      },
    )));

    // 3. 사진 추가 버튼
    imageWidgets.add(
        InkWell(
          key: const ValueKey('add_button'),
          onTap: _isUploading ? null : _pickAndUploadImage,
          child: Container(
            decoration: BoxDecoration(color: mutedSurfaceColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
            child: Center(child: _isUploading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add_a_photo_outlined, color: subTextColor, size: 32)),
          ),
        )
    );

    return GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1),
      itemCount: imageWidgets.length,
      itemBuilder: (context, index) => imageWidgets[index],
    );
  }

  // Grid 아이템 (이미지 + 삭제 버튼)
  Widget _buildGridItem({required Key key, required ImageProvider imageProvider, required VoidCallback onDelete}) {
    return Stack(
      key: key, fit: StackFit.expand,
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(12), child: Image(image: imageProvider, fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          errorBuilder: (context, error, stack) => Container(color: Colors.grey[200], child: const Icon(Icons.error_outline)),
        ),),
        Positioned(top: 4, right: 4, child: InkWell(onTap: onDelete, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, size: 16, color: Colors.white)),),),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(myGroupsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? '일기 수정' : '일기 쓰기', style: heading2),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1.0), child: Container(color: borderColor, height: 1.0)),
        actions: _isEditMode
            ? [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: subTextColor),
            tooltip: '삭제',
            onPressed: _isLoading ? null : _confirmDelete,
          ),
        ]
            : null,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildPhotoGrid(), // 사진 영역
            const SizedBox(height: 24),
            // 제목
            TextFormField(controller: _titleController, style: bodyText1, decoration: InputDecoration(hintText: '제목을 입력하세요', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderColor)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderColor)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primaryColor, width: 1.5)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)), validator: (v) => (v == null || v.isEmpty) ? '제목을 입력하세요' : null),
            const SizedBox(height: 16),
            // 날짜
            InkWell(
              onTap: () async {
                final pickedDate = await showDatePicker(context: context, initialDate: _selectedDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime.now().add(const Duration(days: 1)));
                if (pickedDate != null) setState(() => _selectedDate = pickedDate);
              },
              child: InputDecorator(decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderColor)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderColor)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(_selectedDate == null ? '날짜를 선택하세요' : DateFormat('yyyy년 MM월 dd일 EEEE', 'ko_KR').format(_selectedDate!), style: bodyText1.copyWith(fontSize: 16)),
                  const Icon(Icons.calendar_today_outlined, color: subTextColor, size: 20),
                ],),),
            ),
            groupsAsync.when(
              data: (groups) {
                if (_selectedGroupId != null &&
                    groups.every((group) => group.id != _selectedGroupId)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() {
                      _selectedGroupId = null;
                    });
                  });
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('그룹 선택', style: bodyText1),
                          TextButton.icon(
                            onPressed: _openGroupManagement,
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('그룹 만들기'),
                            style: TextButton.styleFrom(
                              foregroundColor: primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (groups.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: mutedSurfaceColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('아직 가입된 그룹이 없습니다.', style: bodyText1),
                              SizedBox(height: 4),
                              Text(
                                '그룹을 만들거나 초대를 받아서 함께 일기를 관리해보세요.',
                                style: bodyText2,
                              ),
                            ],
                          ),
                        )
                      else
                        DropdownButtonFormField<String?>(
                          value: _selectedGroupId,
                          decoration: InputDecoration(
                            hintText: '그룹을 선택하세요 (선택)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('그룹 선택 안함'),
                            ),
                            ...groups.map(
                                  (group) => DropdownMenuItem<String?>(
                                value: group.id,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: Color(group.colorValue),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Flexible(
                                      child: Text(
                                        group.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedGroupId = value);
                          },
                        ),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 16),
                child: LinearProgressIndicator(minHeight: 2),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  '그룹 정보를 불러오지 못했습니다. (${err.toString()})',
                  style: bodyText2.copyWith(color: Colors.redAccent),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 내용
            TextFormField(controller: _contentController, style: bodyText1, decoration: InputDecoration(hintText: '내용을 입력하세요', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderColor)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderColor)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primaryColor, width: 1.5)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), alignLabelWithHint: true), maxLines: 8),
            const SizedBox(height: 32),
            // 완료 버튼
            ElevatedButton(
              onPressed: _isLoading ? null : _submitTripRecord,
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), textStyle: buttonText.copyWith(fontSize: 16)),
              child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)) : Text(_isEditMode ? '수정 완료' : '작성 완료'),
            ),
          ],
        ),
      ),
    );
  }
}