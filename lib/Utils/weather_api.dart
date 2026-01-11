import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  final String apiKey;
  WeatherService({required this.apiKey});

  Future<Map<String, dynamic>> fetchCurrentWeather(double lat, double lon) async {
    final uri = Uri.https(
      'weather.googleapis.com',
      '/v1/currentConditions:lookup',
      {
        'key': apiKey,
        'location.latitude': lat.toString(),
        'location.longitude': lon.toString(),
      },
    );

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load weather: ${response.statusCode}');
    }
  }
}
class WeatherForecastApi {
  final String apiKey;
  WeatherForecastApi({required this.apiKey});

  Future<Map<String, dynamic>> fetchForecast(double lat, double lon) async {
    final uri = Uri.https(
      'weather.googleapis.com',
      '/v1/forecast:lookup',
      {
        'key': apiKey,
        'location.latitude': lat.toString(),
        'location.longitude': lon.toString(),
      },
    );

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load weather: ${response.statusCode}');
    }
  }
}
