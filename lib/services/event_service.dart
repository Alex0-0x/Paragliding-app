import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/event.dart';

class EventService {
  static const String _eventsKey = 'events';

  /// Get all events for a specific spot
  static Future<List<Event>> getEventsForSpot(String spotId) async {
    final allEvents = await getAllEvents();
    return allEvents.where((e) => e.spotId == spotId).toList();
  }

  /// Get all events
  static Future<List<Event>> getAllEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = prefs.getStringList(_eventsKey) ?? [];
    return eventsJson.map((json) => Event.fromJson(jsonDecode(json))).toList();
  }

  /// Create a new event
  static Future<Event> createEvent({
    required String spotId,
    required String spotTitle,
    required String userId,
    required String username,
    required DateTime dateTime,
    required String description,
  }) async {
    final event = Event(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      spotId: spotId,
      spotTitle: spotTitle,
      userId: userId,
      username: username,
      dateTime: dateTime,
      description: description,
    );

    final allEvents = await getAllEvents();
    allEvents.add(event);

    final prefs = await SharedPreferences.getInstance();
    final eventsJson = allEvents.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_eventsKey, eventsJson);

    return event;
  }

  /// Delete an event
  static Future<void> deleteEvent(String eventId) async {
    final allEvents = await getAllEvents();
    allEvents.removeWhere((e) => e.id == eventId);

    final prefs = await SharedPreferences.getInstance();
    final eventsJson = allEvents.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_eventsKey, eventsJson);
  }
}
