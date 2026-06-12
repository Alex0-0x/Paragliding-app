import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

import 'models/point_detail.dart';

class ApiService {
  // Adjust this base URL to point at your API server. Use 10.0.2.2 for Android emulator.
  static const String defaultBaseUrl = 'https://10.0.2.2:7095';
  static const List<String> _devFallbacks = ['http://10.0.2.2:5022', 'https://10.0.2.2:7095'];

  // When enabled, local development spots are returned if the API is unavailable.
  static const bool useTemporaryDevSpots = true;

  static List<PointDetail> get temporaryDevSpots => [
        PointDetail(
          id: 'dev-1',
          title: 'Windy Ridge',
          description: 'A beginner-friendly launch site with gentle thermals.',
          location: LatLng(55.6761, 12.5683),
          color: Colors.green,
        ),
        PointDetail(
          id: 'dev-2',
          title: 'Eagle Point',
          description: 'High visibility and long glide distance to the landing zone.',
          location: LatLng(55.6861, 12.5483),
          color: Colors.blue,
        ),
        PointDetail(
          id: 'dev-3',
          title: 'Sunset Bluff',
          description: 'Popular spot for sunset flights and easy access.',
          location: LatLng(55.6661, 12.5783),
          color: Colors.orange,
        ),
        PointDetail(
          id: 'dev-4',
          title: 'Falcon Meadow',
          description: 'Open field launch with nearby amenities.',
          location: LatLng(55.6561, 12.5883),
          color: Colors.purple,
        ),
      ];

  static Future<List<PointDetail>> fetchParaSpots({String? baseUrl}) async {
    final candidates = <String>[];
    if (baseUrl != null) candidates.add(baseUrl);
    candidates.add(defaultBaseUrl);
    candidates.addAll(_devFallbacks);

    Exception? lastError;

    for (final candidate in candidates) {
      try {
        final url = Uri.parse('$candidate/api/ParaSpotModel');
        final resp = await http.get(url);
        if (resp.statusCode != 200) {
          lastError = Exception(
            'Failed to load para spots from $candidate: ${resp.statusCode}',
          );
          continue;
        }

        final List<dynamic> list = jsonDecode(resp.body) as List<dynamic>;
        return list
            .map((e) {
              final map = e as Map<String, dynamic>;
              final lat = (map['latitude'] ?? map['Latitude'] ?? 0).toDouble();
              final lng = (map['longitude'] ?? map['Longitude'] ?? 0)
                  .toDouble();
              final name = map['name'] ?? map['Name'] ?? 'Unnamed';
              final desc = map['description'] ?? map['Description'] ?? '';
              final safty = map['safty'] ?? map['Safty'] ?? '';

              return PointDetail(
                id: (map['id'] ?? map['Id'] ?? 0).toString(),
                title: name.toString(),
                description: [
                  desc,
                  safty,
                ].where((s) => s != null && s.toString().isNotEmpty).join('\n'),
                location: LatLng(lat, lng),
                color: Colors.green,
              );
            })
            .toList(growable: false);
      } catch (e) {
        lastError = Exception('Error fetching from $candidate: $e');
        continue;
      }
    }

    if (useTemporaryDevSpots) {
      return temporaryDevSpots;
    }

    throw lastError ?? Exception('Failed to fetch para spots (no candidates)');
  }
}
