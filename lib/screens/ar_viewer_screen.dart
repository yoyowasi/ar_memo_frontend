import 'dart:async';
import 'dart:math' as math;

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

  final Map<String, _PlacedContent> _placedContents = {};
  final double _nearbyRadiusMeters = 150;
  Position? _currentPosition;
  List<Memory> _latestMemories = [];
  List<Memory> _nearbyMemories = [];
  bool _isSyncingAnchors = false;

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
    if (_isSyncingAnchors) return;
    _isSyncingAnchors = true;
    final anchorManager = _arAnchorManager;
    final objectManager = _arObjectManager;
    if (objectManager == null) {
      _isSyncingAnchors = false;
      return;
    }

    try {
      final idsToKeep = <String>{};
      for (final memory in _nearbyMemories) {
        final placementId = 'memory_${memory.id}';
        idsToKeep.add(placementId);

      final transform = memory.anchorTransform;
      final shouldUseAnchor = transform != null && anchorManager != null;
      final fallbackPlacement = shouldUseAnchor ? null : _buildFallbackPlacement(memory);
      if (!shouldUseAnchor && fallbackPlacement == null) {
        continue;
      }

      final existing = _placedContents[placementId];
      if (existing != null) {
        if (shouldUseAnchor && existing.usesAnchor) {
          continue;
        }
        if (!shouldUseAnchor && !existing.usesAnchor &&
            fallbackPlacement != null &&
            _isSameFallback(existing, fallbackPlacement)) {
          continue;
        }

        await objectManager.removeNode(existing.node);
        if (existing.anchor != null && anchorManager != null) {
          await anchorManager.removeAnchor(existing.anchor!);
        }
        _placedContents.remove(placementId);
      }

      ARAnchor? anchor;
      ARNode? node;

      if (shouldUseAnchor && anchorManager != null) {
        anchor = ARPlaneAnchor(transformation: transform!);
        final didAddAnchor = await anchorManager.addAnchor(anchor);
        if (didAddAnchor != true) {
          continue;
        }

        node = ARNode(
          type: NodeType.localGLTF2,
          uri: 'Models/frame.glb',
          scale: vector.Vector3.all(0.2),
        );
        final didAddNode = await objectManager.addNode(node, planeAnchor: anchor);
        if (didAddNode != true) {
          await anchorManager.removeAnchor(anchor);
          continue;
        }
      } else if (fallbackPlacement != null) {
        node = ARNode(
          type: NodeType.localGLTF2,
          uri: 'Models/frame.glb',
          scale: vector.Vector3.all(0.2),
          position: fallbackPlacement.position,
          rotation: fallbackPlacement.rotation,
        );

        final didAddNode = await objectManager.addNode(node);
        if (didAddNode != true) {
          continue;
        }
      }

      if (node == null) {
        continue;
      }
      _placedContents[placementId] = _PlacedContent(
        anchor: anchor,
        node: node,
        usesAnchor: shouldUseAnchor,
        fallbackPosition: fallbackPlacement?.position,
        fallbackRotation: fallbackPlacement?.rotation,
      );
    }

      final idsToRemove = _placedContents.keys
          .where((id) => !idsToKeep.contains(id))
          .toList(growable: false);
      for (final id in idsToRemove) {
        final content = _placedContents.remove(id);
        if (content == null) continue;

        await objectManager.removeNode(content.node);
        if (content.anchor != null && anchorManager != null) {
          await anchorManager.removeAnchor(content.anchor!);
        }
      }
    } finally {
      _isSyncingAnchors = false;
    }
  }

  void _refreshNearbyMemories() {
    final position = _currentPosition;
    if (position == null) {
      setState(() => _nearbyMemories = []);
      if (_placedContents.isNotEmpty) {
        unawaited(_syncAnchorsWithMemories());
      }
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
    unawaited(_syncAnchorsWithMemories());
  }

  _FallbackPlacement? _buildFallbackPlacement(Memory memory) {
    final origin = _currentPosition;
    if (origin == null) return null;

    final distance = Geolocator.distanceBetween(
      origin.latitude,
      origin.longitude,
      memory.latitude,
      memory.longitude,
    );

    if (!distance.isFinite) return null;

    final clampedDistance = distance.clamp(2.5, 20.0).toDouble();
    final bearingDegrees = Geolocator.bearingBetween(
      origin.latitude,
      origin.longitude,
      memory.latitude,
      memory.longitude,
    );

    final bearingRadians = bearingDegrees * (math.pi / 180.0);
    final offsetX = clampedDistance * math.sin(bearingRadians);
    final offsetZ = -clampedDistance * math.cos(bearingRadians);

    return _FallbackPlacement(
      position: vector.Vector3(offsetX, 0.6, offsetZ),
      rotation: vector.Vector4(0.0, 1.0, 0.0, bearingRadians),
    );
  }

  bool _isSameFallback(_PlacedContent existing, _FallbackPlacement candidate) {
    final previousPosition = existing.fallbackPosition;
    final previousRotation = existing.fallbackRotation;
    if (previousPosition == null || previousRotation == null) {
      return false;
    }

    final positionDelta = (previousPosition - candidate.position).length;
    final rotationDelta = (previousRotation.w - candidate.rotation.w).abs();

    return positionDelta < 0.4 && rotationDelta < 0.2;
  }

  Future<void> _onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager _,
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
              unawaited(_syncAnchorsWithMemories());
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
    if (_placedContents.isNotEmpty) {
      final objectManager = _arObjectManager;
      final anchorManager = _arAnchorManager;
      for (final content in _placedContents.values) {
        objectManager?.removeNode(content.node);
        final anchor = content.anchor;
        if (anchor != null) {
          anchorManager?.removeAnchor(anchor);
        }
      }
      _placedContents.clear();
    }
    _arSessionManager?.dispose();
    super.dispose();
  }
}

class _FallbackPlacement {
  const _FallbackPlacement({required this.position, required this.rotation});

  final vector.Vector3 position;
  final vector.Vector4 rotation;
}

class _PlacedContent {
  const _PlacedContent({
    this.anchor,
    required this.node,
    required this.usesAnchor,
    this.fallbackPosition,
    this.fallbackRotation,
  });

  final ARAnchor? anchor;
  final ARNode node;
  final bool usesAnchor;
  final vector.Vector3? fallbackPosition;
  final vector.Vector4? fallbackRotation;
}
