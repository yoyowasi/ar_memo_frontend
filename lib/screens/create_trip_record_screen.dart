// lib/screens/create_trip_record_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ar_memo_frontend/models/trip_record.dart';
import 'package:ar_memo_frontend/providers/group_provider.dart';
import 'package:ar_memo_frontend/providers/trip_record_provider.dart';
import 'package:ar_memo_frontend/providers/upload_provider.dart';
import 'package:ar_memo_frontend/theme/colors.dart';
import 'package:ar_memo_frontend/theme/text_styles.dart';
import 'package:ar_memo_frontend/screens/group_screen.dart';
import 'package:native_exif/native_exif.dart';

import '../services/native_gallery.dart';

class CreateTripRecordScreen extends ConsumerStatefulWidget {
  final TripRecord? recordToEdit;

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
  bool _isLoading = false;
  bool _isUploading = false;
  String? _selectedGroupId;
  bool _isGroupChanged = false;

  final List<String> _photoKeys = [];
  final List<String> _tempPhotoUrls = [];

  final List<XFile> _localFiles = [];

  final List<String> _removedKeys = [];
  final List<String> _removedUrls = [];

  final Map<String, String> _localFileToKey = {};
  final Map<String, String> _localFileToUrl = {};
  final Map<String, String> _keyToUrl = {};

  double? _photoLatitude;
  double? _photoLongitude;

  bool get _isEditMode => widget.recordToEdit != null;

  @override
  void initState() {
    super.initState();
    debugPrint('🔵 [initState] isEditMode=$_isEditMode');
    if (_isEditMode) {
      final record = widget.recordToEdit!;
      _titleController.text = record.title;
      _contentController.text = record.content;
      _selectedDate = record.date;

      _photoKeys.addAll(record.photoKeys);
      _tempPhotoUrls.addAll(record.photoUrls);

      for (int i = 0; i < record.photoKeys.length; i++) {
        if (i < record.photoUrls.length) {
          _keyToUrl[record.photoKeys[i]] = record.photoUrls[i];
        }
      }

      _selectedGroupId = record.group?.id ?? record.groupIdString;
      if (_selectedGroupId != null && _selectedGroupId!.isEmpty) {
        _selectedGroupId = null;
      }

      _photoLatitude = record.latitude;
      _photoLongitude = record.longitude;
      debugPrint(
          '🔵 [initState] edit-mode 기존 좌표: ${record.latitude}, ${record.longitude}');
    } else {
      _selectedDate = DateTime.now();

      if (widget.initialPhotoUrls != null) {
        _tempPhotoUrls.addAll(widget.initialPhotoUrls!);
      }
      if (widget.initialPhotoKeys != null) {
        _photoKeys.addAll(widget.initialPhotoKeys!);
      }
      if (widget.initialPhotoKeys != null && widget.initialPhotoUrls != null) {
        for (int i = 0; i < widget.initialPhotoKeys!.length; i++) {
          if (i < widget.initialPhotoUrls!.length) {
            _keyToUrl[widget.initialPhotoKeys![i]] =
            widget.initialPhotoUrls![i];
          }
        }
      }
      _selectedGroupId = null;

      _photoLatitude = widget.initialLatitude;
      _photoLongitude = widget.initialLongitude;
      debugPrint(
          '🔵 [initState] create-mode 초기 좌표: ${widget.initialLatitude}, ${widget.initialLongitude}');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      debugPrint('🟦 [didChangeDependencies] route args: $args');
      _photoLatitude ??= args['initialLatitude'] as double?;
      _photoLongitude ??= args['initialLongitude'] as double?;

      final argPhotoKeys = args['initialPhotoKeys'];
      final argPhotoUrls = args['initialPhotoUrls'];
      if (argPhotoKeys is List && _photoKeys.isEmpty) {
        _photoKeys.addAll(argPhotoKeys.cast<String>());
      }
      if (argPhotoUrls is List && _tempPhotoUrls.isEmpty) {
        _tempPhotoUrls.addAll(argPhotoUrls.cast<String>());
      }
    }
  }

