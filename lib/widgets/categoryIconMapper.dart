import 'package:flutter/material.dart';

class CategoryIconMapper {
  static final Map<String, IconData> _iconMapping = {
    'restaurant': Icons.restaurant,
    'hotel': Icons.hotel,
    'shopping': Icons.shopping_bag,
    'plage': Icons.beach_access,
    'médecine': Icons.local_hospital,
    'transport': Icons.directions_bus,
    'tourisme': Icons.landscape,
    'éducation': Icons.school,
    'sport': Icons.sports_soccer,
    'logement': Icons.house,
    'voyage': Icons.flight_takeoff,
    'voiture': Icons.car_repair_outlined,
    'papiers': Icons.newspaper_outlined,
    // Ajoutez d'autres mappings ici...
  };

  static IconData getIconForCategory(String categoryName) {
    final lowerCaseCategory = categoryName.toLowerCase();

    // Essaye de trouver une correspondance exacte
    if (_iconMapping.containsKey(lowerCaseCategory)) {
      return _iconMapping[lowerCaseCategory]!;
    }

    // Recherche partielle pour les catégories similaires
    for (final key in _iconMapping.keys) {
      if (lowerCaseCategory.contains(key)) {
        return _iconMapping[key]!;
      }
    }

    // Si aucun match, retourne une icône par défaut avec une couleur aléatoire
    return _getDefaultIcon(categoryName);
  }

  static IconData _getDefaultIcon(String categoryName) {
    // Utilise le hash du nom pour une icône cohérente
    final hash = categoryName.hashCode;
    final defaultIcons = [
      Icons.category,
      Icons.label,
      Icons.tag,
      Icons.star,
      Icons.favorite,
    ];
    return defaultIcons[hash % defaultIcons.length];
  }

  static Color getColorForCategory(String categoryName) {
    // Génère une couleur stable basée sur le nom
    final hash = categoryName.hashCode;
    return HSLColor.fromAHSL(
      1.0,
      hash % 360.0, // Teinte
      0.7, // Saturation
      0.6, // Luminosité
    ).toColor();
  }
}
