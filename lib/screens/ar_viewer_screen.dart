import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';

import 'package:ar_memo_frontend/models/memory.dart';
import 'package:ar_memo_frontend/providers/memory_provider.dart';
import 'package:ar_memo_frontend/theme/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class ArViewerScreen extends ConsumerStatefulWidget {
  const ArViewerScreen({super.key});
  @override
  ConsumerState<ArViewerScreen> createState() => _ArViewerScreenState();
}

class _ArViewerScreenState extends ConsumerState<ArViewerScreen> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  final Map<String, ARNode> _loadedNodes = {};

  @override
  void initState() {
    super.initState();
  }

  // ARView 생성 콜백 (ar_flutter_plugin API)
  void onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) {
    arSessionManager = sessionManager;
    arObjectManager = objectManager;
    arAnchorManager = anchorManager;

    arSessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: true, // 평면 감지 시각화
      customPlaneTexturePath: null,
      showWorldOrigin: false,
      handleTaps: true,
    );
    arObjectManager!.onInitialize();

    // --- 탭 콜백 이름 수정 ---
    arSessionManager!.onPlaneOrPointTap = _onPlaneOrPointTap;
    // ----------------------

    _loadAndDisplayMemories();
  }

  // 메모리 로드 및 표시
  Future<void> _loadAndDisplayMemories() async {
    // --- Provider 이름 수정 (memoryListProvider 사용) ---
    final memoriesAsyncValue = ref.read(myMemoriesProvider);
    // ------------------------------------------------

    memoriesAsyncValue.whenData((memories) {
      if (arObjectManager == null || !mounted) return;
      final currentNodes = Map<String, ARNode>.from(_loadedNodes);
      final newNodes = <String>{};

      for (final memory in memories) {
        final transform = memory.anchorTransform;
        if (transform != null) {
          final nodeName = "memory_${memory.id}";
          newNodes.add(nodeName);
          if (!currentNodes.containsKey(nodeName)) {
            _addMemoryNode(memory, transform, nodeName).then((node) {
              _loadedNodes[nodeName] = node;
            });
          }
        } else {
          debugPrint("Anchor data invalid for memory ${memory.id}");
        }
      }

      final nodesToRemove = currentNodes.keys.toSet().difference(newNodes);
      for (final nodeNameToRemove in nodesToRemove) {
        final nodeToRemove = _loadedNodes[nodeNameToRemove];
        if (nodeToRemove != null) {
          arObjectManager!.removeNode(nodeToRemove);
          _loadedNodes.remove(nodeNameToRemove);
          debugPrint("AR Node Removed: $nodeNameToRemove");
        }
      }
    });
  }

  // 메모리 노드 추가
  Future<ARNode> _addMemoryNode(Memory memory, vector.Matrix4 transform, String nodeName) async {
    final anchor = ARPlaneAnchor(transformation: transform);
    final didAddAnchor = await arAnchorManager?.addAnchor(anchor);
    if (didAddAnchor != true) {
      throw Exception("Failed to add anchor for memory ${memory.id}");
    }

    final node = ARNode(
      type: NodeType.localGLTF2,
      uri: "Models/frame.glb",
      scale: vector.Vector3(0.2, 0.2, 0.2),
    );

    await arObjectManager?.addNode(node, planeAnchor: anchor);
    debugPrint("AR Node Added for memory ${memory.id}");
    return node;
  }

  // 평면/점 탭 콜백
  Future<void> _onPlaneOrPointTap(List<ARHitTestResult> results) async {
    if (results.isEmpty || arSessionManager == null) return;

    final singleHit = results.firstWhere(
      // --- 'point' -> 'featurePoint'로 수정 (ar_flutter_plugin API) ---
          (hit) =>
      hit.type.index == 3 || // ARHitTestResultType.plane
          hit.type.index == 0, // ARHitTestResultType.featurePoint
      // ---------------------------------------------------------
      orElse: () => results.first,
    );

    // TODO: 탭한 위치에 새 AR 메모 생성 UI 표시
    // 예: _showCreateMemoryPopup(singleHit.worldTransform);

    // --- 임시로 큐브 추가 (ar_flutter_plugin은 큐브 지원) ---
    _addTempCube(singleHit.worldTransform);
    // -------------------------------------------------
  }

  // --- 임시 큐브 추가 함수 (ar_flutter_plugin API) ---
  Future<void> _addTempCube(vector.Matrix4 transform) async {
    final anchor = ARPlaneAnchor(transformation: transform);
    final success = await arAnchorManager?.addAnchor(anchor);
    if (success != true) {
      return;
    }
    final node = ARNode(
      type: NodeType.localGLTF2,
      uri: 'Models/frame.glb',
      scale: vector.Vector3(0.05, 0.05, 0.05),
    );
    await arObjectManager?.addNode(node, planeAnchor: anchor);
  }
  // --- 함수 추가 끝 ---


  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- Provider 이름 수정 ---
    ref.watch(myMemoriesProvider).whenData((_) {
      // -------------------------
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadAndDisplayMemories();
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('AR 뷰어', style: heading2),
        backgroundColor: Colors.transparent, elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadAndDisplayMemories)],
      ),
      extendBodyBehindAppBar: true,
      body: ARView(
        onARViewCreated: onARViewCreated,
        planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
      ),
    );
  }
}