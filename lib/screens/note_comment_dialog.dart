// lib/screens/note_comment_dialog.dart

import 'package:flutter/material.dart';
import '../models/place_model.dart';
import '../services/database_service.dart';

class NoteCommentDialog extends StatefulWidget {
  final Place place;

  const NoteCommentDialog({super.key, required this.place});

  @override
  State<NoteCommentDialog> createState() => _NoteCommentDialogState();
}

class _NoteCommentDialogState extends State<NoteCommentDialog> {
  final _commentController = TextEditingController();
  double _rating = 3.0; // Valeur par défaut

  @override
  void initState() {
    super.initState();
    // Pré-remplir si des données existent déjà
    if (widget.place.userRating != null && widget.place.userRating! > 0) {
      _rating = widget.place.userRating!;
    }
    if (widget.place.userComment != null) {
      _commentController.text = widget.place.userComment!;
    }
  }

  Future<void> _saveNote() async {
    // 1. Créer une copie du lieu avec les nouvelles infos utilisateur
    final updatedPlace = widget.place.copyWith(
      userRating: _rating,
      userComment: _commentController.text,
    );

    // 2. Sauvegarder dans SQLite (insertPlace gère le remplacement grâce à ConflictAlgorithm.replace)
    await DatabaseService.instance.insertPlace(updatedPlace);

    if (mounted) {
      // 3. Fermer le dialogue et renvoyer le lieu mis à jour à la page précédente
      Navigator.of(context).pop(updatedPlace);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Note et commentaire enregistrés !")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Votre avis personnel"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Note :", style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _rating,
                    min: 0,
                    max: 5,
                    divisions: 10, // Permet des demi-étoiles (0.5)
                    label: _rating.toString(),
                    onChanged: (val) => setState(() => _rating = val),
                  ),
                ),
                Text(
                  _rating.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Icon(Icons.star, color: Colors.amber, size: 20),
              ],
            ),
            const SizedBox(height: 15),
            const Text("Commentaire :", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Qu'avez-vous pensé de ce lieu ? (ex: Super ambiance, mais un peu cher...)",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null), // Annuler
          child: const Text("Annuler"),
        ),
        ElevatedButton(
          onPressed: _saveNote,
          child: const Text("Enregistrer"),
        ),
      ],
    );
  }
}