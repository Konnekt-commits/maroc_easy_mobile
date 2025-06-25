import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/comment_item.dart';
import 'package:carousel_slider/carousel_slider.dart';

class PropertyDetailPage extends StatefulWidget {
  final int id;
  final String title;
  final String location;
  final String phone;
  final String price;
  final double rating;
  final String description;
  final List<String> amenities;
  final List<String> services;
  final List<String> moyensDePaiement;
  final List<String> langues;
  final List<String> imageUrls;
  final Map<String, dynamic> horaires;
  final LatLng? coordinates;
  final String type;

  const PropertyDetailPage({
    Key? key,
    this.title = '',
    this.location = '',
    this.price = '',
    this.rating = 5.0,
    this.description = '',
    this.phone = '',
    this.type = '',
    this.amenities = const [],
    this.services = const [],
    this.moyensDePaiement = const [],
    this.langues = const [],
    this.imageUrls = const [],
    this.horaires = const {},
    this.coordinates,
    required this.id,
  }) : super(key: key);

  @override
  State<PropertyDetailPage> createState() => _PropertyDetailPageState();
}

class _PropertyDetailPageState extends State<PropertyDetailPage> {
  int _currentPage = 0;
  final PageController _pageController = PageController();
  bool _showComments = false;
  List<dynamic> _avis = [];
  double _userRating = 5.0;
  int user_id = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isFavorite = false;

  // Default amenities list when none are provided
  final List<String> _defaultAmenities = [
    'Wi-Fi',
    'Cuisine équipée',
    'Climatisation',
    'Parking gratuit',
    'Piscine',
    'Vue panoramique',
    'Télévision',
    'Machine à laver',
  ];

  // Helper method to get icon for each amenity
  IconData _getAmenityIcon(String amenity) {
    final String lowercaseAmenity = amenity.toLowerCase();

    // 🏠 Icônes pour les logements
    if (lowercaseAmenity.contains('wifi') ||
        lowercaseAmenity.contains('wi-fi')) {
      return Icons.wifi;
    } else if (lowercaseAmenity.contains('cuisine') ||
        lowercaseAmenity.contains('kitchen')) {
      return Icons.kitchen;
    } else if (lowercaseAmenity.contains('clim') ||
        lowercaseAmenity.contains('climatisation') ||
        lowercaseAmenity.contains('air conditionné')) {
      return Icons.ac_unit;
    } else if (lowercaseAmenity.contains('chauffage') ||
        lowercaseAmenity.contains('chauffe')) {
      return Icons.fireplace;
    } else if (lowercaseAmenity.contains('parking') ||
        lowercaseAmenity.contains('garage')) {
      return Icons.local_parking;
    } else if (lowercaseAmenity.contains('piscine') ||
        lowercaseAmenity.contains('pool')) {
      return Icons.pool;
    } else if (lowercaseAmenity.contains('vue') ||
        lowercaseAmenity.contains('panorama') ||
        lowercaseAmenity.contains('mer')) {
      return Icons.landscape;
    } else if (lowercaseAmenity.contains('tv') ||
        lowercaseAmenity.contains('télé')) {
      return Icons.tv;
    } else if (lowercaseAmenity.contains('machine') ||
        lowercaseAmenity.contains('lave')) {
      return Icons.local_laundry_service;
    } else if (lowercaseAmenity.contains('sèche')) {
      return Icons.dry;
    } else if (lowercaseAmenity.contains('fer') ||
        lowercaseAmenity.contains('repasser')) {
      return Icons.iron;
    } else if (lowercaseAmenity.contains('sécurité') ||
        lowercaseAmenity.contains('alarme') ||
        lowercaseAmenity.contains('surveillance')) {
      return Icons.security;
    } else if (lowercaseAmenity.contains('jardin') ||
        lowercaseAmenity.contains('espace vert')) {
      return Icons.yard;
    } else if (lowercaseAmenity.contains('terrasse') ||
        lowercaseAmenity.contains('balcon')) {
      return Icons.deck;
    } else if (lowercaseAmenity.contains('ascenseur')) {
      return Icons.elevator;
    } else if (lowercaseAmenity.contains('cheminée')) {
      return Icons.fireplace;
    } else if (lowercaseAmenity.contains('adapté') ||
        lowercaseAmenity.contains('pmr') ||
        lowercaseAmenity.contains('handicap')) {
      return Icons.accessible;
    } else if (lowercaseAmenity.contains('animaux') ||
        lowercaseAmenity.contains('chiens') ||
        lowercaseAmenity.contains('chat')) {
      return Icons.pets;
    } else if (lowercaseAmenity.contains('barbecue')) {
      return Icons.outdoor_grill;
    } else if (lowercaseAmenity.contains('bibliothèque')) {
      return Icons.menu_book;
    } else if (lowercaseAmenity.contains('nettoyage') ||
        lowercaseAmenity.contains('ménage')) {
      return Icons.cleaning_services;

      // 🚗 Icônes pour les voitures
    } else if (lowercaseAmenity.contains('gps')) {
      return Icons.gps_fixed;
    } else if (lowercaseAmenity.contains('bluetooth')) {
      return Icons.bluetooth;
    } else if (lowercaseAmenity.contains('siège') ||
        lowercaseAmenity.contains('cuir')) {
      return Icons.event_seat;
    } else if (lowercaseAmenity.contains('carburant') ||
        lowercaseAmenity.contains('essence')) {
      return Icons.local_gas_station;
    } else if (lowercaseAmenity.contains('boite') ||
        lowercaseAmenity.contains('transmission')) {
      return Icons.settings;
    } else if (lowercaseAmenity.contains('caméra') ||
        lowercaseAmenity.contains('recul')) {
      return Icons.videocam;
    } else if (lowercaseAmenity.contains('capteurs') ||
        lowercaseAmenity.contains('proximité')) {
      return Icons.sensors;
    } else if (lowercaseAmenity.contains('toit ouvrant') ||
        lowercaseAmenity.contains('sunroof')) {
      return Icons.wb_sunny;
    } else if (lowercaseAmenity.contains('usb') ||
        lowercaseAmenity.contains('chargeur')) {
      return Icons.usb;
    } else if (lowercaseAmenity.contains('marque') ||
        lowercaseAmenity.contains('brand')) {
      return Icons.directions_car;
    } else if (lowercaseAmenity.contains('modèle') ||
        lowercaseAmenity.contains('model')) {
      return Icons.directions_car_filled;
    } else if (lowercaseAmenity.contains('transmission') ||
        lowercaseAmenity.contains('boite') ||
        lowercaseAmenity.contains('boîte') ||
        lowercaseAmenity.contains('automatique') ||
        lowercaseAmenity.contains('manuelle')) {
      return Icons.settings;
    } else if (lowercaseAmenity.contains('kilométrage') ||
        lowercaseAmenity.contains('kilometrage') ||
        lowercaseAmenity.contains('km') ||
        lowercaseAmenity.contains('kilometres') ||
        lowercaseAmenity.contains('mileage')) {
      return Icons.speed;

      // 🧭 Icônes pour les excursions / activités
    } else if (lowercaseAmenity.contains('guide') ||
        lowercaseAmenity.contains('accompagnateur')) {
      return Icons.person;
    } else if (lowercaseAmenity.contains('transport') ||
        lowercaseAmenity.contains('bus')) {
      return Icons.directions_bus;
    } else if (lowercaseAmenity.contains('repas') ||
        lowercaseAmenity.contains('déjeuner') ||
        lowercaseAmenity.contains('dîner')) {
      return Icons.restaurant;
    } else if (lowercaseAmenity.contains('équipement') ||
        lowercaseAmenity.contains('matériel')) {
      return Icons.hiking;
    } else if (lowercaseAmenity.contains('photo')) {
      return Icons.photo_camera;
    } else if (lowercaseAmenity.contains('boissons')) {
      return Icons.local_drink;
    } else if (lowercaseAmenity.contains('billets') ||
        lowercaseAmenity.contains('entrées')) {
      return Icons.confirmation_num;

      // 📦 Services divers
    } else if (lowercaseAmenity.contains('réception') ||
        lowercaseAmenity.contains('accueil')) {
      return Icons.room_service;
    } else if (lowercaseAmenity.contains('bagages')) {
      return Icons.luggage;
    } else if (lowercaseAmenity.contains('coffre') ||
        lowercaseAmenity.contains('fort')) {
      return Icons.lock;
    } else if (lowercaseAmenity.contains('massage') ||
        lowercaseAmenity.contains('spa')) {
      return Icons.spa;
    } else if (lowercaseAmenity.contains('internet')) {
      return Icons.public;
    }
    // Paiement
    if (lowercaseAmenity.contains('espèces') ||
        lowercaseAmenity.contains('cash')) {
      return Icons.money;
    } else if (lowercaseAmenity.contains('carte bancaire') ||
        lowercaseAmenity.contains('cb') ||
        lowercaseAmenity.contains('carte de crédit')) {
      return Icons.credit_card;
    } else if (lowercaseAmenity.contains('chèque')) {
      return Icons.receipt;
    } else if (lowercaseAmenity.contains('virement')) {
      return Icons.account_balance;
    } else if (lowercaseAmenity.contains('mobile payment') ||
        lowercaseAmenity.contains('paiement mobile')) {
      return Icons.phone_iphone;

      // Santé
    } else if (lowercaseAmenity.contains('rendez-vous')) {
      return Icons.calendar_today;
    } else if (lowercaseAmenity.contains('téléconsultation')) {
      return Icons.video_call;
    } else if (lowercaseAmenity.contains('dossier médical')) {
      return Icons.folder_shared;
    } else if (lowercaseAmenity.contains('urgence')) {
      return Icons.emergency;
    } else if (lowercaseAmenity.contains('domicile')) {
      return Icons.home;

      // Langues
    } else if (lowercaseAmenity.contains('français')) {
      return Icons.language;
    } else if (lowercaseAmenity.contains('anglais')) {
      return Icons.translate;
    } else if (lowercaseAmenity.contains('arabe')) {
      return Icons.language;
    } else if (lowercaseAmenity.contains('espagnol')) {
      return Icons.language;
    } else if (lowercaseAmenity.contains('allemand')) {
      return Icons.language;

      // Types de voitures
    } else if (lowercaseAmenity.contains('berline')) {
      return Icons.directions_car;
    } else if (lowercaseAmenity.contains('suv')) {
      return Icons.directions_car_filled;
    } else if (lowercaseAmenity.contains('coupé')) {
      return Icons.time_to_leave;
    } else if (lowercaseAmenity.contains('cabriolet')) {
      return Icons.wb_sunny;
    } else if (lowercaseAmenity.contains('break')) {
      return Icons.airline_seat_recline_normal;
    } else if (lowercaseAmenity.contains('monospace')) {
      return Icons.airport_shuttle;
    } else if (lowercaseAmenity.contains('4x4')) {
      return Icons.offline_pin;
    } else if (lowercaseAmenity.contains('utilitaire')) {
      return Icons.business;
    } else if (lowercaseAmenity.contains('citadine')) {
      return Icons.directions_car;
    } else if (lowercaseAmenity.contains('sportive')) {
      return Icons.sports_motorsports;
    } else if (lowercaseAmenity.contains('luxe')) {
      return Icons.stars;

      // Marques de voitures
    } else if ([
      'audi',
      'bmw',
      'citroën',
      'dacia',
      'fiat',
      'ford',
      'honda',
      'hyundai',
      'kia',
      'mercedes',
      'nissan',
      'opel',
      'peugeot',
      'renault',
      'seat',
      'skoda',
      'toyota',
      'volkswagen',
      'volvo',
    ].any(lowercaseAmenity.contains)) {
      return Icons.directions_car;

      // Services autos
    } else if (lowercaseAmenity.contains('financement')) {
      return Icons.account_balance_wallet;
    } else if (lowercaseAmenity.contains('garantie')) {
      return Icons.verified;
    } else if (lowercaseAmenity.contains('entretien') ||
        lowercaseAmenity.contains('réparation')) {
      return Icons.build;
    } else if (lowercaseAmenity.contains('reprise')) {
      return Icons.autorenew;
    } else if (lowercaseAmenity.contains('location')) {
      return Icons.car_rental;
    } else if (lowercaseAmenity.contains('essai')) {
      return Icons.speed;
    } else if (lowercaseAmenity.contains('livraison')) {
      return Icons.local_shipping;
    } else if (lowercaseAmenity.contains('service après-vente')) {
      return Icons.support_agent;
    } else if (lowercaseAmenity.contains('personnalisation')) {
      return Icons.design_services;
    } else if (lowercaseAmenity.contains('assurance')) {
      return Icons.assignment;

      // Voyages et excursions
    } else if (lowercaseAmenity.contains('guide touristique')) {
      return Icons.person;
    } else if (lowercaseAmenity.contains('transport inclus')) {
      return Icons.directions_bus;
    } else if (lowercaseAmenity.contains('hébergement inclus')) {
      return Icons.hotel;
    } else if (lowercaseAmenity.contains('activités organisées')) {
      return Icons.event;
    } else if (lowercaseAmenity.contains('assurance voyage')) {
      return Icons.card_travel;
    } else if (lowercaseAmenity.contains('repas inclus')) {
      return Icons.restaurant;
    } else if (lowercaseAmenity.contains('excursions')) {
      return Icons.terrain;
    } else if (lowercaseAmenity.contains('billets d\'avion inclus')) {
      return Icons.flight;
    } else if (lowercaseAmenity.contains('service de réservation')) {
      return Icons.book_online;
    } else if (lowercaseAmenity.contains('wi-fi gratuit')) {
      return Icons.wifi;
    } else if (lowercaseAmenity.contains('service de traduction')) {
      return Icons.translate;
    } else if (lowercaseAmenity.contains('support 24/7')) {
      return Icons.support_agent;

      // Commerces et services
    } else if (lowercaseAmenity.contains('supermarché')) {
      return Icons.store;
    } else if (lowercaseAmenity.contains('vêtements')) {
      return Icons.checkroom;
    } else if (lowercaseAmenity.contains('magasin d\'\u00e9lectronique')) {
      return Icons.electrical_services;
    } else if (lowercaseAmenity.contains('librairie')) {
      return Icons.menu_book;
    } else if (lowercaseAmenity.contains('centre commercial')) {
      return Icons.shopping_bag;
    } else if (lowercaseAmenity.contains('magasin de sport')) {
      return Icons.sports;
    } else if (lowercaseAmenity.contains('bijouterie')) {
      return Icons.watch;
    } else if (lowercaseAmenity.contains('magasin de meubles')) {
      return Icons.weekend;
    } else if (lowercaseAmenity.contains('pharmacie')) {
      return Icons.local_pharmacy;
    } else if (lowercaseAmenity.contains('magasin de jouets')) {
      return Icons.toys;
    } else if (lowercaseAmenity.contains('parking gratuit')) {
      return Icons.local_parking;
    } else if (lowercaseAmenity.contains('accessibilité')) {
      return Icons.accessible;
    } else if (lowercaseAmenity.contains('service de livraison')) {
      return Icons.delivery_dining;
    } else if (lowercaseAmenity.contains('réservation en ligne')) {
      return Icons.book_online;
    } else if (lowercaseAmenity.contains('promotions')) {
      return Icons.discount;
    } else if (lowercaseAmenity.contains('paiement sans contact')) {
      return Icons.nfc;
    } else if (lowercaseAmenity.contains('espace enfants')) {
      return Icons.child_friendly;
    } else if (lowercaseAmenity.contains('retours et échanges')) {
      return Icons.swap_horiz;
    } else if (lowercaseAmenity.contains('assistance client')) {
      return Icons.support_agent;
    }
    // Nouveaux éléments
    else if (lowercaseAmenity.contains('marocaine') ||
        lowercaseAmenity.contains('italienne') ||
        lowercaseAmenity.contains('française') ||
        lowercaseAmenity.contains('asiatique') ||
        lowercaseAmenity.contains('végétarienne') ||
        lowercaseAmenity.contains('sans gluten')) {
      return Icons.dining;
    } else if (lowercaseAmenity.contains('menu enfant')) {
      return Icons.child_friendly;
    } else if (lowercaseAmenity.contains('emporter')) {
      return Icons.shopping_bag;
    } else if (lowercaseAmenity.contains('livraison')) {
      return Icons.delivery_dining;
    } else if (lowercaseAmenity.contains('réservation')) {
      return Icons.calendar_today;
    } else if (lowercaseAmenity.contains('buffet')) {
      return Icons.local_dining;
    } else if (lowercaseAmenity.contains('service à table')) {
      return Icons.room_service;
    } else if (lowercaseAmenity.contains('parking')) {
      return Icons.local_parking;
    } else if (lowercaseAmenity.contains('accessibilité')) {
      return Icons.accessible;
    } else if (lowercaseAmenity.contains('espace enfants')) {
      return Icons.toys;
    } else if (lowercaseAmenity.contains('terrasse')) {
      return Icons.deck;
    } else if (lowercaseAmenity.contains('salle privée')) {
      return Icons.meeting_room;
    } else if (lowercaseAmenity.contains('musique live')) {
      return Icons.music_note;
    } else if (lowercaseAmenity.contains('paiement sans contact')) {
      return Icons.contactless;
    } else if (lowercaseAmenity.contains('service après-vente')) {
      return Icons.support_agent;
    }

    // ❓ Icône par défaut
    return Icons.check_circle_outline;
  }

  @override
  // Add a review for a annonces
  addReview(double rating, String comment) async {
    try {
      // Get token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userDataString = prefs.getString('userData');
      final userData = jsonDecode(userDataString!);

      if (token == null || token.isEmpty) {
        throw Exception('User not authenticated');
      }

      final response = await http.post(
        Uri.parse('https://maroceasy.konnekt.fr/api/avis'),
        headers: {
          'accept': 'application/ld+json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/ld+json',
        },
        body: jsonEncode({
          'annonce': '/api/annonces/${widget.id}',
          'user': "/api/users/" + userData['id'].toString(),
          'note': rating.toString(),
          'commentaire': comment,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        print('Failed to add review: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error adding review: $e');
      return false;
    }
  }

  double calculateAverageRating(List<dynamic> avisList) {
    try {
      final validNotes =
          avisList
              .where((avis) => avis is Map && avis['note'] != null)
              .map((avis) => double.parse(avis['note']))
              .where(
                (note) => note >= 0 && note <= 5,
              ) // Validation des notes entre 0 et 5
              .toList();

      if (validNotes.isEmpty) return 0.0;

      return validNotes.reduce((a, b) => a + b) / validNotes.length;
    } catch (e) {
      print('Erreur de calcul: $e');
      return 0.0;
    }
  }

  fetchAvis() async {
    // Get token from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userDataString = prefs.getString('userData');
    final userData = jsonDecode(userDataString!);
    print(userData);
    final response = await http.get(
      Uri.parse(
        "https://maroceasy.konnekt.fr/api/avis?page=1&annonce.id=${widget.id}",
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      var jsonData = json.decode(response.body);
      print(jsonData["hydra:member"]);
      setState(() {
        _avis = jsonData["hydra:member"];

        user_id = userData['id'];
      });
      return jsonData["hydra:member"];
    } else if (response.statusCode == 426) {
      // Gestion de l'erreur 426 : Mise à jour requise
      var errorData = jsonDecode(response.body);
      String updateUrl = errorData['update_url'];

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Mise à jour requise'),
              content: const Text(
                'Veuillez télécharger la dernière version de l\'application.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Ouvrir le lien de mise à jour
                    launch(updateUrl);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Mettre à jour'),
                ),
              ],
            ),
      );
    } else {
      // Gestion des autres erreurs
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Erreur'),
              content: Text(
                'Status Code: ${response.statusCode} \nResponse Body: ${response.body}',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Ok"),
                ),
              ],
            ),
      );
      throw Exception('Échec de la récupération de données');
    }
  }

  String _capitalize(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchAvis();
    _pageController.addListener(() {
      int next = _pageController.page!.round();
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use the provided imageUrls or fallback to assets
    final List<String> images =
        widget.imageUrls.isEmpty
            ? [
              'assets/images/maison1.jpg',
              'assets/images/maison2.jpg',
              'assets/images/maison3.jpg',
              'assets/images/maison4.jpg',
            ]
            : widget.imageUrls;

    // Use the provided coordinates or default to Estaimpuis
    final LatLng mapCoordinates = widget.coordinates ?? LatLng(50.7304, 3.2583);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // AppBar avec carrousel d'images
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                leading: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                actions: [
                  // CircleAvatar(
                  //   backgroundColor: Colors.white,
                  //   child: IconButton(
                  //     icon: const Icon(Icons.share, color: Colors.black),
                  //     onPressed: () {},
                  //   ),
                  // ),
                  // const SizedBox(width: 10),
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.red : Colors.black,
                      ),
                      onPressed: _toggleFavorite,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                flexibleSpace: Stack(
                  children: [
                    Positioned.fill(
                      child: FlexibleSpaceBar(
                        background: PageView.builder(
                          controller: _pageController,
                          itemCount: images.length,
                          itemBuilder: (context, index) {
                            return Image.network(
                              images[index],
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      ),
                    ),
                    // Indicateurs de page
                    Positioned(
                      bottom: 50,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          images.length,
                          (index) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  _currentPage == index
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Contenu blanc qui remonte sur le carrousel
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 30,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Contenu
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 16.0,
                    bottom: 100.0,
                  ),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre et informations principales
                      Center(
                        child: Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Localisation avec icône
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.location,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Équipements en grille
                      if (widget.amenities.isNotEmpty)
                        Column(
                          children: [
                            const SizedBox(height: 24),
                            const Text(
                              'Informations principales',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 4.5,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                              itemCount: widget.amenities.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getAmenityIcon(
                                          widget.amenities[index],
                                        ),
                                        size: 20,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          widget.amenities[index].contains(':')
                                              ? widget.amenities[index]
                                                  .split(':')
                                                  .skip(1)
                                                  .join(':')
                                                  .trim()
                                              : widget.amenities[index],
                                          style: const TextStyle(fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      if (widget.services.isNotEmpty)
                        Column(
                          children: [
                            const SizedBox(height: 24),
                            // Équipements en grille
                            const Text(
                              'Principaux services',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 4.5,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                              itemCount: widget.services.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getAmenityIcon(widget.services[index]),
                                        size: 20,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          widget.services[index],
                                          style: const TextStyle(fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                      if (widget.langues.isNotEmpty)
                        Column(
                          children: [
                            const SizedBox(height: 24),
                            // Équipements en grille
                            const Text(
                              'Langues parlées',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 4.5,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                              itemCount: widget.langues.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getAmenityIcon(widget.langues[index]),
                                        size: 20,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          widget.langues[index],
                                          style: const TextStyle(fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      if (widget.moyensDePaiement.isNotEmpty)
                        Column(
                          children: [
                            const SizedBox(height: 24),
                            // Équipements en grille
                            const Text(
                              'Moyens de paiement',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 4.5,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                              itemCount: widget.moyensDePaiement.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getAmenityIcon(
                                          widget.moyensDePaiement[index],
                                        ),
                                        size: 20,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          widget.moyensDePaiement[index],
                                          style: const TextStyle(fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      if (widget.horaires.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(
                                        Icons.access_time,
                                        color: Colors.teal,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Horaires d'ouverture",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.teal,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ...widget.horaires.entries.map((entry) {
                                    final isClosed = entry.value
                                        .toLowerCase()
                                        .contains("fermé");

                                    return Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _capitalize(entry.key),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                            Text(
                                              entry.value,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w400,
                                                color:
                                                    isClosed
                                                        ? Colors.redAccent
                                                        : Colors.black87,
                                                fontStyle:
                                                    isClosed
                                                        ? FontStyle.italic
                                                        : FontStyle.normal,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Divider(
                                          height: 16,
                                          thickness: 0.8,
                                          color: Colors.grey,
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ],
                        ),

                      // Note et commentaires - Rendu cliquable
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showComments = true;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.star),
                              SizedBox(width: 5),
                              Text(
                                calculateAverageRating(
                                  _avis,
                                ).toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 5),
                              Text(
                                '· ${_avis.length.toString()} commentaires',
                                style: TextStyle(
                                  fontSize: 16,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Services
                      const SizedBox(height: 30),

                      // Localisation
                      const Text(
                        'Localisation',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(widget.location, style: TextStyle(fontSize: 16)),

                      const SizedBox(height: 15),

                      // Carte
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          height: 300,
                          child: Stack(
                            children: [
                              FlutterMap(
                                options: MapOptions(
                                  center:
                                      widget
                                          .coordinates!, // Coordonnées d'Estaimpuis
                                  zoom: 13,
                                  interactiveFlags: InteractiveFlag.all,
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName:
                                        'com.konnekt.maroceasy',
                                  ),
                                  CircleLayer(
                                    circles: [
                                      CircleMarker(
                                        point: widget.coordinates!,
                                        radius: 1000, // 1km de rayon
                                        color: Colors.red.withOpacity(0.2),
                                        borderColor: Colors.red.withOpacity(
                                          0.5,
                                        ),
                                        borderStrokeWidth: 1,
                                      ),
                                    ],
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: LatLng(
                                          widget.coordinates!.latitude,
                                          widget.coordinates!.longitude,
                                        ),
                                        width: 80,
                                        height: 80,
                                        child: Icon(
                                          Icons.location_pin,
                                          color: Colors.red,
                                          size: 30,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Positioned(
                                right: 10,
                                top: 10,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.fullscreen),
                                    onPressed: () {
                                      // Action pour agrandir la carte
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'Adresse exacte communiquée après la réservation.',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),

                      const SizedBox(height: 10),

                      // Description section
                      const Text(
                        'À propos',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        widget.description.isNotEmpty
                            ? widget.description
                            : 'Ce logement confortable vous offre une expérience unique avec une vue imprenable sur les environs. Parfait pour se détendre et profiter de la nature environnante.',
                        style: TextStyle(fontSize: 16, height: 1.5),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 1,
                      child: RichText(
                        text: TextSpan(
                          children: [
                            if (widget.type == 'Shopping' ||
                                widget.type == 'Restaurant')
                              TextSpan(
                                text: 'À partir de ',
                                style: TextStyle(
                                  fontSize: 18,
                                  decoration: TextDecoration.underline,
                                  color:
                                      Colors.black, // Important pour RichText
                                ),
                              ),
                            TextSpan(
                              text:
                                  widget.type == 'Santé'
                                      ? "Contactez-nous"
                                      : widget.price,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                                color: Colors.black, // Important pour RichText
                              ),
                            ),
                            if (widget.type == 'logement')
                              TextSpan(
                                text: ' par nuit',
                                style: TextStyle(
                                  fontSize: 18,
                                  decoration: TextDecoration.underline,
                                  color:
                                      Colors.black, // Important pour RichText
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Bouton Réserver
                    Expanded(
                      flex: 1,
                      child: ElevatedButton(
                        onPressed: () {
                          launchUrl(Uri.parse('tel://' + widget.phone));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: const Text(
                            'Réserver',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Ajout du conteneur animé pour les commentaires
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: _showComments ? 0 : -MediaQuery.of(context).size.height,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Scaffold(
                backgroundColor: Colors.transparent,
                resizeToAvoidBottomInset: true,
                body: SafeArea(
                  // Ajout de SafeArea pour éviter la barre d'état
                  child: Column(
                    children: [
                      // En-tête des commentaires
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () {
                                setState(() {
                                  _showComments = false;
                                });
                              },
                            ),
                            Text(
                              '${_avis.length} commentaire(s)',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Liste des commentaires
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          children: List.generate(_avis.length, (index) {
                            return CommentItem(
                              onDelete:
                                  () => _showDeleteConfirmation(_avis[index]),
                              onEdit:
                                  () => _showEditCommentDialog(_avis[index]),
                              canModify: _avis[index]["user"]['id'] == user_id,
                              isImage: true,
                              rate: double.parse(_avis[index]["note"]),
                              name: _avis[index]["user"]['pseudoName'],
                              date: getRelativeTime(
                                DateTime.parse(_avis[index]["dateAvis"]),
                              ),
                              duration: 'Séjour de quelques nuits',
                              comment: _avis[index]['commentaire'],
                              language: 'français',
                              years: 'Client MarocEasy',
                              avatar: _avis[index]["user"]['picto'],
                            );
                          }),
                        ),
                      ),

                      // Barre de commentaire
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // Rating bar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Votre note: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                RatingBar.builder(
                                  initialRating: 5,
                                  minRating: 1,
                                  direction: Axis.horizontal,
                                  allowHalfRating: true,
                                  itemCount: 5,
                                  itemSize: 30,
                                  itemPadding: const EdgeInsets.symmetric(
                                    horizontal: 2.0,
                                  ),
                                  itemBuilder:
                                      (context, _) => const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                      ),
                                  onRatingUpdate: (rating) {
                                    setState(() {
                                      _userRating = rating;
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Comment input field and send button
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _commentController,
                                    decoration: InputDecoration(
                                      hintText: 'Votre commentaire',
                                      prefixIcon: const Icon(Icons.comment),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(30),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[200],
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 50,
                                  child: IconButton(
                                    color: Colors.pink,
                                    onPressed: () {
                                      // Fermer le clavier
                                      FocusScope.of(context).unfocus();

                                      // Envoyer le commentaire avec la note
                                      if (_commentController.text.isNotEmpty) {
                                        addReview(
                                          _userRating,
                                          _commentController.text,
                                        ).then((success) {
                                          if (success) {
                                            // Effacer le champ de texte
                                            _commentController.clear();
                                            // Rafraîchir les commentaires
                                            fetchAvis();
                                            // Afficher un message de succès
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Commentaire ajouté avec succès',
                                                ),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Erreur lors de l\'ajout du commentaire',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        });
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Veuillez ajouter un commentaire',
                                            ),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.send),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditCommentDialog(Map<String, dynamic> avis) {
    final TextEditingController editController = TextEditingController(
      text: avis['commentaire'],
    );
    double editRating = double.parse(avis['note']);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Modifier votre commentaire'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Rating bar
                RatingBar.builder(
                  initialRating: editRating,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemSize: 30,
                  itemPadding: EdgeInsets.symmetric(horizontal: 2.0),
                  itemBuilder:
                      (context, _) => Icon(Icons.star, color: Colors.amber),
                  onRatingUpdate: (rating) {
                    editRating = rating;
                  },
                ),
                SizedBox(height: 16),
                // Comment text field
                TextField(
                  controller: editController,
                  decoration: InputDecoration(
                    hintText: 'Votre commentaire',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler'),
              ),
              TextButton(
                onPressed: () {
                  // Update the comment
                  updateReview(
                    avis['id'],
                    editRating,
                    editController.text,
                  ).then((success) {
                    Navigator.pop(context);
                    if (success) {
                      fetchAvis();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Commentaire modifié avec succès'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur lors de la modification'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  });
                },
                child: Text('Enregistrer'),
              ),
            ],
          ),
    );
  }

  // Show confirmation dialog before deleting a comment
  void _showDeleteConfirmation(Map<String, dynamic> avis) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            title: Text('Supprimer le commentaire'),
            content: Text(
              'Êtes-vous sûr de vouloir supprimer ce commentaire ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () {
                  // Delete the comment
                  deleteReview(avis['id']).then((success) {
                    Navigator.pop(context);
                    if (success) {
                      fetchAvis();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Commentaire supprimé avec succès'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur lors de la suppression'),
                          backgroundColor: Colors.pink,
                        ),
                      );
                    }
                  });
                },
                child: Text('Supprimer', style: TextStyle(color: Colors.pink)),
              ),
            ],
          ),
    );
  }

  // Update a review
  Future<bool> updateReview(int reviewId, double rating, String comment) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception('User not authenticated');
      }

      final response = await http.put(
        Uri.parse('https://maroceasy.konnekt.fr/api/avis/$reviewId'),
        headers: {
          'accept': 'application/ld+json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/ld+json',
        },
        body: jsonEncode({
          'note': rating.toString(),
          'commentaire': comment,
          'user': '/api/users/' + user_id.toString(),
          'annonces': '/api//annonces/' + widget.id.toString(),
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to update review: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error updating review: $e');
      return false;
    }
  }

  // Delete a review
  Future<bool> deleteReview(int reviewId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception('User not authenticated');
      }

      final response = await http.delete(
        Uri.parse('https://maroceasy.konnekt.fr/api/avis/$reviewId'),
        headers: {
          'accept': 'application/ld+json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204) {
        return true;
      } else {
        print('Failed to delete review: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error deleting review: $e');
      return false;
    }
  }
}

String getRelativeTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inDays > 365) {
    final years = (difference.inDays / 365).floor();
    return 'il y a $years ${years == 1 ? 'an' : 'ans'}';
  } else if (difference.inDays > 30) {
    final months = (difference.inDays / 30).floor();
    return 'il y a $months ${months == 1 ? 'mois' : 'mois'}';
  } else if (difference.inDays > 0) {
    return 'il y a ${difference.inDays} ${difference.inDays == 1 ? 'jour' : 'jours'}';
  } else if (difference.inHours > 0) {
    return 'il y a ${difference.inHours} ${difference.inHours == 1 ? 'heure' : 'heures'}';
  } else if (difference.inMinutes > 0) {
    return 'il y a ${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'}';
  } else {
    return 'à l\'instant';
  }
}

// Show dialog to edit a comment
