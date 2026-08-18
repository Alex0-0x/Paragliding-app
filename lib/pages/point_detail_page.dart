import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import '../map_tiles.dart';
import '../models/point_detail.dart';
import '../services/favorites_service.dart';
import '../services/event_service.dart';
import '../services/user_service.dart';
import '../models/user.dart';
import '../models/event.dart';
import 'login_page.dart';
import '../services/weather_service.dart';

class PointDetailPage extends StatefulWidget {
  final PointDetail point;

  const PointDetailPage({super.key, required this.point});

  @override
  State<PointDetailPage> createState() => _PointDetailPageState();
}

class _PointDetailPageState extends State<PointDetailPage> {
  late bool _isFavorited;
  late Future<List<Event>> _eventsFuture;
  User? _currentUser;
  late Future<List<ForecastDay>> _forecastFuture;

  @override
  void initState() {
    super.initState();
    _isFavorited = widget.point.isFavorited;
    _eventsFuture = EventService.getEventsForSpot(widget.point.id);
    _loadCurrentUser();
    _forecastFuture = WeatherService.getForecast(
  widget.point.location.latitude,
  widget.point.location.longitude,
);
  }

  Future<void> _loadCurrentUser() async {
    final user = await UserService.getCurrentUser();
    setState(() {
      _currentUser = user;
    });
  }

  Future<void> _toggleFavorite() async {
    await FavoritesService.toggleFavorite(widget.point.id);
    setState(() {
      _isFavorited = !_isFavorited;
    });
  }

  void _showCreateEventDialog() {
    if (_currentUser == null) {
      // Navigate to login page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      ).then((loggedIn) {
        // After login, reload user and show create event dialog
        if (loggedIn == true) {
          _loadCurrentUser();
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && _currentUser != null) {
              _showCreateEventDialogInternal();
            }
          });
        }
      });
      return;
    }
    _showCreateEventDialogInternal();
  }

  void _showCreateEventDialogInternal() {
    showDialog(
      context: context,
      builder: (context) => CreateEventDialog(
        spot: widget.point,
        currentUser: _currentUser,
        onEventCreated: () {
          setState(() {
            _eventsFuture = EventService.getEventsForSpot(widget.point.id);
          });
        },
      ),
    );
  }

  Future<void> _giveDirection() async {
    final latitude = widget.point.location.latitude;
    final longitude = widget.point.location.longitude;
    Uri uri;
    if (Platform.isAndroid) {
      uri = Uri.parse(
        'google.navigation:q=$latitude,$longitude&mode=d',
      );
    } else if (Platform.isIOS) {
      uri = Uri.parse(
        'http://maps.apple.com/?daddr=$latitude,$longitude&dirflg=d',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Directions not supported on this platform'),
        ),
      );
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.point.title),
        actions: [
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(
              _isFavorited ? Icons.star : Icons.star_border,
              color: _isFavorited ? Colors.amber : null,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.point.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                widget.point.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 220,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: widget.point.location,
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
                          point: widget.point.location,
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
              const SizedBox(height: 20),

FutureBuilder<List<ForecastDay>>(
  future: _forecastFuture,
  builder: (context, snapshot) {

    if (snapshot.connectionState ==
        ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }


    if (snapshot.hasError) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            "Unable to load forecast",
          ),
        ),
      );
    }


    final forecast = snapshot.data!;


    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [

        Text(
          "3 Day Forecast",
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),


        const SizedBox(height: 12),


        ...forecast.map(
          (day) => Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(12),
              child: Row(
                children: [

                  Image.network(
                    day.iconUrl,
                    width: 50,
                  ),


                  const SizedBox(width: 12),


                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [

                        Text(
                          "${day.date.day}/${day.date.month}",
                          style: const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        Text(day.condition),

                        Text(
                          "${day.minTemp}° - ${day.maxTemp}°C",
                        ),

                      ],
                    ),
                  ),


                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.end,
                    children: [

                      Text(
                        "💨 ${day.windSpeed} km/h",
                      ),

                      Text(
                        day.windDirection,
                      ),

                      Text(
                        "🌧 ${day.rainChance}%",
                      ),

                    ],
                  ),

                ],
              ),
            ),
          ),
        ),

      ],
    );
  },
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
                      Text(
                        'Latitude: ${widget.point.location.latitude.toStringAsFixed(5)}',
                      ),
                      Text(
                        'Longitude: ${widget.point.location.longitude.toStringAsFixed(5)}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _showCreateEventDialog,
                icon: const Icon(Icons.event),
                label: const Text('Create Event'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _giveDirection,
                icon: const Icon(Icons.directions),
                label: const Text('Get Directions'),
              ),
              const SizedBox(height: 24),
              Text(
                'Events at this spot',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<Event>>(
                future: _eventsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final events = snapshot.data ?? [];
                  if (events.isEmpty) {
                    return Card(
                      color: Colors.grey[100],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            'No events yet for this spot',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    event.username,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${event.dateTime.month}/${event.dateTime.day} at ${event.dateTime.hour}:${event.dateTime.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              if (event.description.isNotEmpty)
                                Text(
                                  event.description,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
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

class CreateEventDialog extends StatefulWidget {
  final PointDetail spot;
  final User? currentUser;
  final VoidCallback onEventCreated;

  const CreateEventDialog({
    super.key,
    required this.spot,
    required this.currentUser,
    required this.onEventCreated,
  });

  @override
  State<CreateEventDialog> createState() => _CreateEventDialogState();
}

class _CreateEventDialogState extends State<CreateEventDialog> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createEvent() async {
    if (widget.currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      final eventDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      await EventService.createEvent(
        spotId: widget.spot.id,
        spotTitle: widget.spot.title,
        userId: widget.currentUser!.id,
        username: widget.currentUser!.username,
        dateTime: eventDateTime,
        description: _descriptionController.text,
      );

      if (mounted) {
        widget.onEventCreated();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating event: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Event'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'at ${widget.spot.title}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Date'),
              subtitle: Text(
                '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
            ),
            ListTile(
              title: const Text('Time'),
              subtitle: Text(_selectedTime.format(context)),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (time != null) {
                  setState(() => _selectedTime = time);
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
                hintText: 'e.g., Looking for flying partners',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createEvent,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
