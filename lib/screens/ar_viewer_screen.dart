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
import 'package:ar_flutter_plugin/widgets/ar_view.dart';
import 'package:ar_memo_frontend/models/memory.dart';
import 'package:ar_memo_frontend/providers/memory_provider.dart'; // Provider import
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

  final Map<String, ARAnchor> _loadedAnchors = {}; // Change to ARAnchor

  @override
  void initState() {
    super.initState();
  }

  void onARViewCreated(
      ARSessionManager sessionManager, ARObjectManager objectManager,
      ARAnchorManager anchorManager, ARLocationManager locationManager,
      ) {
    arSessionManager = sessionManager;
    arObjectManager = objectManager;
    arAnchorManager = anchorManager;

    arSessionManager!.onInitialize(
      showFeaturePoints: false, showPlanes: true, handleTaps: true,
    );
    arObjectManager!.onInitialize();
    arSessionManager!.onPlaneOrPointTap = _onPlaneOrPointTap;

    _loadAndDisplayMemories();
  }

  Future<void> _loadAndDisplayMemories() async {
    final memoriesAsyncValue = ref.read(myMemoriesProvider);

    memoriesAsyncValue.whenData((memories) {
      if (arObjectManager == null || arAnchorManager == null || !mounted) return;
      final currentAnchorsMap = {..._loadedAnchors};
      final newAnchorsNames = <String>{};

      for (final memory in memories) {
        final transform = memory.anchorTransform;
        if (transform != null) {
          final anchorName = "memory_${memory.id}";
          newAnchorsNames.add(anchorName);
          if (!currentAnchorsMap.containsKey(anchorName)) {
            _addMemoryAnchor(memory, transform, anchorName);
          }
        } else {
          debugPrint("Anchor data invalid for memory ${memory.id}");
        }
      }

      final anchorsToRemoveNames = currentAnchorsMap.keys.toSet().difference(newAnchorsNames);
      for (final anchorNameToRemove in anchorsToRemoveNames) {
        final anchorToRemove = _loadedAnchors[anchorNameToRemove];
        if (anchorToRemove != null) {
          arAnchorManager!.removeAnchor(anchorToRemove); // Remove anchor
          _loadedAnchors.remove(anchorNameToRemove);
          debugPrint("AR Anchor Removed: $anchorNameToRemove");
        }
      }
    });
  }

  Future<void> _addMemoryAnchor(Memory memory, vector.Matrix4 transform, String anchorName) async {
    final anchor = ARPlaneAnchor(transformation: transform);
    final didAddAnchor = await arAnchorManager?.addAnchor(anchor);
    if (didAddAnchor == true) {
      _loadedAnchors[anchorName] = anchor; // Store the anchor
      debugPrint("AR Anchor Added: $anchorName");

      final node = ARNode(
        type: NodeType.localGLTF2,
        uri: "Models/frame.glb",
        scale: vector.Vector3(0.2, 0.2, 0.2),
      );
      await arObjectManager?.addNode(node, planeAnchor: anchor);
    } else {
      debugPrint("Failed to add anchor for memory ${memory.id}");
    }
  }

  Future<void> _onPlaneOrPointTap(List<ARHitTestResult> results) async {
    if (results.isEmpty || arSessionManager == null) return;

    final singleHit = results.firstWhere(
          (hit) =>
      hit.type == ARHitTestResultType.plane ||
          hit.type == ARHitTestResultType.point,
      orElse: () => results.first,
    );

    final position = singleHit.worldTransform.getTranslation();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Tap: (${position.x.toStringAsFixed(2)}, ${position.y.toStringAsFixed(2)}, ${position.z.toStringAsFixed(2)})'),
      duration: const Duration(seconds: 2),
    ));
    // _addMemoryAnchor(Memory(..), singleHit.worldTransform, "temp"); // 테스트 시
  }

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