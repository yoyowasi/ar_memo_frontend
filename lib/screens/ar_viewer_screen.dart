import 'package:ar_flutter_plugin_updated/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_updated/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_updated/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin_updated/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_updated/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_updated/models/ar_node.dart';
import 'package:ar_flutter_plugin_updated/widgets/ar_view.dart';
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

  final Set<String> _loadedNodeNames = {}; // 중복 로드 방지

  @override
  void initState() {
    super.initState();
    // initState에서는 Provider를 watch 할 수 없으므로,
    // 첫 빌드 후 또는 ARView 생성 후에 데이터를 로드합니다.
  }

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
      showPlanes: true,
      customPlaneTexturePath: null,
      showWorldOrigin: false,
      handleTaps: true,
    );
    arObjectManager!.onInitialize();

    arSessionManager!.onPlaneOrPointTap = _onPlaneOrPointTap;

    // AR View 준비 완료 후 메모리 로드 시작
    _loadAndDisplayMemories();
  }

  // 메모리 로드 및 AR 객체 표시
  Future<void> _loadAndDisplayMemories() async {
    // TODO: 현재 위치 기반 주변 메모리 로드 로직 구현 (Provider 수정 필요)
    // final memoriesAsyncValue = ref.read(nearbyMemoriesProvider); // 가정
    final memoriesAsyncValue = ref.read(memoryListProvider); // 임시: 모든 메모리 로드

    memoriesAsyncValue.whenData((memories) {
      if (arObjectManager == null || !mounted) return;

      final currentNodes = {..._loadedNodeNames}; // 현재 노드 복사
      final newNodes = <String>{}; // 새로 로드할 노드

      for (final memory in memories) {
        final transform = memory.anchorTransform;
        if (transform != null) {
          final nodeName = "memory_${memory.id}";
          newNodes.add(nodeName); // 새 노드 목록에 추가

          if (!currentNodes.contains(nodeName)) { // 현재 없으면 추가
            _addMemoryNode(memory, transform, nodeName);
            _loadedNodeNames.add(nodeName);
          }
        } else {
          debugPrint("메모리 ${memory.id}의 anchor 데이터가 유효하지 않습니다.");
        }
      }

      // 사라진 노드 제거 (현재 목록에는 없는데 이전에 로드된 노드)
      final nodesToRemove = currentNodes.difference(newNodes);
      for (final nodeNameToRemove in nodesToRemove) {
        arObjectManager!.removeNode(nodeNameToRemove);
        _loadedNodeNames.remove(nodeNameToRemove);
        debugPrint("AR 노드 제거: $nodeNameToRemove");
      }
    });
  }

  // 메모리 데이터를 AR 노드로 추가
  Future<void> _addMemoryNode(Memory memory, vector.Matrix4 transform, String nodeName) async {
    // TODO: 실제 3D 모델 파일 경로 및 설정 필요
    // 'assets/Models/frame.gltf' 파일이 존재하고 pubspec.yaml에 등록되어야 함
    final node = ARNode(
      type: NodeType.localGLTF2,
      uri: "assets/Models/frame.gltf", // 모델 경로
      scale: vector.Vector3(0.2, 0.2, 0.2), // 모델 크기
      transformation: transform, // AR 위치
      name: nodeName,
      // TODO: onTap 콜백 추가하여 메모 정보 표시
      // data: memory, // 노드에 데이터 연결 (선택적)
    );

    await arObjectManager?.addNode(node);
    debugPrint("AR 노드 추가: $nodeName");
  }

  // 평면 또는 특징점 탭 콜백
  Future<void> _onPlaneOrPointTap(List<ARHitTestResult> results) async {
    if (results.isEmpty || arSessionManager == null) return;

    final singleHit = results.firstWhere(
          (hit) =>
      hit.type == ARHitTestResultType.plane ||
          hit.type == ARHitTestResultType.point,
      orElse: () => results.first,
    );

    // TODO: 탭한 위치에 새 AR 메모 생성 UI (팝업 등) 표시
    // 예: _showCreateMemoryPopup(singleHit.worldTransform);

    final position = singleHit.worldTransform.getTranslation();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('탭 위치: (${position.x.toStringAsFixed(2)}, ${position.y.toStringAsFixed(2)}, ${position.z.toStringAsFixed(2)})'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Provider watch하여 데이터 변경 시 앵커 갱신
    // TODO: Provider 변경 시 _loadAndDisplayMemories 호출 방식 개선 필요 (중복 호출 방지)
    ref.watch(memoryListProvider).whenData((_) { // 임시: memoryListProvider 사용
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadAndDisplayMemories();
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('AR 뷰어', style: heading2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [ // 새로고침 버튼 추가
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white), // 흰색 아이콘
            tooltip: '새로고침',
            onPressed: _loadAndDisplayMemories, // 앵커 다시 로드
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: ARView(
        onARViewCreated: onARViewCreated,
        planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
      ),
    );
  }
}