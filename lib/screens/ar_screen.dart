// lib/screens/ar_screen.dart
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

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
      arSessionManager.onError.call('앵커 추가 실패');
      return;
    }

    // ✅ 노드 생성
    // NodeType.localGLTF2는 .gltf/.glb 모두 지원합니다.
    final node = ARNode(
      type: NodeType.localGLTF2,
      uri: 'Models/frame.glb',
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
      arSessionManager.onError.call('노드 추가 실패');
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
        planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
      ),
    );
  }
}
