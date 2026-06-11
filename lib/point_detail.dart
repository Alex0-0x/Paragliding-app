import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class PointDetail {
  final String id;
  final String title;
  final String description;
  final LatLng location;
  final Color color;

  const PointDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.color,
  });
}
