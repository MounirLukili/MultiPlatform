import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:ui';
import '../models/city_model.dart';

class WeatherCard extends StatelessWidget {
  final City city;

  const WeatherCard({super.key, required this.city});

  String _getWeatherAssetPath(String condition) {
    final lower = condition.toLowerCase();
    if (lower.contains('pluie') || lower.contains('averse')) return 'assets/rain.json';
    if (lower.contains('neige')) return 'assets/snow.json';
    if (lower.contains('soleil') || lower.contains('clair') || lower.contains('clear')) return 'assets/sun.json';
    if (lower.contains('nuage') || lower.contains('couvert')) return 'assets/wind.json';
    return 'assets/wind.json';
  }

  Widget _weatherMiniInfo(IconData icon, String val) {
    return Column(
      children: [
        Icon(icon, color: Colors.white54, size: 14),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double widgetWidth = screenWidth < 600 ? 280.0 : 320.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: widgetWidth,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.black.withOpacity(0.7), Colors.black.withOpacity(0.5)]
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(city.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(city.weatherCondition, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 5),
                    Text('${city.currentTemp.round()}°', style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w300)),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 50, width: 50,
                    child: Lottie.asset(_getWeatherAssetPath(city.weatherCondition), fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _weatherMiniInfo(Icons.water_drop, "${city.humidity}%"),
                      const SizedBox(width: 10),
                      _weatherMiniInfo(Icons.air, "${city.windSpeed.round()}"),
                      const SizedBox(width: 10),
                      _weatherMiniInfo(Icons.thermostat, "${city.maxTemp.round()}°"),
                    ],
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}