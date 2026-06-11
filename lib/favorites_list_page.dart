import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'point_detail.dart';
import 'point_detail_page.dart';
import 'favorites_service.dart';

class FavoritesListPage extends StatelessWidget {
  final List<PointDetail> points;
  final Position currentPosition;

  const FavoritesListPage({
    super.key,
    required this.points,
    required this.currentPosition,
  });

  double _distanceFromCurrent(PointDetail point, Position currentPosition) {
    return Distance().as(
      LengthUnit.Meter,
      LatLng(currentPosition.latitude, currentPosition.longitude),
      point.location,
    );
  }

  @override
  Widget build(BuildContext context) {
    final favoritePoints = points.where((p) => p.isFavorited).toList();
    final sortedFavorites = [...favoritePoints]
      ..sort((a, b) {
        final distanceA = _distanceFromCurrent(a, currentPosition);
        final distanceB = _distanceFromCurrent(b, currentPosition);
        return distanceA.compareTo(distanceB);
      });

    if (sortedFavorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_border, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No favorites yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Add points to your favorites to see them here',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: sortedFavorites.length,
      itemBuilder: (context, index) {
        final point = sortedFavorites[index];
        final distance = _distanceFromCurrent(point, currentPosition);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          child: Card(
            color: point.color.withAlpha(41),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PointDetailPage(point: point),
                  ),
                );
              },
              child: ListTile(
                title: Text(point.title),
                subtitle: Text(
                  '${point.description}\n${(distance / 1000).toStringAsFixed(1)} km away',
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.star, color: Colors.amber),
                      onPressed: () async {
                        await FavoritesService.toggleFavorite(point.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${point.title} removed from favorites',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
