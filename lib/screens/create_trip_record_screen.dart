import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:ar_memo_frontend/models/trip_record.dart';
import 'package:ar_memo_frontend/providers/trip_record_provider.dart';
import 'package:ar_memo_frontend/providers/upload_provider.dart';
import 'package:ar_memo_frontend/theme/colors.dart';
import 'package:ar_memo_frontend/theme/text_styles.dart';

class CreateTripRecordScreen extends ConsumerStatefulWidget {
  final TripRecord? recordToEdit; // 수정 모드를 위한 데이터
  const CreateTripRecordScreen({super.key, this.recordToEdit});

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

  final List<String> _photoUrls = []; // 최종 서버 URL 목록 (기존 + 신규)
  final List<XFile> _localFiles = []; // 새로 추가한 로컬 파일 목록
  final List<String> _removedUrls = []; // 삭제된 기존 서버 URL 목록

  bool get _isEditMode => widget.recordToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final record = widget.recordToEdit!;
      _titleController.text = record.title;
      _contentController.text = record.content;
      _selectedDate = record.date;
      _photoUrls.addAll(record.photoUrls); // 기존 이미지 URL 로드
    } else {
      _selectedDate = DateTime.now(); // 생성 모드는 오늘 날짜
    }
  }

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

  // 이미지 선택 및 업로드
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final List<XFile> pickedFiles = await picker.pickMultiImage(imageQuality: 85);
    if (pickedFiles.isEmpty || !mounted) return;

    setState(() { _isUploading = true; _localFiles.addAll(pickedFiles); });

    try {
      final repository = ref.read(uploadRepositoryProvider);
      final results = await Future.wait(pickedFiles.map((file) => repository.uploadPhoto(file)));
      // 성공한 URL만 추가
      _photoUrls.addAll(results.map((result) => result.url));
    } catch (e) {
      if (mounted) {
        for (var file in pickedFiles) {
        _localFiles.remove(file);
      }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('이미지 업로드 중 오류 발생: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
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

      // TODO: 수정 시 위치 정보 업데이트 로직 추가 (예: 지도에서 위치 다시 선택 기능)
      double? currentLat = _isEditMode ? widget.recordToEdit!.latitude : null;
      double? currentLng = _isEditMode ? widget.recordToEdit!.longitude : null;

      try {
        final notifier = ref.read(tripRecordsProvider.notifier);
        if (_isEditMode) {
          // 최종 photoUrls 목록 (삭제된 것 제외)
          final finalPhotoUrls = _photoUrls.where((url) => !_removedUrls.contains(url)).toList();

          await notifier.updateTripRecord(
            id: widget.recordToEdit!.id,
            title: _titleController.text,
            content: _contentController.text,
            date: _selectedDate!,
            photoUrls: finalPhotoUrls,
            latitude: currentLat, // 현재는 기존 위치 유지 (수정 기능 필요 시 추가)
            longitude: currentLng,
          );
          messenger.showSnackBar(const SnackBar(content: Text('일기가 수정되었습니다.')));
        } else {
          // 생성 로직은 홈 화면 팝업에서 처리
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

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // 사진 Grid
  Widget _buildPhotoGrid() {
    final List<Widget> imageWidgets = [];

    // 1. 기존 서버 이미지 (삭제되지 않은 것만)
    imageWidgets.addAll(_photoUrls
        .where((url) => !_removedUrls.contains(url)) // 삭제된 URL 제외
        .map((url) => _buildGridItem(
      key: ValueKey(url),
      imageProvider: NetworkImage(_toAbsoluteUrl(url)),
      onDelete: () => setState(() {
        _removedUrls.add(url); // 삭제 목록에 추가 (실제 삭제는 저장 시 처리)
        // _photoUrls.remove(url); // 바로 목록에서 제거해도 무방
      }),
    )));

    // 2. 새로 추가한 로컬 이미지
    imageWidgets.addAll(_localFiles.map((file) => _buildGridItem(
      key: ValueKey(file.path),
      imageProvider: FileImage(File(file.path)),
      onDelete: () {
        setState(() {
          _localFiles.remove(file);
          // 업로드 성공 후 URL 목록에 추가된 경우, 해당 URL도 제거
          _photoUrls.removeWhere((url) => url.contains(file.name));
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? '일기 수정' : '일기 쓰기', style: heading2),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1.0), child: Container(color: borderColor, height: 1.0)),
        // actions: _isEditMode ? [
        //   IconButton(icon: const Icon(Icons.delete_outline, color: subTextColor), tooltip: '삭제', onPressed: () { /* TODO: 삭제 로직 */ }),
        // ] : null, // 삭제 버튼 필요 시 활성화
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