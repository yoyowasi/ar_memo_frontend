import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:ar_memo_frontend/models/trip_record.dart';
import 'package:ar_memo_frontend/providers/trip_record_provider.dart';
import 'package:ar_memo_frontend/providers/upload_provider.dart';
import 'package:ar_memo_frontend/theme/colors.dart';
import 'package:ar_memo_frontend/theme/text_styles.dart';

class CreateTripRecordScreen extends ConsumerStatefulWidget {
  final TripRecord? recordToEdit;
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
  bool _isLoading = false;
  bool _isUploading = false;
  final List<String> _photoUrls = [];

  bool get _isEditMode => widget.recordToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final record = widget.recordToEdit!;
      _titleController.text = record.title;
      _contentController.text = record.content;
      _selectedDate = record.date;
      _photoUrls.addAll(record.photoUrls);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked =
    await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked == null || !mounted) return;

    setState(() => _isUploading = true);
    try {
      final repository = ref.read(uploadRepositoryProvider);
      final result = await repository.uploadPhoto(picked);
      setState(() => _photoUrls.add(result.url));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 업로드에 실패했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _submitTripRecord() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('날짜를 선택해주세요.')));
        return;
      }
      setState(() => _isLoading = true);

      // 비동기 작업 전 context 사용 변수 선언
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);

      try {
        final notifier = ref.read(tripRecordsProvider.notifier);
        if (_isEditMode) {
          await notifier.updateTripRecord(
            id: widget.recordToEdit!.id,
            title: _titleController.text,
            content: _contentController.text,
            date: _selectedDate!,
            photoUrls: _photoUrls,
          );
        } else {
          await notifier.addTripRecord(
            title: _titleController.text,
            content: _contentController.text,
            date: _selectedDate!,
            photoUrls: _photoUrls,
          );
        }
        navigator.pop(true);
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('저장 실패: ${e.toString()}')));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? '일기 수정' : '일기 쓰기', style: heading2),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_photoUrls.isEmpty)
                    InkWell(
                      onTap: _isUploading ? null : _pickAndUploadImage,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isUploading)
                            const CircularProgressIndicator()
                          else
                            const Icon(Icons.add_a_photo_outlined,
                                size: 40, color: subTextColor),
                          const SizedBox(height: 8),
                          Text(_isUploading ? '업로드 중...' : '사진 추가하기',
                              style: bodyText2),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final photoUrl = _photoUrls[index];
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  photoUrl,
                                  width: 160,
                                  height: 160,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: InkWell(
                                  onTap: () =>
                                      setState(() => _photoUrls.removeAt(index)),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black54,
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(Icons.close,
                                        size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemCount: _photoUrls.length,
                      ),
                    ),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: ElevatedButton.icon(
                      onPressed: _isUploading ? null : _pickAndUploadImage,
                      icon: _isUploading
                          ? const SizedBox(
                        height: 16,
                        width: 16,
                        child:
                        CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(Icons.add_a_photo_outlined, size: 16),
                      label: Text(_isUploading ? '업로드 중' : '추가'),
                      style: ElevatedButton.styleFrom(
                        // withOpacity 경고 수정
                        backgroundColor: const Color.fromRGBO(0, 0, 0, 0.6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        textStyle: bodyText2.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                  labelText: '제목', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.isEmpty) ? '제목을 입력하세요' : null,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (pickedDate != null) setState(() => _selectedDate = pickedDate);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                    labelText: '날짜', border: OutlineInputBorder()),
                child: Text(
                  _selectedDate == null
                      ? '날짜를 선택하세요'
                      : DateFormat('yyyy.MM.dd').format(_selectedDate!),
                  style: bodyText1.copyWith(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: '내용',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 8,
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: _submitTripRecord,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(_isEditMode ? '수정 완료' : '작성 완료',
                  style: buttonText),
            ),
          ],
        ),
      ),
    );
  }
}