import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 단순한 2D 맵 위젯.
///
/// 실제 카카오맵 SDK 대신 기본적인 마커 표시와 카메라 이동만 제공합니다.
class SimpleMap extends StatefulWidget {
  const SimpleMap({
    super.key,
    required this.onMapCreated,
    required this.markers,
    required this.center,
    required this.currentLevel,
    this.onMarkerTap,
    this.onInfoWindowTap,
    this.selectedMarkerId,
  });

  final ValueChanged<SimpleMapController> onMapCreated;
  final List<MapMarker> markers;
  final LatLng center;
  final double currentLevel;
  final void Function(String markerId, LatLng position, double zoomLevel)? onMarkerTap;
  final void Function(String markerId, LatLng position)? onInfoWindowTap;
  final String? selectedMarkerId;

  @override
  State<SimpleMap> createState() => _SimpleMapState();
}

class _SimpleMapState extends State<SimpleMap> {
  late LatLng _center;
  late double _zoomLevel;
  late SimpleMapController _controller;

  @override
  void initState() {
    super.initState();
    _center = widget.center;
    _zoomLevel = widget.currentLevel;
    _controller = SimpleMapController(
      onMoveCamera: _handleMoveCamera,
      onGetCenter: () async => _center,
      onGetZoomLevel: () => _zoomLevel,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onMapCreated(_controller);
    });
  }

  @override
  void didUpdateWidget(covariant SimpleMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.center != oldWidget.center) {
      _center = widget.center;
    }
    if (widget.currentLevel != oldWidget.currentLevel) {
      _zoomLevel = widget.currentLevel;
    }
  }

  void _handleMoveCamera(CameraUpdate update) {
    setState(() {
      _center = update.target ?? _center;
      _zoomLevel = update.zoom ?? _zoomLevel;
    });
  }

  Offset _project(LatLng coordinate, Size size) {
    const double baseScale = 12000;
    final double zoomFactor = math.pow(2.0, (_zoomLevel - 7.0) / 1.4) as double;
    final double scale = baseScale / zoomFactor;

    final double dx = (coordinate.longitude - _center.longitude) * scale;
    final double dy = (coordinate.latitude - _center.latitude) * scale;
    final double x = size.width / 2 + dx;
    final double y = size.height / 2 - dy;
    return Offset(x, y);
  }

  bool _isVisible(Offset offset, Size size) {
    const double margin = 48;
    return offset.dx >= -margin &&
        offset.dx <= size.width + margin &&
        offset.dy >= -margin &&
        offset.dy <= size.height + margin;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFdbeafe), Color(0xFFbfdbfe)],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _SimpleGridPainter())),
              for (final marker in widget.markers)
                Builder(
                  builder: (context) {
                    final position = _project(marker.position, size);
                    if (!_isVisible(position, size)) {
                      return const SizedBox.shrink();
                    }
                    final bool isSelected = marker.markerId == widget.selectedMarkerId;
                    return Positioned(
                      left: position.dx - 12,
                      top: position.dy - 24,
                      child: _MarkerWidget(
                        marker: marker,
                        isSelected: isSelected,
                        onTap: () {
                          widget.onMarkerTap?.call(marker.markerId, marker.position, _zoomLevel);
                        },
                        onInfoTap: widget.onInfoWindowTap == null
                            ? null
                            : () => widget.onInfoWindowTap!(marker.markerId, marker.position),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MarkerWidget extends StatelessWidget {
  const _MarkerWidget({
    required this.marker,
    required this.isSelected,
    this.onTap,
    this.onInfoTap,
  });

  final MapMarker marker;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onInfoTap;

  @override
  Widget build(BuildContext context) {
    final Color pinColor = isSelected ? Colors.redAccent : Colors.deepOrange;
    final List<Widget> children = [];
    if (isSelected && marker.infoWindow != null && marker.infoWindow!.isNotEmpty) {
      children.add(
        GestureDetector(
          onTap: onInfoTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              marker.infoWindow!,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }
    children.add(
      GestureDetector(
        onTap: onTap,
        child: Icon(Icons.location_on, size: 28, color: pinColor),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

class _SimpleGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const double spacing = 80;
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SimpleGridPainter oldDelegate) => false;
}

class SimpleMapController {
  SimpleMapController({
    required void Function(CameraUpdate update) onMoveCamera,
    required Future<LatLng> Function() onGetCenter,
    required double Function() onGetZoomLevel,
  })  : _onMoveCamera = onMoveCamera,
        _onGetCenter = onGetCenter,
        _onGetZoomLevel = onGetZoomLevel;

  final void Function(CameraUpdate update) _onMoveCamera;
  final Future<LatLng> Function() _onGetCenter;
  final double Function() _onGetZoomLevel;

  Future<LatLng> getCenter() => _onGetCenter();

  double get zoomLevel => _onGetZoomLevel();

  void moveCamera(CameraUpdate update) => _onMoveCamera(update);
}

class CameraUpdate {
  CameraUpdate._(this.target, this.zoom);

  final LatLng? target;
  final double? zoom;

  static CameraUpdate newLatLngZoom(LatLng target, double zoom) => CameraUpdate._(target, zoom);

  static CameraUpdate fromLatLngZoom(LatLng target, double zoom) => CameraUpdate._(target, zoom);
}

class LatLng {
  const LatLng(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) =>
      other is LatLng && other.latitude == latitude && other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}

class MapMarker {
  const MapMarker({
    required this.markerId,
    required this.position,
    this.infoWindow,
  });

  final String markerId;
  final LatLng position;
  final String? infoWindow;

  @override
  bool operator ==(Object other) => other is MapMarker && other.markerId == markerId;

  @override
  int get hashCode => markerId.hashCode;
}
