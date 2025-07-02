import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../models/weather.dart';

class WeatherService {
  // --- IMPORTANT: PASTE YOUR API KEY HERE ---
  final String _apiKey = '8e8b91972447e6527d3ff5da24cc63d1';
  final String _baseUrl = 'https://api.openweathermap.org/data/2.5/onecall';

  Future<List<Weather>> getHourlyForecast() async {
    try {
      Position position = await _determinePosition();
      final url =
          '$_baseUrl?lat=${position.latitude}&lon=${position.longitude}&exclude=current,minutely,daily,alerts&appid=$_apiKey&units=metric';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> hourlyData = data['hourly'];
        return hourlyData.map((json) => Weather.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      print("WeatherService Error: $e");
      return [];
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }
}
