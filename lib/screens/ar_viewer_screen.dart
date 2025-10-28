import 'dart:async';

import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

import 'package:ar_memo_frontend/models/memory.dart';
import 'package:ar_memo_frontend/providers/memory_provider.dart';
import 'package:ar_memo_frontend/theme/text_styles.dart';
import 'package:ar_memo_frontend/utils/url_utils.dart';

class ARViewerScreen extends ConsumerStatefulWidget {
  const ARViewerScreen({super.key});

  @override
  ConsumerState<ARViewerScreen> createState() => _ARViewerScreenState();
}

class _ARViewerScreenState extends ConsumerState<ARViewerScreen> {
  ARSessionManager? _arSessionManager;
  ARObjectManager? _arObjectManager;
  ARAnchorManager? _arAnchorManager;

  final Map<String, ARAnchor> _loadedAnchors = {};
  final double _nearbyRadiusMeters = 150;
  Position? _currentPosition;
  List<Memory> _latestMemories = [];
  List<Memory> _nearbyMemories = [];

  @override
  void initState() {
    super.initState();
    ref.listen<AsyncValue<List<Memory>>>(
      myMemoriesProvider,
      (_, next) => next.whenOrNull(
        data: (memories) {
          _latestMemories = memories;
          _refreshNearbyMemories();
          unawaited(_syncAnchorsWithMemories());
        },
      ),
    );

    ref.read(myMemoriesProvider).whenOrNull(
          data: (memories) {
            _latestMemories = memories;
            _refreshNearbyMemories();
          },
        );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _ensureLocationReady();
      }
    });
  }

  Future<void> _ensureLocationReady() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AR 근처 메모를 보려면 위치 권한이 필요합니다.')),
      );
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    if (!mounted) return;
    setState(() {
      _currentPosition = position;
    });
    _refreshNearbyMemories();
  }

  Future<void> _syncAnchorsWithMemories() async {
    final anchorManager = _arAnchorManager;
    final objectManager = _arObjectManager;
    if (anchorManager == null || objectManager == null) return;

    final anchorsToKeep = <String>{};
    for (final memory in _latestMemories) {
      final transform = memory.anchorTransform;
      if (transform == null) continue;

      final anchorId = 'memory_${memory.id}';
      anchorsToKeep.add(anchorId);
      if (_loadedAnchors.containsKey(anchorId)) continue;

      final anchor = ARPlaneAnchor(transformation: transform);
      final didAddAnchor = await anchorManager.addAnchor(anchor);
      if (didAddAnchor == true) {
        _loadedAnchors[anchorId] = anchor;
        final node = ARNode(
          type: NodeType.localGLTF2,
          uri: 'Models/frame.glb',
          scale: vector.Vector3.all(0.2),
        );
        await objectManager.addNode(node, planeAnchor: anchor);
      }
    }

    final anchorsToRemove = _loadedAnchors.keys
        .where((name) => !anchorsToKeep.contains(name))
        .toList(growable: false);
    for (final name in anchorsToRemove) {
      final anchor = _loadedAnchors.remove(name);
      if (anchor != null) {
        await anchorManager.removeAnchor(anchor);
      }
    }
  }

  void _refreshNearbyMemories() {
    final position = _currentPosition;
    if (position == null) {
      setState(() => _nearbyMemories = []);
      return;
    }

    final nearby = _latestMemories.where((memory) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        memory.latitude,
        memory.longitude,
      );
      return distance <= _nearbyRadiusMeters;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    setState(() => _nearbyMemories = nearby);
  }

  Future<void> _onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager,
  ) async {
    _arSessionManager = arSessionManager;
    _arObjectManager = arObjectManager;
    _arAnchorManager = arAnchorManager;

    await _arSessionManager?.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      showWorldOrigin: false,
      handleTaps: true,
    );
    await _arObjectManager?.onInitialize();

    _arSessionManager?.onPlaneOrPointTap = (hits) async {
      if (hits.isEmpty) return;
      final hit = hits.first;
      final anchor = ARPlaneAnchor(transformation: hit.worldTransform);
      final didAddAnchor = await _arAnchorManager?.addAnchor(anchor) ?? false;
      if (!didAddAnchor) return;

      final node = ARNode(
        type: NodeType.webGLB,
        uri:
            'https://github.com/KhronosGroup/glTF-Sample-Models/raw/master/2.0/Cube/glTF-Binary/Cube.glb',
        scale: vector.Vector3.all(0.1),
      );
      await _arObjectManager?.addNode(node, planeAnchor: anchor);
    };

    await _syncAnchorsWithMemories();
  }

  Widget _buildNearbyOverlay(AsyncValue<List<Memory>> memoriesAsync) {
    if (memoriesAsync.isLoading && _nearbyMemories.isEmpty) {
      return const SizedBox(
        height: 56,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_nearbyMemories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          '근처 메모 없음',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _nearbyMemories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final memory = _nearbyMemories[index];
          final imageUrl = memory.thumbUrl ?? memory.photoUrl;
          return GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${memory.createdAt.year}년 메모 선택: ${memory.id}')),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 92,
                height: 92,
                color: Colors.white24,
                child: imageUrl == null
                    ? const Icon(Icons.image_not_supported, color: Colors.white)
                    : Image.network(
                        toAbsoluteUrl(imageUrl),
                        fit: BoxFit.cover,
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final memoriesAsync = ref.watch(myMemoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AR 뷰어', style: heading2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              _ensureLocationReady();
              _syncAnchorsWithMemories();
            },
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          ARView(
            onARViewCreated: _onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _buildNearbyOverlay(memoriesAsync),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _arSessionManager?.dispose();
    _arObjectManager?.dispose();
    super.dispose();
  }
}
