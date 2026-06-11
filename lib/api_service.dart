import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

import 'point_detail.dart';

class ApiService {
  // Adjust this base URL to point at your API server. Use 10.0.2.2 for Android emulator.
  static const String defaultBaseUrl = 'https://10.0.2.2:7095';
  static const List<String> _devFallbacks = ['http://10.0.2.2:5022', 'https://10.0.2.2:7095'];

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

    throw lastError ?? Exception('Failed to fetch para spots (no candidates)');
  }
}
