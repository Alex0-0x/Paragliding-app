import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import 'point_detail.dart';
import 'map_view.dart';
import 'point_detail_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paragliding App',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
      ),
      home: const MyHomePage(title: 'Paragliding App'),

    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _permissionRationaleShown = false;
  bool _waitingForLocation = true;
  Object? _locationError;

  final List<PointDetail> points = const [
    PointDetail(
      id: '1',
      title: 'Point 1',
      description: 'High launch site with good wind shelter.',
      location: LatLng(55.6761, 12.5683),
      color: Colors.blue,
    ),
    PointDetail(
      id: '2',
      title: 'Point 2',
      description: 'Open ridge with scenic landing area.',
      location: LatLng(55.6838, 12.5710),
      color: Colors.red,
    ),
    PointDetail(
      id: '3',
      title: 'Point 3',
      description: 'Calm valley spot for beginners.',
      location: LatLng(55.6715, 12.5652),
      color: Colors.green,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startLocationTracking();
      }
    });
  }

  Future<void> _startLocationTracking() async {
    if (!_permissionRationaleShown) {
      _permissionRationaleShown = true;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text('Location permission needed'),
            content: const Text(
              'This app uses your location to sort points by distance and to center the map on your current position. '
              'Please allow location access when prompted.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }

    setState(() {
      _waitingForLocation = true;
      _locationError = null;
    });

    try {
      final initialPosition = await getCurrentLocation();
      if (!mounted) return;

      setState(() {
        _currentPosition = initialPosition;
        _waitingForLocation = false;
        _locationError = null;
      });

      _positionStreamSubscription?.cancel();
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 10,
        ),
      ).listen(
        (position) {
          if (!mounted) return;
          setState(() {
            _currentPosition = position;
            _locationError = null;
          });
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _locationError = error;
          });
        },
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _currentPosition = null;
        _waitingForLocation = false;
        _locationError = error;
      });
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_waitingForLocation || (_currentPosition == null && _locationError == null)) {
      return Scaffold(
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Getting location..."),
            ],
          ),
        ),
      );
    }

    if (_locationError != null) {
      final errorMessage = _locationError?.toString() ?? 'Unable to access location.';
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.gps_off,
                  size: 72,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                Text(
                  'GPS is unavailable',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                ),
                if (errorMessage.toLowerCase().contains('denied') ||
                    errorMessage.toLowerCase().contains('disabled')) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Please enable GPS access so we can center the map and sort points by distance.',
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _startLocationTracking,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry location'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final position = _currentPosition!;
    final sortedPoints = [...points]
      ..sort((a, b) {
        final distanceA = _distanceFromCurrent(a, position);
        final distanceB = _distanceFromCurrent(b, position);
        return distanceA.compareTo(distanceB);
      });

    return Scaffold(
      body: OrientationBuilder(
        builder: (context, orientation) {
          return orientation == Orientation.portrait
              ? Column(
                  children: [
                    Expanded(
                      flex: 2,
                      child: MapView(
                        points: sortedPoints,
                        currentPosition: position,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: _buildPointList(sortedPoints, position),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: MapView(
                        points: sortedPoints,
                        currentPosition: position,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: _buildPointList(sortedPoints, position),
                    ),
                  ],
                );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Points',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildPointList(List<PointDetail> sortedPoints, Position currentPosition) {
    return ListView.builder(
      itemCount: sortedPoints.length,
      itemBuilder: (context, index) {
        final point = sortedPoints[index];
        final distance = _distanceFromCurrent(point, currentPosition);
        return Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
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
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          ),
        );
      },
    );
  }

  double _distanceFromCurrent(PointDetail point, Position currentPosition) {
    return Distance().as(
      LengthUnit.Meter,
      LatLng(currentPosition.latitude, currentPosition.longitude),
      point.location,
    );
  }
}

Future<Position> getCurrentLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Check if location services are enabled
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services are disabled.');
  }

  // Check for location permissions
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error(
      'Location permissions are permanently denied, we cannot request permissions.',
    );
  }

  // If permissions are granted, get the current position.
  try {
    return await Geolocator.getCurrentPosition().timeout(
      const Duration(seconds: 12),
      onTimeout: () async {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          return lastKnown;
        }
        throw TimeoutException(
          'Location request timed out. Please make sure GPS is enabled.',
        );
      },
    );
  } on TimeoutException catch (error) {
    return Future.error(error.message ??
        'Location request timed out. Please enable GPS or try again.');
  } catch (error) {
    return Future.error('Unable to get current location: $error');
  }
}

