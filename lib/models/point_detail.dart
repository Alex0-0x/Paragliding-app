import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class PointDetail {
  final String id;
  final String title;
  final String description;
  final LatLng location;
  final Color color;
  bool isFavorited;

  PointDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.color,
    this.isFavorited = false,
  });

  /// Create a copy with modified fields
  PointDetail copyWith({bool? isFavorited}) {
    return PointDetail(
      id: id,
      title: title,
      description: description,
      location: location,
      color: color,
      isFavorited: isFavorited ?? this.isFavorited,
    );
  }
}
