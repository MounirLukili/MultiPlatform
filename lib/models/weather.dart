class Weather {
  final String city;       
  final double temp;
  final String description;
  final double tempMin;
  final double tempMax;
  final int humidity;
  final double windSpeed;

  Weather({
    required this.city,     
    required this.temp,
    required this.description,
    required this.tempMin,
    required this.tempMax,
    required this.humidity,
    required this.windSpeed,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      city: json['name'],   
      temp: json['main']['temp'].toDouble(),
      description: json['weather'][0]['description'],
      tempMin: json['main']['temp_min'].toDouble(),
      tempMax: json['main']['temp_max'].toDouble(),
      humidity: json['main']['humidity'].toInt(),
      windSpeed: json['wind']['speed'].toDouble(),
    );
  }
}
