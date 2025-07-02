class Weather {
  final int temperature;
  final String condition;
  final String icon;
  final DateTime time;

  Weather({
    required this.temperature,
    required this.condition,
    required this.icon,
    required this.time,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      temperature: (json['temp'] as num).round(),
      condition: json['weather'][0]['main'],
      icon: json['weather'][0]['icon'],
      time: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000, isUtc: true),
    );
  }
}
