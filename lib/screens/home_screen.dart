// lib/screens/home_screen.dart
import 'dart:async';

import 'package:ar_memo_frontend/models/trip_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ar_memo_frontend/providers/group_provider.dart';
import 'package:ar_memo_frontend/providers/trip_record_provider.dart';
import 'package:ar_memo_frontend/screens/trip_record_detail_screen.dart';
import 'package:ar_memo_frontend/theme/colors.dart';
import 'package:ar_memo_frontend/theme/text_styles.dart';
import 'package:ar_memo_frontend/widgets/trip_record_search_delegate.dart';

import 'package:kakao_map_sdk/kakao_map_sdk.dart';
import 'package:geolocator/geolocator.dart';
import 'package:native_exif/native_exif.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

enum RecordSortOrder {
  latest,
  oldest,
  title,
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  KakaoMapController? _mapController;

  final Map<String, String> _markerInfoWindows = {};
  final Map<String, Poi> _pois = {};
  final Map<String, LatLng> _fallbackPositions = {};
  final Map<String, KImage> _photoMarkerIcons = {};
  final Map<String, String> _photoMarkerIconSources = {};
  KImage? _poiIcon;

  String? _previouslySelectedMarkerId;
  LatLng? _currentMapCenter;
  late final PageController _recordPageController;
  late final ValueNotifier<int> _currentRecordPageNotifier;
  late final DraggableScrollableController _sheetController;
  ProviderSubscription<AsyncValue<List<TripRecord>>>? _tripRecordsSubscription;

  RecordSortOrder _sortOrder = RecordSortOrder.latest;
  String? _selectedGroupId;

  @override
  void initState() {
    super.initState();
    _recordPageController = PageController(viewportFraction: 0.88);
    _currentRecordPageNotifier = ValueNotifier<int>(0);
    _sheetController = DraggableScrollableController();
    try {
      _tripRecordsSubscription = ref.listenManual<AsyncValue<List<TripRecord>>>(
        tripRecordsProvider,
            (previous, next) {
          next.whenData((records) {
            _syncMarkers(_applyFilters(records));
          });
        },
      );
    } catch (e) {
      debugPrint('Error setting up tripRecordsSubscription: $e');
    }
  }

