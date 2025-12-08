import 'package:flutter/material.dart';

class FloatingMenu extends StatelessWidget {
  final VoidCallback onAiPressed;
  final VoidCallback onSettingsPressed;
  final VoidCallback onAddPressed;

  const FloatingMenu({
    super.key,
    required this.onAiPressed,
    required this.onSettingsPressed,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 250),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 1. IA
          FloatingActionButton(
            heroTag: "btn_ai",
            onPressed: onAiPressed,
            backgroundColor: Colors.black87,
            foregroundColor: Colors.amber,
            elevation: 4,
            child: const Icon(Icons.auto_awesome),
          ),
          const SizedBox(height: 16),

          // 2. SETTINGS
          FloatingActionButton(
            heroTag: "btn_settings",
            onPressed: onSettingsPressed,
            backgroundColor: Colors.black87,
            foregroundColor: Colors.amber,
            elevation: 4,
            child: const Icon(Icons.settings),
          ),
          const SizedBox(height: 16),

          // 3. AJOUT
          FloatingActionButton(
            heroTag: "btn_add",
            onPressed: onAddPressed,
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
            elevation: 6,
            child: const Icon(Icons.add_location_alt),
          ),
        ],
      ),
    );
  }
}