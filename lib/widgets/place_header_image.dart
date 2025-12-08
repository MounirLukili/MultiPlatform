import 'package:flutter/material.dart';
import '../models/place_model.dart';

class PlaceHeaderImage extends StatelessWidget {
  final Place place;

  const PlaceHeaderImage({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Hero(
          tag: 'place-img-${place.title}',
          child: Container(
            height: 300,
            width: double.infinity,
            color: Colors.grey.shade300,
            child: place.imageUrl.isNotEmpty
                ? Image.network(place.imageUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)))
                : const Icon(Icons.image, size: 100, color: Colors.grey),
          ),
        ),
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            height: 100,
            decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.8)])),
          ),
        ),
      ],
    );
  }
}