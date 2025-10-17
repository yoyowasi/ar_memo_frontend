// lib/screens/ar_screen.dart
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

// ar_flutter_plugin_updated
import 'package:ar_flutter_plugin_updated/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_updated/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_updated/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_updated/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_updated/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_updated/models/ar_node.dart';

class ARScreen extends StatefulWidget {
  const ARScreen({super.key});

  @override
  State<ARScreen> createState() => _ARScreenState();
}

class _ARScreenState extends State<ARScreen> {
  late ARSessionManager arSessionManager;
  late ARObjectManager arObjectManager;
  late ARAnchorManager arAnchorManager;

  void onARViewCreated(
      ARSessionManager sessionManager,
      ARObjectManager objectManager,
      ARAnchorManager anchorManager,
      ARLocationManager locationManager,
      ) {
    arSessionManager = sessionManager;
    arObjectManager = objectManager;
    arAnchorManager = anchorManager;

    // ✅ onInitialize 파라미터는 그대로 사용 가능 (0.7.3)
    arSessionManager.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      showWorldOrigin: false,
      handleTaps: true,
    );
    arObjectManager.onInitialize();

    // 탭 이벤트 핸들러 등록
    arSessionManager.onPlaneOrPointTap = _onPlaneOrPointTapped;
  }

  Future<void> _onPlaneOrPointTapped(List<ARHitTestResult> hits) async {
    if (hits.isEmpty) return;
    final hit = hits.first;

    // ✅ 앵커 생성 (0.7.3)
    final anchor = ARPlaneAnchor(transformation: hit.worldTransform);
    final didAddAnchor = await arAnchorManager.addAnchor(anchor);
    if (didAddAnchor != true) {
      arSessionManager.onError?.call('앵커 추가 실패');
      return;
    }

    // ✅ 노드 생성
    // 주의: 로컬 assets는 GLTF2(.gltf) 경로 + NodeType.localGLTF2를 사용하세요.
    // 만약 .glb만 있다면: (1) .gltf로 변환하거나  (2) URL이면 NodeType.webGLB 사용
    final node = ARNode(
      type: NodeType.localGLTF2, // ✅ 0.7.3 유효 enum
      uri: 'Models/frame.gltf',  // ✅ assets에 GLTF2를 두는 것을 권장
      scale: vector.Vector3(0.5, 0.5, 0.5),
      // 필요 시 position/rotation/eulerAngles 추가
    );

    // ✅ 0.7.3에서는 parentNodeName 대신 planeAnchor 파라미터 사용
    final didAddNode = await arObjectManager.addNode(
      node,
      planeAnchor: anchor,
    );

    if (didAddNode == true) {
      if (!mounted) return;
      debugPrint('새로운 액자 앵커와 객체가 추가되었습니다.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('여기에 메모를 추가합니다!')),
      );
    } else {
      arSessionManager.onError?.call('노드 추가 실패');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR 메모'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: ARView(
        onARViewCreated: onARViewCreated,
        // ❌ planeDetection (오류) → ✅ planeDetectionConfig
        planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
      ),
    );
  }
}
