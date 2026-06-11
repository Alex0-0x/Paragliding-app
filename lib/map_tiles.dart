import 'package:flutter_map/flutter_map.dart';

TileLayer get openSteetMapTileLayer => TileLayer(
  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'dk.dev.paragliding_app',
);