  @override
  void dispose() {
    _tripRecordsSubscription?.close();
    _recordPageController.dispose();
    _currentRecordPageNotifier.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  List<TripRecord> _sortRecords(List<TripRecord> records) {
    final sorted = List<TripRecord>.from(records);
    switch (_sortOrder) {
      case RecordSortOrder.latest:
        sorted.sort((a, b) => b.date.compareTo(a.date));
        break;
      case RecordSortOrder.oldest:
        sorted.sort((a, b) => a.date.compareTo(b.date));
        break;
      case RecordSortOrder.title:
        sorted.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }
    return sorted;
  }

  List<TripRecord> _applyFilters(List<TripRecord> records) {
    if (_selectedGroupId == null) {
      return records;
    }

    if (_selectedGroupId!.isEmpty) {
      return records
          .where((record) =>
      (record.group?.id ?? record.groupIdString)?.isEmpty ?? true)
          .toList();
    }

    return records
        .where((record) =>
    (record.group?.id ?? record.groupIdString) == _selectedGroupId)
        .toList();
  }

  LatLng? _resolveRecordPosition(TripRecord record) {
    if (record.latitude != null && record.longitude != null) {
      return LatLng(record.latitude!, record.longitude!);
    }

    return null;
  }

  Future<void> _syncMarkers(List<TripRecord> records) async {
    print('Syncing markers for ${records.length} records');
    final controller = _mapController;
    if (controller == null) return;

    await _preparePoiIcon();
    if (_poiIcon == null) return;

    final style = PoiStyle(icon: _poiIcon!);
    final newIds = records.map((record) => record.id).toSet();

    for (final markerId in List<String>.from(_pois.keys)) {
      if (!newIds.contains(markerId)) {
        final poi = _pois.remove(markerId);
        if (poi != null) {
          await controller.labelLayer.removePoi(poi);
        }
        _markerInfoWindows.remove(markerId);
        _photoMarkerIcons.remove(markerId);
        _photoMarkerIconSources.remove(markerId);
        _fallbackPositions.remove(markerId);
        if (_previouslySelectedMarkerId == markerId) {
          _previouslySelectedMarkerId = null;
        }
      }
    }

    for (final record in records) {
      final markerId = record.id;
      final position = _resolveRecordPosition(record);
      print('Record ${record.id}: position is $position');

      await _preparePoiIcon();
      if (_poiIcon == null) return;

      final style = PoiStyle(icon: _poiIcon!);
      final newIds = records.map((record) => record.id).toSet();

      for (final markerId in List<String>.from(_pois.keys)) {
        if (!newIds.contains(markerId)) {
          final poi = _pois.remove(markerId);
          if (poi != null) {
            await controller.labelLayer.removePoi(poi);
          }
          _markerInfoWindows.remove(markerId);
          _photoMarkerIcons.remove(markerId);
          _photoMarkerIconSources.remove(markerId);
          _fallbackPositions.remove(markerId);
          if (_previouslySelectedMarkerId == markerId) {
            _previouslySelectedMarkerId = null;
          }
        }
      }

      for (final record in records) {
        final markerId = record.id;
        final position = _resolveRecordPosition(record);

        if (position == null) {
          final poi = _pois.remove(markerId);
          if (poi != null) {
            await controller.labelLayer.removePoi(poi);
          }
          _markerInfoWindows.remove(markerId);
          _photoMarkerIcons.remove(markerId);
          _photoMarkerIconSources.remove(markerId);
          if (_previouslySelectedMarkerId == markerId) {
            _previouslySelectedMarkerId = null;
          }
          continue;
        }

        var infoTitle = record.title;
        if (record.latitude == null || record.longitude == null) {
          infoTitle += ' (위치 없음)';
        }

        final existing = _pois[markerId];
        final needsUpdate = existing == null ||
            existing.position.latitude != position.latitude ||
            existing.position.longitude != position.longitude ||
            (_markerInfoWindows[markerId] ?? '') != infoTitle;

        if (needsUpdate && existing != null) {
          await controller.labelLayer.removePoi(existing);
          _pois.remove(markerId);
          _photoMarkerIcons.remove(markerId);
        }

        if (needsUpdate) {
          final poi = await controller.labelLayer.addPoi(
            position,
            style: style,
            id: markerId,
            text: infoTitle,
            onClick: () => _onMarkerTapped(markerId),
          );
          _pois[markerId] = poi;
        }

        _markerInfoWindows[markerId] = infoTitle;
        if (record.photoUrls.isNotEmpty) {
          // 🟢 Signed URL은 매번 바뀌므로, iconSource는 GCS key로 비교 (key가 없으므로 첫번째 URL로 임시 비교)
          final latestUrl = record.photoUrls.first;
          final cachedIconSource = _photoMarkerIconSources[markerId];
          if (cachedIconSource != null && cachedIconSource != latestUrl) {
            _photoMarkerIcons.remove(markerId);
            _photoMarkerIconSources.remove(markerId);
          }
        } else {
          _photoMarkerIcons.remove(markerId);
          _photoMarkerIconSources.remove(markerId);
        }
      }
    }}

  String get _sortOrderLabel {
    switch (_sortOrder) {
      case RecordSortOrder.latest:
        return '최신순';
      case RecordSortOrder.oldest:
        return '오래된순';
      case RecordSortOrder.title:
        return '제목순';
    }
  }

  Future<void> _showSortBottomSheet() async {
    final selected = await showModalBottomSheet<RecordSortOrder>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('최신순'),
                trailing: _sortOrder == RecordSortOrder.latest
                    ? const Icon(Icons.check, color: primaryColor)
                    : null,
                onTap: () => Navigator.of(context).pop(RecordSortOrder.latest),
              ),
              ListTile(
                title: const Text('오래된순'),
                trailing: _sortOrder == RecordSortOrder.oldest
                    ? const Icon(Icons.check, color: primaryColor)
                    : null,
                onTap: () => Navigator.of(context).pop(RecordSortOrder.oldest),
              ),
              ListTile(
                title: const Text('제목순'),
                trailing: _sortOrder == RecordSortOrder.title
                    ? const Icon(Icons.check, color: primaryColor)
                    : null,
                onTap: () => Navigator.of(context).pop(RecordSortOrder.title),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || selected == null || selected == _sortOrder) return;

    setState(() {
      _sortOrder = selected;
      _currentRecordPageNotifier.value = 0;
      if (_recordPageController.hasClients) {
        _recordPageController.jumpToPage(0);
      }
    });
  }