  Future<bool> _ensureMediaLocationPermission() async {
    final before = await Permission.accessMediaLocation.status;
    debugPrint('🟡 [perm] ACCESS_MEDIA_LOCATION before: $before');

    if (before.isGranted) return true;

    final result = await Permission.accessMediaLocation.request();
    debugPrint('🟡 [perm] ACCESS_MEDIA_LOCATION after: $result');

    return result.isGranted;
  }

  Future<Map<String, double>?> _getExifLocation(List<XFile> files) async {
    for (final file in files) {
      debugPrint('Attempting to read EXIF from file: ${file.path}');
      try {
        final exif = await Exif.fromPath(file.path);
        final latLong = await exif.getLatLong();

        if (latLong != null) {
          debugPrint(
              'EXIF LatLong found: ${latLong.latitude}, ${latLong.longitude}');
          return {
            'latitude': latLong.latitude,
            'longitude': latLong.longitude
          };
        } else {
          debugPrint('No LatLong found in EXIF for file: ${file.path}');
        }
      } catch (e) {
        debugPrint('Error reading EXIF from ${file.path}: $e');
      }
    }
    debugPrint('No EXIF location found in any of the selected files.');
    return null;
  }

  Future<void> _pickAndUploadImage() async {
    debugPrint('🟦 [_pickAndUploadImage] start');
    if (!mounted) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final native = await NativeGallery.pickImageWithGPS();
      if (native != null) {
        debugPrint('🟢 [native] result=$native');

        final uri = native['uri'] as String?;
        final path = native['path'] as String?;
        final lat = native['latitude'] as double?;
        final lng = native['longitude'] as double?;

        if (lat != null && lng != null) {
          _photoLatitude = lat;
          _photoLongitude = lng;
          debugPrint('🟢 [native] EXIF lat=$lat, lng=$lng');
        } else {
          _photoLatitude = null;
          _photoLongitude = null;
          debugPrint('🟥 [native] EXIF 없음 → null로 보냄');
        }

        String? finalPath = path;
        if ((finalPath == null || finalPath.isEmpty) && uri != null) {
          finalPath = Uri.parse(uri).path;
        }

        if (finalPath != null && finalPath.isNotEmpty) {
          final xfile = XFile(finalPath);
          final repository = ref.read(uploadRepositoryProvider);
          final result = await repository.uploadPhoto(xfile);

          setState(() {
            _photoKeys.add(result.key);
            _tempPhotoUrls.add(result.url);

            _localFiles.add(xfile);
            _localFileToKey[xfile.path] = result.key;
            _localFileToUrl[xfile.path] = result.url;
            _keyToUrl[result.key] = result.url;
          });

          debugPrint(
              '🟢 [native-upload] file=$finalPath, key=${result.key}, url=${result.url}');
          return;
        } else {
          debugPrint('🟥 [native] path 도 없고 uri 로 변환한 path 도 없음 → picker로 폴백');
        }
      } else {
        debugPrint('🟥 [native] 결과가 null → flutter picker로 폴백');
      }

      final picker = ImagePicker();
      final List<XFile> pickedFiles = await picker.pickMultiImage();
      debugPrint('🟦 [fallback] picked count=${pickedFiles.length}');
      if (pickedFiles.isEmpty || !mounted) return;

      setState(() {
        _localFiles.addAll(pickedFiles);
      });

      final location = await _getExifLocation(pickedFiles);
      if (mounted) {
        if (location != null) {
          _photoLatitude = location['latitude'];
          _photoLongitude = location['longitude'];
          debugPrint(
              '🟢 [fallback EXIF] lat=$_photoLatitude, lng=$_photoLongitude');
        } else {
          _photoLatitude = null;
          _photoLongitude = null;
          debugPrint('🟥 [fallback EXIF] 위치 없음 → null');
        }
      }

      final repository = ref.read(uploadRepositoryProvider);
      final results = await Future.wait(
        pickedFiles.map((file) => repository.uploadPhoto(file)),
      );

      if (!mounted) return;
      setState(() {
        for (var i = 0; i < pickedFiles.length; i++) {
          final file = pickedFiles[i];
          final result = results[i];

          _photoKeys.add(result.key);
          _tempPhotoUrls.add(result.url);
          _localFileToKey[file.path] = result.key;
          _localFileToUrl[file.path] = result.url;
          _keyToUrl[result.key] = result.url;

          debugPrint('🟢 [fallback upload] file=${file.path}, key=${result.key}');
        }
      });
    } catch (e, st) {
      debugPrint('🟥 [_pickAndUploadImage] error: $e');
      debugPrint('🟥 stack: $st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 업로드 중 오류 발생: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
      debugPrint('🟦 [_pickAndUploadImage] end');
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
      await ref.refresh(myGroupsProvider.future);
    } catch (_) {}
  }

