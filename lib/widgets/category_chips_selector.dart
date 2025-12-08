import 'package:flutter/material.dart';

class CategoryChipsSelector extends StatelessWidget {
  final Map<String, IconData> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const CategoryChipsSelector({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.entries.map((entry) {
        final isSelected = selectedCategory.toLowerCase() == entry.key.toLowerCase();
        return ChoiceChip(
          label: Text(entry.key),
          avatar: isSelected ? null : Icon(entry.value, size: 16, color: Colors.white70),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) onCategorySelected(entry.key);
          },
          backgroundColor: Colors.white.withOpacity(0.1),
          selectedColor: Colors.amber,
          labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
        );
      }).toList(),
    );
  }
}