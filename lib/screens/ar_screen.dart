// lib/screens/ar_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
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

import 'package:ar_memo_frontend/providers/memory_provider.dart';

class ARScreen extends ConsumerStatefulWidget {
  const ARScreen({super.key});

  @override
  ConsumerState<ARScreen> createState() => _ARScreenState();
}

class _ARScreenState extends ConsumerState<ARScreen> {
  late ARSessionManager arSessionManager;
  late ARObjectManager arObjectManager;
  late ARAnchorManager arAnchorManager;
  bool _isSaving = false;

  Future<Position?> _getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치 서비스를 활성화해주세요.')),
        );
      }
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AR 메모 저장을 위해 위치 권한이 필요합니다.')),
        );
      }
      return null;
    }

    try {
      return Geolocator.getCurrentPosition();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('현재 위치를 가져올 수 없습니다: $e')),
        );
      }
      return null;
    }
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
    if (_isSaving) return;
    if (hits.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    ARNode? node;
    ARPlaneAnchor? anchor;

    try {
      final hit = hits.first;

      final position = await _getCurrentPosition();
      if (position == null) {
        return;
      }

      anchor = ARPlaneAnchor(transformation: hit.worldTransform);
      final didAddAnchor = await arAnchorManager.addAnchor(anchor);
      if (didAddAnchor != true) {
        arSessionManager.onError('앵커 추가 실패');
        return;
      }

      node = ARNode(
        type: NodeType.localGLTF2,
        uri: 'Models/frame.glb',
        scale: vector.Vector3(0.5, 0.5, 0.5),
      );

      final didAddNode = await arObjectManager.addNode(
        node,
        planeAnchor: anchor,
      );

      if (didAddNode != true) {
        await arAnchorManager.removeAnchor(anchor);
        arSessionManager.onError('노드 추가 실패');
        return;
      }

      final anchorData = List<double>.from(
        hit.worldTransform.storage,
        growable: false,
      );

      await ref.read(memoryCreatorProvider.notifier).createMemory(
            latitude: position.latitude,
            longitude: position.longitude,
            anchor: anchorData,
          );

      if (!mounted) return;
      debugPrint('새로운 액자 앵커와 객체가 추가되었습니다.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('새로운 AR 메모가 저장되었습니다.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (node != null) {
        await arObjectManager.removeNode(node);
      }
      if (anchor != null) {
        await arAnchorManager.removeAnchor(anchor);
      }
      if (mounted) {
        arSessionManager.onError('메모 저장에 실패했습니다: $e');
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
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
      body: Stack(
        children: [
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          if (_isSaving)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