  void _onGroupFilterChanged(String? groupId) {
    if (_selectedGroupId == groupId) return;
    setState(() {
      _selectedGroupId = groupId;
    });
    final records = ref.read(tripRecordsProvider).asData?.value ?? [];
    _syncMarkers(_applyFilters(records));
  }

  void _toggleSheetSize() {
    final controller = _sheetController;
    if (!controller.isAttached) return;
    const expanded = 0.6;
    const collapsed = 0.25;
    final current = controller.size;
    final target = current < expanded ? expanded : collapsed;
    controller.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _preparePoiIcon() async {
    if (_poiIcon != null) return;
    _poiIcon = await KImage.fromWidget(
      const Icon(Icons.place, size: 28),
      const Size(36, 36),
    );
  }

  Future<void> _onMarkerTapped(String recordId) async {
    final c = _mapController;
    if (c == null) return;

    if (_previouslySelectedMarkerId != null &&
        _previouslySelectedMarkerId != recordId) {
      final oldPoi = _pois[_previouslySelectedMarkerId];
      if (oldPoi != null) {
        final defaultStyle = PoiStyle(icon: _poiIcon);
        await c.labelLayer.removePoi(oldPoi);
        final newPoi = await c.labelLayer.addPoi(
          oldPoi.position,
          style: defaultStyle,
          id: oldPoi.id,
          text: oldPoi.text,
          onClick: () => _onMarkerTapped(oldPoi.id),
        );
        _pois[oldPoi.id] = newPoi;
      }
    }

    final records = ref.read(tripRecordsProvider).asData?.value ?? [];
    final record = records.firstWhere((r) => r.id == recordId,
        orElse: () => throw Exception("Record not found for ID: $recordId"));

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_markerInfoWindows[recordId] ?? '정보 없음'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: '상세보기',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    TripRecordDetailScreen(recordId: recordId),
              ),
            );
          },
        ),
      ),
    );

    if (record.photoUrls.isNotEmpty) {
      // 🟢 Signed URL은 매번 바뀌므로, URL 자체로 캐시 키 사용
      final latestUrl = record.photoUrls.first;
      if (_photoMarkerIconSources[recordId] != latestUrl) {
        _photoMarkerIcons.remove(recordId);
      }

      KImage? photoIcon = _photoMarkerIcons[recordId];

      if (photoIcon == null) {
        photoIcon = await KImage.fromWidget(
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                // 🟢 toAbsoluteUrl 제거 (Signed URL은 이미 절대 경로)
                  image: NetworkImage(record.photoUrls.first),
                  fit: BoxFit.cover),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.3), blurRadius: 5)
              ],
            ),
          ),
          const Size(70, 70),
        );
        _photoMarkerIcons[recordId] = photoIcon;
        _photoMarkerIconSources[recordId] = latestUrl;
      }

      final poiToUpdate = _pois[recordId];
      if (poiToUpdate != null) {
        final photoStyle = PoiStyle(icon: photoIcon);
        await c.labelLayer.removePoi(poiToUpdate);
        final newPoi = await c.labelLayer.addPoi(
          poiToUpdate.position,
          style: photoStyle,
          id: poiToUpdate.id,
          text: poiToUpdate.text,
          onClick: () => _onMarkerTapped(poiToUpdate.id),
        );
        _pois[poiToUpdate.id] = newPoi;
      }
    }

    if (record.photoUrls.isEmpty) {
      _photoMarkerIcons.remove(recordId);
      _photoMarkerIconSources.remove(recordId);
    }

    setState(() {
      _previouslySelectedMarkerId = recordId;
    });
    debugPrint('Poi Tapped: $recordId');
  }

  Future<void> _moveToCurrentUserLocation() async {
    final c = _mapController;
    if (c == null) return;

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('위치 정보 권한이 필요합니다.')),
          );
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition();
      final currentLatLng = LatLng(position.latitude, position.longitude);

      await c.moveCamera(
        CameraUpdate.newCenterPosition(currentLatLng),
        animation: CameraAnimation(500),
      );
      _currentMapCenter = currentLatLng;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('현재 위치를 가져올 수 없습니다: $e')),
      );
    }
  }

  Future<void> _refreshCenter() async {
    final c = _mapController;
    if (c == null) return;
    try {
      final cam = await c.getCameraPosition();
      _currentMapCenter = cam.position;
    } catch (_) {}
  }

  Future<void> _openTripRecord(TripRecord record) async {
    if (record.latitude != null && record.longitude != null) {
      final targetLatLng = LatLng(record.latitude!, record.longitude!);
      await _mapController?.moveCamera(
        CameraUpdate.newCenterPosition(targetLatLng),
        animation: CameraAnimation(500),
      );
      await _refreshCenter();
      await _onMarkerTapped(record.id);
    } else {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TripRecordDetailScreen(recordId: record.id),
        ),
      );
    }
  }

  Future<void> _openSearch() async {
    final records = ref.read(tripRecordsProvider).asData?.value ?? [];
    if (records.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('검색할 기록이 없습니다.')));
      return;
    }

    final selected = await showSearch<TripRecord?>(
      context: context,
      delegate: TripRecordSearchDelegate(records),
    );

    if (selected != null && mounted) {
      await _openTripRecord(selected);
    }
  }

  Widget _buildGroupFilterChip({
    required String label,
    int? count,
    required bool selected,
    required VoidCallback onSelected,
    Color? accentColor,
  }) {
    final displayLabel = count != null ? '$label ($count)' : label;
    final chipColor = accentColor ?? primaryColor;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(displayLabel),
        selected: selected,
        onSelected: (_) => onSelected(),
        labelStyle: bodyText2.copyWith(
          color: selected ? chipColor : textColor,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
        backgroundColor: Colors.white,
        selectedColor: chipColor.withOpacity(0.16),
        side: BorderSide(
          color: selected ? chipColor : Colors.grey.shade300,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }





  @override
  Widget build(BuildContext context) {
    final tripRecordsAsyncValue = ref.watch(tripRecordsProvider);
    final groupsAsyncValue = ref.watch(myGroupsProvider);

    return Scaffold(
      body: Stack(
        children: [
          KakaoMap(
            option: KakaoMapOption(
              position: _currentMapCenter ?? const LatLng(37.5665, 126.9780),
              zoomLevel: 15,
            ),
            onMapReady: (controller) async {
              _mapController = controller;
              await _preparePoiIcon();
              await _moveToCurrentUserLocation();
              final records = tripRecordsAsyncValue.asData?.value ?? [];
              await _syncMarkers(_applyFilters(records));
            },
            onCameraMoveEnd: (cameraPosition, gestureType) {
              _currentMapCenter = cameraPosition.position;
              _refreshCenter();
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text('내 일기', style: heading2),
              centerTitle: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.search, color: textColor),
                  onPressed: _openSearch,
                ),
              ],
            ),
          ),
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.25,
            minChildSize: 0.1,
            maxChildSize: 0.6,
            builder: (context, scrollController) {
              return SafeArea(
                  top: false,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _toggleSheetSize,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            controller: scrollController,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('일기 목록', style: heading3),
                                    InkWell(
                                      onTap: _showSortBottomSheet,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        child: Row(
                                          children: [
                                            Text(_sortOrderLabel, style: bodyText2),
                                            const Icon(Icons.arrow_drop_down,
                                                color: subTextColor),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              groupsAsyncValue.when(
                                data: (groups) {
                                  final allRecordsCount = tripRecordsAsyncValue.asData?.value.length ?? 0;
                                  final noGroupRecordsCount = tripRecordsAsyncValue.asData?.value.where((record) => (record.group?.id ?? record.groupIdString)?.isEmpty ?? true).length ?? 0;

                                  return SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: Row(
                                      children: [
                                        _buildGroupFilterChip(
                                          label: '전체',
                                          count: allRecordsCount,
                                          selected: _selectedGroupId == null,
                                          onSelected: () => _onGroupFilterChanged(null),
                                        ),
                                        _buildGroupFilterChip(
                                          label: '그룹 없음',
                                          count: noGroupRecordsCount,
                                          selected: _selectedGroupId == '',
                                          onSelected: () => _onGroupFilterChanged(''),
                                        ),
                                        ...groups.map((group) {
                                          final count = tripRecordsAsyncValue.asData?.value
                                              .where((record) =>
                                          (record.group?.id ?? record.groupIdString) ==
                                              group.id)
                                              .length ??
                                              0;
                                          return _buildGroupFilterChip(
                                            label: group.name,
                                            count: count,
                                            selected: _selectedGroupId == group.id,
                                            onSelected: () => _onGroupFilterChanged(group.id),
                                            accentColor: Color(group.colorValue),
                                          );
                                        }).toList(),
                                      ],
                                    ),
                                  );
                                },
                                loading: () => const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  child: LinearProgressIndicator(),
                                ),
                                error: (err, _) => Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  child: Text('그룹 정보를 불러오지 못했습니다: $err',
                                      style: bodyText2.copyWith(color: Colors.redAccent)),
                                ),
                              ),
                              tripRecordsAsyncValue.when(
                                data: (records) {
                                  final filteredRecords = _applyFilters(records);
                                  final sortedRecords = _sortRecords(filteredRecords);

                                  if (sortedRecords.isEmpty) {
                                    return const Padding(
                                      padding: EdgeInsets.all(20),
                                      child: Center(child: Text('표시할 일기가 없습니다.')),
                                    );
                                  }

                                  return SizedBox(
                                    height: 380,
                                    child: PageView.builder(
                                      controller: _recordPageController,
                                      itemCount: sortedRecords.length,
                                      onPageChanged: (index) {
                                        _currentRecordPageNotifier.value = index;
                                        final record = sortedRecords[index];
                                        if (record.latitude != null && record.longitude != null) {
                                          _mapController?.moveCamera(
                                            CameraUpdate.newCenterPosition(LatLng(record.latitude!, record.longitude!)),
                                            animation: CameraAnimation(500),
                                          );
                                          _onMarkerTapped(record.id);
                                        }
                                      },
                                      itemBuilder: (context, index) {
                                        final record = sortedRecords[index];
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                          child: _TripRecordSlideCard(
                                            record: record,
                                            onTap: () => _openTripRecord(record),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                                loading: () => const SizedBox(
                                  height: 300,
                                  child: Center(child: CircularProgressIndicator()),
                                ),
                                error: (err, _) => Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Center(child: Text('일기를 불러오지 못했습니다: $err', style: bodyText2.copyWith(color: Colors.redAccent))),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ));
            },
          ),
        ],
      ),
    );
  }
}

class _TripRecordSlideCard extends StatelessWidget {
  const _TripRecordSlideCard({
    required this.record,
    required this.onTap,
  });

  final TripRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final group = record.group;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: record.photoUrls.isNotEmpty
                    ? Image.network(
                  // 🟢 toAbsoluteUrl 제거 (Signed URL은 이미 절대 경로)
                  record.photoUrls.first,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    final expected = loadingProgress.expectedTotalBytes;
                    final loaded = loadingProgress.cumulativeBytesLoaded;
                    final progress = expected != null ? loaded / expected : null;
                    return Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: progress,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.grey,
                      size: 42,
                    ),
                  ),
                )
                    : Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.grey,
                      size: 42,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('yyyy.MM.dd').format(record.date),
                      style: bodyText2.copyWith(color: subTextColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      record.title,
                      style: bodyText1.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      record.content.isNotEmpty ? record.content : '내용이 없습니다.',
                      style: bodyText2.copyWith(height: 1.4),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          record.latitude != null && record.longitude != null
                              ? Icons.place
                              : Icons.notes,
                          size: 18,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            record.latitude != null && record.longitude != null
                                ? '지도에서 보기'
                                : '상세 정보 보기',
                            style: bodyText2.copyWith(color: primaryColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (group != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: record.groupColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              group.name,
                              style: bodyText2.copyWith(
                                fontSize: 12,
                                color: record.groupColor,
                              ),
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
      ),
    );
  }

}