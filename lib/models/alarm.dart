class Alarm {
  final String id;
  final String label;
  final DateTime time;
  final bool isActive;
  final List<int> days;
  final String sound; // NEW: To store the sound asset path

  Alarm({
    required this.id,
    required this.label,
    required this.time,
    required this.isActive,
    required this.days,
    required this.sound,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'time': time.toIso8601String(),
      'isActive': isActive,
      'days': days,
      'sound': sound, // NEW
    };
  }

  factory Alarm.fromJson(Map<String, dynamic> json) {
    return Alarm(
      id: json['id'],
      label: json['label'],
      time: DateTime.parse(json['time']),
      isActive: json['isActive'],
      days: List<int>.from(json['days'] ?? []),
      sound: json['sound'] ?? 'sounds/radar.mp3', // NEW with default
    );
  }
}
