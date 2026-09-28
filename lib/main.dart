import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import 'models/point_detail.dart';
import 'map_view.dart';
import 'pages/point_detail_page.dart';
import 'services/api_service.dart';
import 'services/favorites_service.dart';
import 'pages/favorites_list_page.dart';
import 'pages/login_page.dart';
import 'pages/events_list_page.dart';
import 'pages/settings_page.dart';
import 'models/user.dart';
import 'services/user_service.dart';

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
  bool _waitingForLocation = true;
  Object? _locationError;
  User? _currentUser;
  bool _checkingAuth = true;

  List<PointDetail> _points = [];

  Future<void> _fetchPoints() async {
    try {
      final spots = await ApiService.fetchParaSpots();
      final favorites = await FavoritesService.loadFavorites();

      // Mark points as favorited based on saved favorites
      final pointsWithFavorites = spots.map((point) {
        return point.copyWith(isFavorited: favorites.contains(point.id));
      }).toList();

      if (!mounted) return;
      setState(() {
        _points = pointsWithFavorites;
      });
    } catch (e) {
      // ignore fetch errors for now; user can retry by restarting or reloading
    }
  }

  @override
  void initState() {
    super.initState();
    _checkUserAuth();
  }

  Future<void> _checkUserAuth() async {
    try {
      final user = await UserService.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _checkingAuth = false;
        });

        // Start location tracking regardless of login status
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _startLocationTracking();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _checkingAuth = false;
        });
        // Start location tracking even if auth check fails
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _startLocationTracking();
          }
        });
      }
    }
  }

  Future<void> _startLocationTracking() async {
    if (!mounted) return;

    setState(() {
      _waitingForLocation = true;
      _locationError = null;
    });

    try {
      // Add overall timeout of 30 seconds
      final initialPosition = await getCurrentLocation().timeout(
        const Duration(seconds: 30),
        onTimeout: () async {
          throw Exception('Location request timed out. GPS may be disabled.');
        },
      );

      if (!mounted) return;

      setState(() {
        _currentPosition = initialPosition;
        _waitingForLocation = false;
        _locationError = null;
      });

      await _fetchPoints();

      _positionStreamSubscription?.cancel();
      _positionStreamSubscription =
          Geolocator.getPositionStream(
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
    if (_checkingAuth) {
      return Scaffold(body: const Center(child: CircularProgressIndicator()));
    }

    if (_waitingForLocation ||
        (_currentPosition == null && _locationError == null)) {
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
      final errorMessage =
          _locationError?.toString() ?? 'Unable to access location.';
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.gps_off, size: 72, color: Colors.orange),
                const SizedBox(height: 16),
                Text(
                  'GPS is unavailable',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(errorMessage, textAlign: TextAlign.center),
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
    final sortedPoints = [..._points]
      ..sort((a, b) {
        final distanceA = _distanceFromCurrent(a, position);
        final distanceB = _distanceFromCurrent(b, position);
        return distanceA.compareTo(distanceB);
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paragliding App'),
        actions: [
          if (_currentUser != null)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'logout') {
                  await UserService.logout();
                  setState(() {
                    _currentUser = null;
                  });
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(
                  value: 'user',
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Logged in as'),
                      Text(
                        _currentUser?.username ?? 'User',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'logout', child: Text('Logout')),
              ],
            )
          else
            TextButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
                if (result == true) {
                  final user = await UserService.getCurrentUser();
                  setState(() {
                    _currentUser = user;
                  });
                }
              },
              child: const Text(
                'Log In',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _buildBody(sortedPoints, position),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<PointDetail> sortedPoints, Position position) {
    switch (_selectedIndex) {
      case 0:
        return OrientationBuilder(
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
        );
      case 1:
        return FavoritesListPage(
          points: sortedPoints,
          currentPosition: position,
        );
      case 2:
        return EventsListPage(currentPosition: position);
      case 3:
        return SettingsPage(
          currentUser: _currentUser,
          onLogin: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
            if (result == true) {
              final user = await UserService.getCurrentUser();
              setState(() {
                _currentUser = user;
              });
            }
          },
          onLogout: () async {
            await UserService.logout();
            setState(() {
              _currentUser = null;
            });
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPointList(
    List<PointDetail> sortedPoints,
    Position currentPosition,
  ) {
    if (sortedPoints.isEmpty) {
      return const Center(
        child: Text('Server Failed to Load Points. Please try again later.'),
      );
    }
    return Scrollbar(
      thumbVisibility: true,
      thickness: 6.0,
      radius: const Radius.circular(8.0),
      child: ListView.builder(
        itemCount: sortedPoints.length,
        itemBuilder: (context, index) {
          final point = sortedPoints[index];
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
                        icon: Icon(
                          point.isFavorited ? Icons.star : Icons.star_border,
                          color: point.isFavorited ? Colors.amber : Colors.grey,
                        ),
                        onPressed: () async {
                          await FavoritesService.toggleFavorite(point.id);
                          setState(() {
                            final pointIndex = _points.indexWhere(
                              (p) => p.id == point.id,
                            );
                            if (pointIndex != -1) {
                              _points[pointIndex] = _points[pointIndex]
                                  .copyWith(
                                    isFavorited:
                                        !_points[pointIndex].isFavorited,
                                  );
                            }
                          });
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
      ),
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
    return Future.error(
      error.message ??
          'Location request timed out. Please enable GPS or try again.',
    );
  } catch (error) {
    return Future.error('Unable to get current location: $error');
  }
}
