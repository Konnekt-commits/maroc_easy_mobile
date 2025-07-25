import 'package:flutter/material.dart';

class CategoryIconMapper {
  static final Map<String, IconData> _iconMapping = {
    // 🍽️ Alimentation / Restauration
    'restaurant': Icons.restaurant,
    'food': Icons.fastfood,
    'repas': Icons.dining,
    'café': Icons.local_cafe,
    'bar': Icons.local_bar,

    // 🛏️ Hébergement
    'hotel': Icons.hotel,
    'logement': Icons.house,
    'appartement': Icons.apartment,
    'chambre': Icons.bed,

    // 🛍️ Shopping / Commerce
    'shopping': Icons.shopping_bag,
    'boutique': Icons.storefront,
    'magasin': Icons.store,
    'mode': Icons.checkroom,
    'cosmétique': Icons.brush,
    'chaussure': Icons.hiking,

    // 🏖️ Tourisme / Loisir
    'plage': Icons.beach_access,
    'tourisme': Icons.landscape,
    'voyage': Icons.flight_takeoff,
    'vacances': Icons.card_travel,

    // 🚗 Transport / Voiture
    'voiture': Icons.directions_car,
    'transport': Icons.directions_bus,
    'bus': Icons.directions_bus,
    'train': Icons.train,
    'moto': Icons.two_wheeler,
    'avion': Icons.flight,
    'taxi': Icons.local_taxi,
    'parking': Icons.local_parking,

    // 🧾 Administratif / Paperasse
    'papiers': Icons.description,
    'administratif': Icons.account_balance,
    'document': Icons.article,
    'permis': Icons.assignment_ind,
    'assurance': Icons.assignment_turned_in,

    // 🩺 Santé
    'médecine': Icons.local_hospital,
    'hopital': Icons.local_hospital,
    'pharmacie': Icons.local_pharmacy,
    'santé': Icons.health_and_safety,
    'dentiste': Icons.medical_services,

    // 🧑‍🏫 Éducation
    'éducation': Icons.school,
    'université': Icons.cast_for_education,
    'cours': Icons.menu_book,
    'livres': Icons.book,

    // 🏋️‍♂️ Sport
    'sport': Icons.sports_soccer,
    'gym': Icons.fitness_center,
    'yoga': Icons.self_improvement,
    'natation': Icons.pool,

    // 🏢 Entreprise / Business
    'entreprise': Icons.business,
    'création de business': Icons.rocket_launch,
    'startup': Icons.lightbulb_outline,
    'bureau': Icons.apartment,
    'administration': Icons.admin_panel_settings,

    // 🏘️ Immobilier
    'immobilier': Icons.house,
    'vente immobilière': Icons.real_estate_agent,
    'terrain': Icons.terrain,
    'location': Icons.location_city,

    // 🎭 Culture / Événement
    'cinéma': Icons.movie,
    'musique': Icons.music_note,
    'théâtre': Icons.theaters,
    'événement': Icons.event,

    // 📱 Technologie / Numérique
    'informatique': Icons.computer,
    'technologie': Icons.devices,
    'internet': Icons.wifi,
    'mobile': Icons.smartphone,
    'app': Icons.apps,

    // 👶 Famille / Enfants
    'famille': Icons.family_restroom,
    'bébé': Icons.child_friendly,
    'mariage': Icons.volunteer_activism,

    // 💼 Emploi / Travail
    'emploi': Icons.work,
    'job': Icons.engineering,
    'freelance': Icons.laptop_mac,
    'stage': Icons.school,

    // 💬 Services
    'services': Icons.handshake,
    'nettoyage': Icons.cleaning_services,
    'déménagement': Icons.local_shipping,
    'réparation': Icons.build,
    'jardinage': Icons.grass,

    // 💰 Finances
    'banque': Icons.account_balance_wallet,
    'finance': Icons.attach_money,
    'prêt': Icons.request_page,
    'impôts': Icons.receipt_long,

    // 💖 Autres
    'association': Icons.groups,
    'religion': Icons.church,
    'animaux': Icons.pets,
    'sécurité': Icons.shield,
    'climat': Icons.eco,
  };

  static List<String> get availableCategories => _iconMapping.keys.toList();

  static IconData getIconForCategory(String categoryName) {
    final lowerCaseCategory = categoryName.toLowerCase();

    // Match exact
    if (_iconMapping.containsKey(lowerCaseCategory)) {
      return _iconMapping[lowerCaseCategory]!;
    }

    // Match partiel
    for (final key in _iconMapping.keys) {
      if (lowerCaseCategory.contains(key)) {
        return _iconMapping[key]!;
      }
    }

    // Icône par défaut
    return _getDefaultIcon(categoryName);
  }

  static IconData _getDefaultIcon(String categoryName) {
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
    final hash = categoryName.hashCode;
    return HSLColor.fromAHSL(1.0, hash % 360.0, 0.7, 0.6).toColor();
  }
}
