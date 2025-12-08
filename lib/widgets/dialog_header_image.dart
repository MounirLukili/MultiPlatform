import 'package:flutter/material.dart';

class DialogHeaderImage extends StatelessWidget {
  final String imageUrl;
  final String category;
  final double rating;
  final IconData categoryIcon;

  const DialogHeaderImage({
    super.key,
    required this.imageUrl,
    required this.category,
    required this.rating,
    required this.categoryIcon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl.isNotEmpty)
            Image.network(imageUrl, fit: BoxFit.cover)
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(categoryIcon, size: 50, color: Colors.white30),
              ),
            ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, const Color(0xFF1E1E1E).withOpacity(0.95)],
                ),
              ),
            ),
          ),
          if (rating > 0)
            Positioned(
              top: 15, right: 15,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                child: Row(
                  children: [
                    Text(rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(width: 4),
                    const Icon(Icons.star, size: 12, color: Colors.black),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}