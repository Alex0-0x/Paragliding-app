import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherData {
  final double temperature;
  final double feelsLike;
  final String condition;
  final String iconUrl;
  final double windKph;
  final String windDirection;
  final double gustKph;
  final int humidity;
  final double uv;

  WeatherData({
    required this.temperature,
    required this.feelsLike,
    required this.condition,
    required this.iconUrl,
    required this.windKph,
    required this.windDirection,
    required this.gustKph,
    required this.humidity,
    required this.uv,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final current = json["current"];

    return WeatherData(
      temperature: (current["temp_c"] as num).toDouble(),
      feelsLike: (current["feelslike_c"] as num).toDouble(),
      condition: current["condition"]["text"],
      iconUrl: "https:${current["condition"]["icon"]}",
      windKph: (current["wind_kph"] as num).toDouble(),
      windDirection: current["wind_dir"],
      gustKph: (current["gust_kph"] as num).toDouble(),
      humidity: current["humidity"],
      uv: (current["uv"] as num).toDouble(),
    );
  }
}

class WeatherService {
  static const apiKey = "a8f6046bd0d6406497164959260608";

  static Future<WeatherData> getWeather(
      double lat,
      double lon,
      ) async {

    final url = Uri.parse(
      "https://api.weatherapi.com/v1/current.json"
      "?key=$apiKey"
      "&q=$lat,$lon"
      "&aqi=no",
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception("Failed to load weather");
    }

    return WeatherData.fromJson(jsonDecode(response.body));
  }
}