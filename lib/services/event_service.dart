import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/event.dart';
import 'user_service.dart';

class EventService {
  static const String baseUrl = 'http://10.0.2.2:5022';

  static const String eventsUrl = '$baseUrl/api/Event';

  /// Get authentication headers
  static Future<Map<String, String>> _headers() async {
    final token = await UserService.getToken();

    if (token == null) {
      throw Exception('User is not logged in');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Get all events
  static Future<List<Event>> getAllEvents() async {
    final response = await http.get(
      Uri.parse(eventsUrl),
      headers: await _headers(),
    );

    if (response.statusCode == 401) {
      throw Exception('Unauthorized. Please login again.');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load events: ${response.statusCode}',
      );
    }

    final List<dynamic> data = jsonDecode(response.body);

    return data
        .map((json) => Event.fromJson(json))
        .toList();
  }

  /// Get events for a specific spot
  static Future<List<Event>> getEventsForSpot(int spotId) async {
    final events = await getAllEvents();

    return events
        .where((event) => event.spotId == spotId)
        .toList();
  }

  /// Create event
  static Future<Event> createEvent({
    required int spotId,
    required String spotTitle,
    required String userId,
    required String username,
    required DateTime dateTime,
    required String description,
  }) async {
    final eventData = 
    {
      'spotId': spotId, 
      'userName': username, 
      'paraSpotTitle': spotTitle, 
      'startDate': dateTime.toIso8601String(), 
      'description': description, 
    };

    final response = await http.post(
      Uri.parse(eventsUrl),
      headers: await _headers(),
      body: jsonEncode(eventData),
    );

    if (response.statusCode == 401) {
      throw Exception('Unauthorized. Please login again.');
    }

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception(
        'Failed to create event: '
        '${response.statusCode} ${response.body}',
      );
    }

    return Event.fromJson(
      jsonDecode(response.body),
    );
  }
}