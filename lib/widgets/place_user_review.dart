import 'package:flutter/material.dart';
import '../models/place_model.dart';

class PlaceUserReview extends StatelessWidget {
  final Place place;
  final VoidCallback onEditPressed;

  const PlaceUserReview({super.key, required this.place, required this.onEditPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(thickness: 1.5),
        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Votre avis", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (place.userRating != null && place.userRating! > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    Text(place.userRating.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                    const SizedBox(width: 4),
                    Icon(Icons.star, size: 16, color: Colors.blue.shade900),
                  ],
                ),
              )
          ],
        ),
        const SizedBox(height: 10),

        if (place.userComment != null && place.userComment!.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              place.userComment!,
              style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black87),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.only(bottom: 15),
            child: Text("Vous n'avez pas encore commenté ce lieu.", style: TextStyle(color: Colors.grey)),
          ),

        Center(
          child: ElevatedButton.icon(
            onPressed: onEditPressed,
            icon: const Icon(Icons.edit),
            label: Text(place.userComment != null ? "Modifier ma note" : "Ajouter une note personnelle"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}