  Future<void> _submitTripRecord() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('날짜를 선택해주세요.')),
        );
        return;
      }
      setState(() => _isLoading = true);
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);

      final bool newPhotosPicked = _localFiles.isNotEmpty;
      debugPrint('🟧 [_submitTripRecord] newPhotosPicked=$newPhotosPicked');

      double? currentLat;
      double? currentLng;

      if (newPhotosPicked) {
        currentLat = _photoLatitude;
        currentLng = _photoLongitude;
      } else {
        currentLat = _photoLatitude;
        currentLng = _photoLongitude;
      }

      List<String> finalPhotoKeys = [];

      if (_isEditMode) {
        final Set<String> keys = Set.from(widget.recordToEdit!.photoKeys);
        for (final removedKey in _removedKeys) {
          keys.remove(removedKey);
        }
        keys.addAll(_localFileToKey.values);
        finalPhotoKeys = keys.toList();
      } else {
        final Set<String> keys = Set.from(widget.initialPhotoKeys ?? []);
        keys.addAll(_localFileToKey.values);
        finalPhotoKeys = keys.toList();
      }

      debugPrint('🟧 [_submitTripRecord] payload ↓↓↓');
      debugPrint('title=${_titleController.text}');
      debugPrint('date=$_selectedDate');
      debugPrint('groupId=$_selectedGroupId');
      debugPrint('photoKeys=$finalPhotoKeys');
      debugPrint('lat=$currentLat, lng=$currentLng');
      debugPrint('🟧 [_submitTripRecord] payload ↑↑↑');

      try {
        final notifier = ref.read(tripRecordsProvider.notifier);
        if (_isEditMode) {
          await notifier.updateTripRecord(
            id: widget.recordToEdit!.id,
            title: _titleController.text,
            content: _contentController.text,
            date: _selectedDate!,
            groupId: _selectedGroupId,
            isGroupIdUpdated: _isGroupChanged,
            photoUrls: finalPhotoKeys,
            latitude: currentLat,
            longitude: currentLng,
          );
          messenger.showSnackBar(
            const SnackBar(content: Text('일기가 수정되었습니다.')),
          );
        } else {
          await notifier.addTripRecord(
            title: _titleController.text,
            content: _contentController.text,
            date: _selectedDate!,
            groupId: _selectedGroupId,
            photoUrls: finalPhotoKeys,
            latitude: currentLat,
            longitude: currentLng,
          );
          messenger.showSnackBar(
            const SnackBar(content: Text('일기가 저장되었습니다.')),
          );
        }
        navigator.pop(true);
      } catch (e, stackTrace) {
        debugPrint('!!!!!!!!!!!! 저장 실패 오류 !!!!!!!!!!!!');
        debugPrint('오류: $e');
        debugPrint('스택: $stackTrace');
        debugPrint('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
        if (navigator.mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text('저장 실패: $e')),
          );
        }
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

  Widget _buildPhotoGrid() {
    final List<Widget> imageWidgets = [];

    imageWidgets.addAll(
      _tempPhotoUrls
          .where((url) => !_removedUrls.contains(url))
          .map(
            (url) => _buildGridItem(
          key: ValueKey(url),
          imageProvider: NetworkImage(url),
          onDelete: () => setState(() {
            _tempPhotoUrls.remove(url);
            _removedUrls.add(url);

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
        ),
      ),
    );

    imageWidgets.addAll(
      _localFiles.map(
            (file) => _buildGridItem(
          key: ValueKey(file.path),
          imageProvider: FileImage(File(file.path)),
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
        ),
      ),
    );

    imageWidgets.add(
      InkWell(
        key: const ValueKey('add_button'),
        onTap: _isUploading ? null : _pickAndUploadImage,
        child: Container(
          decoration: BoxDecoration(
            color: mutedSurfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Center(
            child: _isUploading
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(
              Icons.add_a_photo_outlined,
              color: subTextColor,
              size: 32,
            ),
          ),
        ),
      ),
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: imageWidgets.length,
      itemBuilder: (context, index) => imageWidgets[index],
    );
  }

  Widget _buildGridItem({
    required Key key,
    required ImageProvider imageProvider,
    required VoidCallback onDelete,
  }) {
    return Stack(
      key: key,
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image(
            image: imageProvider,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) =>
            progress == null
                ? child
                : const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            errorBuilder: (context, error, stack) => Container(
              color: Colors.grey[200],
              child: const Icon(Icons.error_outline),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: borderColor, height: 1.0),
        ),
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
            _buildPhotoGrid(),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              style: bodyText1,
              decoration: InputDecoration(
                hintText: '제목을 입력하세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                  const BorderSide(color: primaryColor, width: 1.5),
                ),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              validator: (v) =>
              (v == null || v.isEmpty) ? '제목을 입력하세요' : null,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                );
                if (pickedDate != null) {
                  setState(() => _selectedDate = pickedDate);
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: borderColor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDate == null
                          ? '날짜를 선택하세요'
                          : DateFormat('yyyy년 MM월 dd일 EEEE', 'ko_KR')
                          .format(_selectedDate!),
                      style: bodyText1.copyWith(fontSize: 16),
                    ),
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: subTextColor,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            groupsAsync.when(
              data: (groups) {
                if (_selectedGroupId != null &&
                    groups.every((g) => g.id != _selectedGroupId)) {
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
                            setState(() {
                              _selectedGroupId = value;
                              _isGroupChanged = true;
                            });
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
            TextFormField(
              controller: _contentController,
              style: bodyText1,
              decoration: InputDecoration(
                hintText: '내용을 입력하세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                  const BorderSide(color: primaryColor, width: 1.5),
                ),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                alignLabelWithHint: true,
              ),
              maxLines: 8,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitTripRecord,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: buttonText.copyWith(fontSize: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              )
                  : Text(_isEditMode ? '수정 완료' : '작성 완료'),
            ),
          ],
        ),
      ),
    );
  }
}

double? _convertDmsToDecimal(String dmsString, String ref) {
  try {
    List<String> parts = dmsString.split(',');
    if (parts.length != 3) return null;

    List<double> dms = parts.map((part) {
      List<String> div = part.split('/');
      if (div.length != 2) throw const FormatException('Invalid DMS part');
      double numerator = double.parse(div[0]);
      double denominator = double.parse(div[1]);
      if (denominator == 0) return 0.0;
      return numerator / denominator;
    }).toList();

    double decimal = dms[0] + (dms[1] / 60) + (dms[2] / 3600);

    if (ref == 'S' || ref == 'W') {
      decimal = -decimal;
    }
    return decimal;
  } catch (e) {
    debugPrint('🟥 [DMS] 변환 실패: $e');
    return null;
  }
}
