import 'dart:convert';
import 'package:http/http.dart' as http;

class ForecastDay {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final String condition;
  final String iconUrl;
  final double windSpeed;
  final String windDirection;
  final double gustSpeed;
  final int rainChance;

  ForecastDay({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.condition,
    required this.iconUrl,
    required this.windSpeed,
    required this.windDirection,
    required this.gustSpeed,
    required this.rainChance,
  });

  factory ForecastDay.fromJson(Map<String, dynamic> json) {
    final day = json["day"];

    return ForecastDay(
      date: DateTime.parse(json["date"]),
      maxTemp: (day["maxtemp_c"] as num).toDouble(),
      minTemp: (day["mintemp_c"] as num).toDouble(),
      condition: day["condition"]["text"],
      iconUrl: "https:${day["condition"]["icon"]}",
      windSpeed: (day["maxwind_kph"] as num).toDouble(),
      windDirection: json["hour"][0]["wind_dir"],
      gustSpeed: (day["maxwind_kph"] as num).toDouble(),
      rainChance: int.parse(
        day["daily_chance_of_rain"].toString(),
      ),
    );
  }
}


class WeatherService {

  static const apiKey = "a8f6046bd0d6406497164959260608";


  static Future<List<ForecastDay>> getForecast(
    double lat,
    double lon,
  ) async {

    final url = Uri.parse(
      "https://api.weatherapi.com/v1/forecast.json"
      "?key=$apiKey"
      "&q=$lat,$lon"
      "&days=3"
      "&aqi=no"
      "&alerts=no",
    );


    final response = await http.get(url);


    if (response.statusCode != 200) {
      throw Exception("Failed to load forecast");
    }


    final data = jsonDecode(response.body);


    final days = data["forecast"]["forecastday"] as List;


    return days
        .map((day) => ForecastDay.fromJson(day))
        .toList();
  }
}