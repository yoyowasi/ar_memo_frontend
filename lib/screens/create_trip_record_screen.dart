import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_memo_frontend/providers/trip_record_provider.dart';
import 'package:ar_memo_frontend/theme/colors.dart';
import 'package:ar_memo_frontend/theme/text_styles.dart';
import 'package:intl/intl.dart';

class CreateTripRecordScreen extends ConsumerStatefulWidget {
  const CreateTripRecordScreen({super.key});

  @override
  ConsumerState<CreateTripRecordScreen> createState() => _CreateTripRecordScreenState();
}

class _CreateTripRecordScreenState extends ConsumerState<CreateTripRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;

  Future<void> _createTripRecord() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('날짜를 선택해주세요.')));
        return;
      }
      setState(() => _isLoading = true);
      try {
        await ref.read(tripRecordsProvider.notifier).addTripRecord(
          title: _titleController.text,
          content: _contentController.text,
          date: _selectedDate!,
        );
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('생성 실패: ${e.toString()}')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('일기 쓰기', style: heading2),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // 이미지 추가 부분 (피그마 디자인)
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  // TODO: 이미지 선택 로직 (image_picker)
                },
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined, size: 40, color: subTextColor),
                    SizedBox(height: 8),
                    Text('사진 추가하기', style: bodyText2),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '제목', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.isEmpty) ? '제목을 입력하세요' : null,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (pickedDate != null) setState(() => _selectedDate = pickedDate);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: '날짜', border: OutlineInputBorder()),
                child: Text(
                  _selectedDate == null ? '날짜를 선택하세요' : DateFormat('yyyy.MM.dd').format(_selectedDate!),
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
              onPressed: _createTripRecord,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('작성 완료', style: buttonText),
            ),
          ],
        ),
      ),
    );
  }
}