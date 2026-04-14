class SensorData {
  final double temperature;
  final double humidity;
  final double heatIndex;

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.heatIndex,
  });

  factory SensorData.fromMap(Map<dynamic, dynamic> map) {
    return SensorData(
      temperature: (map['temperature'] ?? 0).toDouble(),
      humidity:    (map['humidity'] ?? 0).toDouble(),
      heatIndex:   (map['heatIndex'] ?? 0).toDouble(),
    );
  }
}