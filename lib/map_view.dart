import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import 'models/point_detail.dart';
import 'pages/point_detail_page.dart';
import 'map_tiles.dart';

class MapView extends StatefulWidget {
  final List<PointDetail> points;
  final Position currentPosition;

  const MapView({
    super.key,
    required this.points,
    required this.currentPosition,
  });

  @override
  MapViewState createState() => MapViewState();
}

class MapViewState extends State<MapView> {
  final MapController _mapController = MapController();

  void _openPointDetails(PointDetail point) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PointDetailPage(point: point)),
    );
  }

  void _recenterMap() {
    _mapController.move(
      LatLng(widget.currentPosition.latitude, widget.currentPosition.longitude),
      13,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(
              widget.currentPosition.latitude,
              widget.currentPosition.longitude,
            ),
            initialZoom: 11,
          ),
          children: [
            openSteetMapTileLayer,
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(
                    widget.currentPosition.latitude,
                    widget.currentPosition.longitude,
                  ),
                  width: 60,
                  height: 60,
                  child: const Icon(
                    Icons.my_location,
                    size: 40,
                    color: Colors.blue,
                  ),
                ),
                ...widget.points.map(
                  (point) => Marker(
                    point: point.location,
                    width: 60,
                    height: 60,
                    child: GestureDetector(
                      onTap: () => _openPointDetails(point),
                      child: Icon(
                        Icons.location_on,
                        size: 40,
                        color: point.color,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            mini: true,
            onPressed: _recenterMap,
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }
}
