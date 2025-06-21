import 'package:flutter/material.dart';

class CategoryFormType {
  static const String LOGEMENT = 'logement';
  static const String SANTE = 'sante';
  static const String RESTAURANT = 'restaurant';
  static const String VOITURE = 'voiture';
  static const String SHOPPING = 'shopping';
  static const String DEFAULT = 'logement';

  static String getFormTypeForCategory(
    int categoryId,
    List<dynamic> categories,
  ) {
    if (categories.isEmpty) return DEFAULT;

    // Find the category by ID
    final category = categories.firstWhere(
      (cat) => cat['id'] == categoryId,
      orElse: () => null,
    );

    if (category == null) return DEFAULT;

    // Determine form type based on category name
    final categoryName = category['nom'].toString().toLowerCase();

    if (categoryName.contains('logement') ||
        categoryName.contains('appartement') ||
        categoryName.contains('maison')) {
      return LOGEMENT;
    } else if (categoryName.contains('médecin') ||
        categoryName.contains('santé') ||
        categoryName.contains('clinique') ||
        categoryName.contains('hopital')) {
      return SANTE;
    } else if (categoryName.contains('restaurant') ||
        categoryName.contains('café')) {
      return RESTAURANT;
    } else if (categoryName.contains('voiture') ||
        categoryName.contains('auto') ||
        categoryName.contains('véhicule') ||
        categoryName.contains('location auto')) {
      return VOITURE;
    }

    return DEFAULT;
  }
}

// In your _ManagePropertiesState class, add:
