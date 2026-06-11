import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'map_tiles.dart';
import 'point_detail.dart';

class PointDetailPage extends StatelessWidget {
  final PointDetail point;

  const PointDetailPage({super.key, required this.point});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(point.title),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                point.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                point.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 220,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: point.location,
                    initialZoom: 13,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    openSteetMapTileLayer,
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: point.location,
                          width: 60,
                          height: 60,
                          child: const Icon(
                            Icons.location_on,
                            size: 40,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Coordinates',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Latitude: ${point.location.latitude.toStringAsFixed(5)}'),
                      Text('Longitude: ${point.location.longitude.toStringAsFixed(5)}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to points'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
