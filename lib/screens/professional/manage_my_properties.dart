import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:maroceasy/widgets/adressField.dart';
import 'package:maroceasy/widgets/category_form_type.dart';
import 'package:maroceasy/widgets/loader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:location/location.dart' as loc;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

// Add this class
class CustomMarker {
  final latlong.LatLng position;
  final bool draggable;

  CustomMarker({required this.position, this.draggable = false});
}

class CategoryFormType {
  static const String LOGEMENT = 'LOGEMENT';
  static const String SANTE = 'SANTE';
  static const String RESTAURANT = 'RESTAURANT';
  static const String VOITURE = 'VOITURE';
  static const String VOYAGE = 'VOYAGE';
  static const String SHOPPING = 'SHOPPING';
  static const String DEFAULT = 'DEFAULT';

  static String getFormTypeForCategory(
    int categoryId,
    List<dynamic> categories,
  ) {
    final category = categories.firstWhere(
      (cat) => cat['id'] == categoryId,
      orElse: () => null,
    );

    if (category != null) {
      switch (category['nom']) {
        case 'Logement':
          return LOGEMENT;
        case 'Santé':
          return SANTE;
        case 'Restaurant':
          return RESTAURANT;
        case 'Voiture':
          return VOITURE;
        case 'Voyage':
          return VOYAGE;
        case 'Shopping':
          return SHOPPING;
        default:
          return DEFAULT;
      }
    }
    return DEFAULT;
  }
}

class ManageMyProperties extends StatefulWidget {
  const ManageMyProperties({Key? key}) : super(key: key);

  @override
  State<ManageMyProperties> createState() => _ManageMyPropertiesState();
}

class _ManageMyPropertiesState extends State<ManageMyProperties> {
  List<dynamic> _properties = [];
  List<dynamic> _cities = [];
  List<dynamic> _categories = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _isAddingProperty = false;
  bool _isEditingProperty = false;
  int? _editingPropertyId;
  double _formHeight = 0;
  // Variables pour le mode concessionnaire
  bool _isConcessionnaire = false;
  final TextEditingController _nomConcessionnaireController =
      TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  final TextEditingController _nbVehiculesController = TextEditingController();

  // Listes pour les concessionnaires
  final List<String> _availableVehicleTypes = [
    'Berline',
    'SUV',
    'Coupé',
    'Cabriolet',
    'Break',
    'Monospace',
    '4x4',
    'Utilitaire',
    'Citadine',
    'Sportive',
    'Luxe',
  ];

  final List<String> _availableCarBrands = [
    'Audi',
    'BMW',
    'Citroën',
    'Dacia',
    'Fiat',
    'Ford',
    'Honda',
    'Hyundai',
    'Kia',
    'Mercedes',
    'Nissan',
    'Opel',
    'Peugeot',
    'Renault',
    'Seat',
    'Skoda',
    'Toyota',
    'Volkswagen',
    'Volvo',
  ];

  final List<String> _availableDealerServices = [
    'Financement',
    'Garantie',
    'Entretien',
    'Réparation',
    'Reprise',
    'Location',
    'Essai',
    'Livraison',
    'Service après-vente',
    'Personnalisation',
    'Assurance',
  ];

  final List<String> _availableTravelAmenities = [
    'Guide touristique',
    'Transport inclus',
    'Hébergement inclus',
    'Activités organisées',
    'Assurance voyage',
    'Repas inclus',
    'Excursions',
    'Billets d\'avion inclus',
    'Service de réservation',
    'Wi-Fi gratuit',
    'Service de traduction',
    'Support 24/7',
  ];

  final List<String> _availableShoppingAmenities = [
    'Supermarché',
    'Boutique de vêtements',
    'Magasin d\'électronique',
    'Librairie',
    'Centre commercial',
    'Magasin de sport',
    'Bijouterie',
    'Magasin de meubles',
    'Pharmacie',
    'Magasin de jouets',
    'Parking gratuit',
    'Wi-Fi gratuit',
    'Accessibilité handicapés',
    'Service de livraison',
    'Réservation en ligne',
    'Promotions et réductions',
    'Paiement sans contact',
    'Espace enfants',
    'Service après-vente',
    'Retours et échanges faciles',
    'Assistance clientèle',
  ];
  final List<String> _availableRestaurantAmenities = [
    'Cuisine marocaine',
    'Cuisine italienne',
    'Cuisine française',
    'Cuisine asiatique',
    'Cuisine végétarienne',
    'Cuisine sans gluten',
    'Menu enfant',
    'Menu à emporter',
    'Livraison à domicile',
    'Réservation en ligne',
    'Buffet',
    'Service à table',
    'Wi-Fi gratuit',
    'Parking gratuit',
    'Accessibilité handicapés',
    'Espace enfants',
    'Terrasse',
    'Salle privée',
    'Musique live',
    'Paiement sans contact',
    'Service après-vente',
  ];
  List<String> _selectedShoppingAmenities = [];
  List<String> _selectedRestaurantAmenities = [];

  List<String> _selectedVehicleTypes = [];
  List<String> _selectedCarBrands = [];
  List<String> _selectedDealerServices = [];

  // Replace these variables
  MapController? _mapController = MapController();
  latlong.LatLng _selectedLocation = latlong.LatLng(
    31.7917,
    -7.0926,
  ); // Center of Morocco
  Set<CustomMarker> _markers = {};
  bool _isMapReady = false;

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  // Selected values
  int? _selectedCityId;
  String _selectedCityName = "";
  int? _selectedCategoryId;
  List<String> _selectedAmenities = [];

  int itemsPerPage = 30;
  int currentPage = 1; // Commence à 1
  int totalPages = 1;

  // Controllers pour les voitures
  final TextEditingController _marqueController = TextEditingController();
  final TextEditingController _modeleController = TextEditingController();
  final TextEditingController _anneeController = TextEditingController();
  final TextEditingController _kilometrageController = TextEditingController();

  // Options pour les voitures
  final List<String> _carburantOptions = [
    'Essence',
    'Diesel',
    'Hybride',
    'Électrique',
    'GPL',
  ];

  final List<String> _transmissionOptions = [
    'Manuelle',
    'Automatique',
    'Semi-automatique',
  ];

  // Sélections pour les voitures
  String? _selectedCarburant;
  String? _selectedTransmission;
  List<String> _selectedCarEquipements = [];

  // Map pour stocker les attributs de voiture
  Map<String, String> _carAttributes = {};

  // Équipements disponibles pour les voitures
  final List<String> _availableCarEquipements = [
    'Climatisation',
    'GPS',
    'Bluetooth',
    'Caméra de recul',
    'Régulateur de vitesse',
    'Sièges chauffants',
    'Toit ouvrant',
    'Jantes alliage',
    'Airbags',
    'ABS',
    'ESP',
    'Aide au stationnement',
    'Vitres électriques',
    'Verrouillage centralisé',
    'Radio',
    'USB',
    'Prise 12V',
  ];

  // Available amenities
  final List<String> _availableAmenities = [
    'Wifi',
    'Parking',
    'Piscine',
    'Climatisation',
    'Chauffage',
    'Cuisine équipée',
    'Télévision',
    'Lave-linge',
    'Sèche-linge',
    'Fer à repasser',
    'Sèche-cheveux',
    'Ascenseur',
    'Balcon',
    'Terrasse',
  ];

  @override
  void initState() {
    super.initState();
    _fetchProperties();
    _fetchCities();
    _fetchCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  String _currentFormType = CategoryFormType.DEFAULT;
  List<String> _selectedLanguages = [];
  List<String> _selectedServices = [];
  List<String> _selectedPaymentMethods = [];
  Map<String, String> _businessHours = {
    'lundi': '',
    'mardi': '',
    'mercredi': '',
    'jeudi': '',
    'vendredi': '',
    'samedi': '',
    'dimanche': '',
  };

  // Available options for different fields
  final List<String> _availableLanguages = [
    'Français',
    'Anglais',
    'Arabe',
    'Espagnol',
    'Allemand',
  ];

  final List<String> _availableServices = [
    'Rendez-vous en ligne',
    'Téléconsultation',
    'Dossier médical numérique',
    'Urgences',
    'Consultation à domicile',
  ];

  final List<String> _availablePaymentMethods = [
    'Espèces',
    'Carte bancaire',
    'Chèque',
    'Virement bancaire',
    'Mobile payment',
  ];

  List<int> pages = [];

  // Helper method to update car attributes
  void _updateCarAttribute(String key, String value) {
    setState(() {
      _carAttributes[key] = value;
    });
  }

  // Helper method to extract car attributes from comodites
  Map<String, String> _extractCarAttributes(Map<String, dynamic> property) {
    final result = <String, String>{};

    if (property['comodites'] != null && property['comodites'] is List) {
      for (final item in property['comodites']) {
        if (item is String && item.contains(':')) {
          final parts = item.split(':');
          if (parts.length == 2) {
            result[parts[0].trim()] = parts[1].trim();
          }
        }
      }
    }

    return result;
  }

  // Update the _onCategoryChanged method
  void _onCategoryChanged(int? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      if (categoryId != null) {
        _currentFormType = CategoryFormType.getFormTypeForCategory(
          categoryId,
          _categories,
        );

        // Reset specialized fields when changing category type
        if (_currentFormType == CategoryFormType.SANTE ||
            _currentFormType == CategoryFormType.RESTAURANT ||
            _currentFormType == CategoryFormType.SHOPPING) {
          _selectedLanguages = [];
          _selectedServices = [];
          _selectedPaymentMethods = [];
          _businessHours = {
            'lundi': '09:00-18:00',
            'mardi': '09:00-18:00',
            'mercredi': '09:00-18:00',
            'jeudi': '09:00-18:00',
            'vendredi': '09:00-18:00',
            'samedi': '09:00-13:00',
            'dimanche': 'Fermé',
          };
        }
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    final loc.Location location = loc.Location();
    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;
    loc.LocationData locationData;

    // Vérifier si le service de localisation est activé
    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    // Vérifier les permissions
    permissionGranted = await location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) {
        return;
      }
    }

    // Obtenir la position actuelle
    locationData = await location.getLocation();

    if (locationData.latitude != null && locationData.longitude != null) {
      setState(() {
        _selectedLocation = latlong.LatLng(
          locationData.latitude!,
          locationData.longitude!,
        );
        _updateMarker();
      });

      // Mettre à jour les champs de latitude et longitude
      _latitudeController.text = _selectedLocation.latitude.toString();
      _longitudeController.text = _selectedLocation.longitude.toString();

      // Centrer la carte sur la position actuelle
      _mapController?.move(_selectedLocation, 15);

      // Update address based on coordinates
      _updateAddressFromCoordinates();
    }
  }

  // Update the marker method
  void _updateMarker() {
    setState(() {
      _markers = {CustomMarker(position: _selectedLocation, draggable: true)};
    });
  }

  // Méthode pour mettre à jour l'adresse à partir des coordonnées
  Future<void> _updateAddressFromCoordinates() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _selectedLocation.latitude,
        _selectedLocation.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address = [
          place.street,
          place.locality,
          place.postalCode,
          place.country,
        ].where((element) => element != null && element.isNotEmpty).join(', ');

        if (address.isNotEmpty && _addressController.text.isEmpty) {
          _addressController.text = address;
        }
      }
    } catch (e) {
      print('Erreur lors de la récupération de l\'adresse: $e');
    }
  }

  void goToPage(int page) {
    _fetchProperties();
  }

  Future<void> _fetchProperties() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userDataString = prefs.getString('userData');
      final userData = json.decode(userDataString!);

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse(
          'https://maroceasy.konnekt.fr/api/annonces?&user.id=${userData['id']}&page=$currentPage&nom=$_searchQuery',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _properties = data['hydra:member'];
            currentPage = 1;
            totalPages = (data['hydra:totalItems'] / itemsPerPage).ceil();
            pages = List.generate(totalPages, (index) => index + 1);
            print('Fetched properties: ${_properties.length}');
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        await _handleTokenExpiration();
      } else {
        throw Exception('Failed to load properties');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _fetchCities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('https://maroceasy.konnekt.fr/api/villes'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _cities = data['hydra:member'];
          });
        }
      } else if (response.statusCode == 401) {
        await _handleTokenExpiration();
      } else {
        throw Exception('Failed to load cities');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading cities: $e')));
      }
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('https://maroceasy.konnekt.fr/api/categories'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _categories = data['hydra:member'];
            _onCategoryChanged(_categories.first['id']);
          });
        }
      } else if (response.statusCode == 401) {
        await _handleTokenExpiration();
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading categories: $e')));
      }
    }
  }

  TimeOfDay _parseTimeString(String timeRange, {required bool isOpeningTime}) {
    if (timeRange == 'Fermé') {
      return TimeOfDay(hour: 9, minute: 0); // Default time
    }

    try {
      final parts = timeRange.split('-');
      final timeStr = isOpeningTime ? parts[0].trim() : parts[1].trim();
      final timeParts = timeStr.split(':');
      return TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
    } catch (e) {
      // Return default time if parsing fails
      return TimeOfDay(hour: isOpeningTime ? 9 : 18, minute: 0);
    }
  }

  // Helper method to get opening time from time range string
  String _getOpenTimeFromString(String timeRange) {
    if (timeRange == 'Fermé') return 'Fermé';
    try {
      return timeRange.split('-')[0].trim();
    } catch (e) {
      return '09:00';
    }
  }

  // Helper method to get closing time from time range string
  String _getCloseTimeFromString(String timeRange) {
    if (timeRange == 'Fermé') return 'Fermé';
    try {
      return timeRange.split('-')[1].trim();
    } catch (e) {
      return '18:00';
    }
  }

  Future<void> _handleTokenExpiration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Votre session a expiré. Veuillez vous reconnecter.'),
        ),
      );

      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  List<Widget> _buildPaginationPages() {
    const int maxVisiblePages = 5;
    List<Widget> widgets = [];

    int startPage = (currentPage - 2).clamp(1, totalPages);
    int endPage = (currentPage + 2).clamp(1, totalPages);

    if (startPage > 1) {
      widgets.add(_buildPageButton(1));
      if (startPage > 2) {
        widgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0),
            child: Text('...'),
          ),
        );
      }
    }

    for (int i = startPage; i <= endPage; i++) {
      widgets.add(_buildPageButton(i));
    }

    if (endPage < totalPages) {
      if (endPage < totalPages - 1) {
        widgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0),
            child: Text('...'),
          ),
        );
      }
      widgets.add(_buildPageButton(totalPages));
    }

    return widgets;
  }

  Widget _buildPageButton(int page) {
    final isSelected = page == currentPage;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor:
              isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
          foregroundColor: isSelected ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {
          setState(() {
            currentPage = page;
            _fetchProperties();
          });
        },
        child: Text(
          '$page',
          style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
        ),
      ),
    );
  }

  void _toggleAddPropertyForm() {
    setState(() {
      _isAddingProperty = !_isAddingProperty;
      _isEditingProperty = false;
      _editingPropertyId = null;
      _formHeight = _isAddingProperty ? 600 : 0;

      if (_isAddingProperty) {
        // Clear form fields
        _nameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _addressController.clear();
        _websiteController.clear();
        _descriptionController.clear();
        _priceController.clear();
        _latitudeController.clear();
        _longitudeController.clear();
        _selectedCityId = null;
        _selectedCategoryId = null;
        _selectedAmenities = [];
        _marqueController.clear();
        _modeleController.clear();
        _anneeController.clear();
        _kilometrageController.clear();
        _selectedCarburant = null;
        _selectedTransmission = null;
        _selectedCarEquipements = [];
        _carAttributes = {};
      }
    });
  }

  void _showEditPropertyForm(Map<String, dynamic> property) {
    _nameController.text = property['nom'] ?? '';
    _emailController.text = property['email'] ?? '';
    _phoneController.text = property['telephone'] ?? '';
    _addressController.text = property['adresse'] ?? '';
    _websiteController.text = property['siteWeb'] ?? '';
    _descriptionController.text = property['descriptionLongue'] ?? '';
    _priceController.text = property['prix']?.toString() ?? '';

    // Initialiser la position sur la carte
    if (property['latitude'] != null && property['longitude'] != null) {
      _latitudeController.text = property['latitude']?.toString() ?? '';
      _longitudeController.text = property['longitude']?.toString() ?? '';

      setState(() {
        _selectedLocation = latlong.LatLng(
          double.parse(_latitudeController.text),
          double.parse(_longitudeController.text),
        );
        _updateMarker();
      });
    }

    // Extract city ID from IRI
    if (property['ville'] != null) {
      final cityId = property['ville']['id'];
      _selectedCityId = cityId;
    }

    // Extract category ID from IRI
    if (property['category'] != null) {
      final categoryId = property['category']['id'];
      _selectedCategoryId = categoryId;
    }

    String categoryName = CategoryFormType.getFormTypeForCategory(
      _selectedCategoryId!,
      _categories,
    );

    // Set amenities
    if (categoryName == CategoryFormType.LOGEMENT ||
        categoryName == CategoryFormType.VOYAGE) {
      _selectedAmenities = List<String>.from(property['comodites'] ?? []);
    } else if (categoryName == CategoryFormType.SANTE) {
      _selectedLanguages = List<String>.from(property['langues'] ?? []);
      _selectedServices = List<String>.from(property['services'] ?? []);
      _selectedPaymentMethods = List<String>.from(
        property['moyensPaiement'] ?? [],
      );
      _businessHours = Map<String, String>.from(property['horaires'] ?? []);
    } else if (categoryName == CategoryFormType.SHOPPING ||
        categoryName == CategoryFormType.RESTAURANT) {
      _selectedShoppingAmenities = List<String>.from(
        property['comodites'] ?? [],
      );
      _businessHours = Map<String, String>.from(property['horaires'] ?? []);
    } else if (categoryName == CategoryFormType.VOITURE) {
      if (_isConcessionnaire) {
        final List<String> comodites = List<String>.from(
          property['comodites'] ?? [],
        );

        String? nomConcessionnaire;
        String? nbVehicules;
        String? minPrice;
        String? maxPrice;
        final List<String> vehicleTypes = [];
        final List<String> carBrands = [];
        final List<String> dealerServices = [];

        for (final item in comodites) {
          final parts = item.split(':');
          if (parts.length < 2) continue;

          final category = parts[0];

          if (category == 'concessionnaire' && parts.length == 3) {
            final key = parts[1];
            final value = parts[2];
            switch (key) {
              case 'nom':
                nomConcessionnaire = value;
                break;
              case 'nbVehicules':
                nbVehicules = value;
                break;
              case 'minPrice':
                minPrice = value;
                break;
              case 'maxPrice':
                maxPrice = value;
                break;
            }
          } else if (category == 'vehicleType' && parts.length == 2) {
            vehicleTypes.add(parts[1]);
          } else if (category == 'carBrand' && parts.length == 2) {
            carBrands.add(parts[1]);
          } else if (category == 'dealerService' && parts.length == 2) {
            dealerServices.add(parts[1]);
          }
        }

        _nomConcessionnaireController.text = nomConcessionnaire ?? '';
        _nbVehiculesController.text = nbVehicules ?? '';
        _minPriceController.text = minPrice ?? '';
        _maxPriceController.text = maxPrice ?? '';

        _selectedVehicleTypes = vehicleTypes;
        _selectedCarBrands = carBrands;
        _selectedDealerServices = dealerServices;

        _selectedDealerServices = List<String>.from(property['services'] ?? []);
      } else {
        // Store car attributes in comodites as "key:value" pairs
        final carComodites = List<String>.from(property['comodites'] ?? []);

        // Variables pour pré-remplir les contrôleurs
        String? marque;
        String? annee;
        String? modele;
        String? kilometrage;
        String? carburant;
        String? transmission;

        for (final item in carComodites) {
          final parts = item.split(':');
          if (parts.length < 2) continue;

          final key = parts[0].trim();
          final value = parts[1].trim();

          switch (key) {
            case 'marque':
              marque = value;
              break;
            case 'annee':
              annee = value;
              break;
            case 'modele':
              modele = value;
              break;
            case 'kilometrage':
              kilometrage = value;
              break;
            case 'carburant':
              carburant = value;
              break;
            case 'transmission':
              transmission = value;
              break;
          }
        }

        _marqueController.text = marque ?? '';
        _anneeController.text = annee ?? '';
        _modeleController.text = modele ?? '';
        _kilometrageController.text = kilometrage ?? '';
        _selectedCarburant = carburant;
        _selectedTransmission = transmission;

        // Add car-specific fields
        // Transformer carComodites en Map<String, String>
        final Map<String, String> carComoditesMap = {
          for (var item in carComodites) item.split(':')[0]: item.split(':')[1],
        };

        // Insérer dans _carAttributes
        _carAttributes.addAll(carComoditesMap);
        _selectedCarEquipements = List<String>.from(property['services'] ?? []);
      }
    }

    setState(() {
      _isEditingProperty = true;
      _isAddingProperty = false;
      _editingPropertyId = property['id'];
      _formHeight = 600;
    });
  }

  void _cancelForm() {
    setState(() {
      _isAddingProperty = false;
      _isEditingProperty = false;
      _editingPropertyId = null;
      _formHeight = 0;
    });
  }

  // Add image upload functionality
  Future<void> _uploadImage(int propertyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Use image_picker to select multiple images
      final ImagePicker _picker = ImagePicker();
      final List<XFile> images = await _picker.pickMultiImage();

      if (images.isEmpty) {
        // User canceled image selection
        return;
      }

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Téléchargement des images en cours...'),
          ),
        );
      }

      // Upload each image
      int successCount = 0;
      for (var image in images) {
        // Create multipart request
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('https://maroceasy.konnekt.fr/api/galerie'),
        );

        // Add headers
        request.headers.addAll({
          'Authorization': 'Bearer $token',
          'Accept': 'application/ld+json',
        });

        // Add form fields
        request.fields['annonce'] = '/api/annonces/$propertyId';
        request.fields['legende'] = '';

        // Add file
        request.files.add(
          await http.MultipartFile.fromPath('file', image.path),
        );

        // Send request
        var response = await request.send();

        if (response.statusCode == 201) {
          successCount++;
        } else if (response.statusCode == 401) {
          await _handleTokenExpiration();
          break;
        } else {
          final responseBody = await response.stream.bytesToString();
          print('Failed to upload image: $responseBody');
        }
      }

      if (mounted) {
        _fetchProperties(); // Refresh to show the updated property with images
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$successCount images ajoutées avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading images: $e')));
      }
    }
  }

  // Show confirmation dialog before deleting an image
  void _showDeleteImageConfirmation(int imageId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmer la suppression'),
            content: Text('Êtes-vous sûr de vouloir supprimer cette image ?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Annuler',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteImage(imageId);
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                child: const Text(
                  'Supprimer',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  // Delete an image from the gallery
  Future<void> _deleteImage(int imageId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.delete(
        Uri.parse('https://maroceasy.konnekt.fr/api/galerie/$imageId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 204) {
        if (mounted) {
          _fetchProperties(); // Refresh to update the property images
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image supprimée avec succès')),
          );
        }
      } else if (response.statusCode == 401) {
        await _handleTokenExpiration();
      } else {
        throw Exception('Failed to delete image');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _addProperty() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _selectedCityId == null ||
        _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
        ),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userDataString = prefs.getString('userData');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Get user ID from stored user data
      String userId = "1"; // Default value
      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        if (userData['id'] != null) {
          userId = userData['id'].toString();
        }
      }

      Map<String, dynamic> requestBody = {
        'nom': _nameController.text,
        'email': _emailController.text,
        'telephone': _phoneController.text,
        'adresse': _addressController.text,
        'siteWeb': _websiteController.text,
        'descriptionLongue': _descriptionController.text,
        'category': '/api/categories/$_selectedCategoryId',
        'ville': '/api/villes/$_selectedCityId',
        'latitude': double.parse(_latitudeController.text),
        'longitude': double.parse(_longitudeController.text),
        'prix': double.parse(_priceController.text),
        'user': '/api/users/${userId}',
      };

      // Add category-specific fields
      if (_currentFormType == CategoryFormType.LOGEMENT ||
          _currentFormType == CategoryFormType.VOYAGE) {
        requestBody['comodites'] = _selectedAmenities;
      } else if (_currentFormType == CategoryFormType.SANTE) {
        requestBody['langues'] = _selectedLanguages;
        requestBody['services'] = _selectedServices;
        requestBody['moyensPaiement'] = _selectedPaymentMethods;
        requestBody['horaires'] = _businessHours;
      } else if (_currentFormType == CategoryFormType.SHOPPING ||
          _currentFormType == CategoryFormType.RESTAURANT) {
        requestBody['comodites'] = _selectedShoppingAmenities;
        requestBody['horaires'] = _businessHours;
      } else if (_currentFormType == CategoryFormType.VOITURE) {
        if (_isConcessionnaire) {
          // Format concessionnaire data for API
          final List<String> concessionnaireComodites = [];

          // Ajouter les informations du concessionnaire
          concessionnaireComodites.add(
            'concessionnaire:nom:${_nomConcessionnaireController.text}',
          );
          concessionnaireComodites.add(
            'concessionnaire:nbVehicules:${_nbVehiculesController.text}',
          );
          concessionnaireComodites.add(
            'concessionnaire:minPrice:${_minPriceController.text}',
          );
          concessionnaireComodites.add(
            'concessionnaire:maxPrice:${_maxPriceController.text}',
          );

          // Ajouter les types de véhicules
          for (final type in _selectedVehicleTypes) {
            concessionnaireComodites.add('vehicleType:$type');
          }

          // Ajouter les marques
          for (final brand in _selectedCarBrands) {
            concessionnaireComodites.add('carBrand:$brand');
          }

          // Ajouter les services
          for (final service in _selectedDealerServices) {
            concessionnaireComodites.add('dealerService:$service');
          }

          requestBody['comodites'] = concessionnaireComodites;
          requestBody['services'] = _selectedDealerServices;
        } else {
          // Store car attributes in comodites as "key:value" pairs
          final carComodites = <String>[];
          _carAttributes.forEach((key, value) {
            if (value.isNotEmpty) {
              carComodites.add('$key:$value');
            }
          });

          // Add car-specific fields
          requestBody['comodites'] = carComodites;
          requestBody['services'] =
              _selectedCarEquipements; // Store equipments in services
        }
      }

      final response = await http.post(
        Uri.parse('https://maroceasy.konnekt.fr/api/annonces'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          _fetchProperties();
          _cancelForm();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('annonce ajoutée avec succès')),
          );
        }
      } else if (response.statusCode == 401) {
        await _handleTokenExpiration();
      } else {
        throw Exception('Failed to add property: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _updateProperty(int propertyId) async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _selectedCityId == null ||
        _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
        ),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userDataString = prefs.getString('userData');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Get user ID from stored user data
      String userId = "1"; // Default value
      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        if (userData['id'] != null) {
          userId = userData['id'].toString();
        }
      }

      Map<String, dynamic> requestBody = {
        'nom': _nameController.text,
        'email': _emailController.text,
        'telephone': _phoneController.text,
        'adresse': _addressController.text,
        'siteWeb': _websiteController.text,
        'descriptionLongue': _descriptionController.text,
        'category': '/api/categories/$_selectedCategoryId',
        'ville': '/api/villes/$_selectedCityId',
        'latitude': double.parse(_latitudeController.text),
        'longitude': double.parse(_longitudeController.text),
        'prix': double.parse(_priceController.text),
        'user': '/api/users/${userId}',
      };

      // Add category-specific fields
      if (_currentFormType == CategoryFormType.LOGEMENT ||
          _currentFormType == CategoryFormType.VOYAGE) {
        requestBody['comodites'] = _selectedAmenities;
      } else if (_currentFormType == CategoryFormType.SANTE) {
        requestBody['langues'] = _selectedLanguages;
        requestBody['services'] = _selectedServices;
        requestBody['moyensPaiement'] = _selectedPaymentMethods;
        requestBody['horaires'] = _businessHours;
      } else if (_currentFormType == CategoryFormType.SHOPPING ||
          _currentFormType == CategoryFormType.RESTAURANT) {
        requestBody['comodites'] = _selectedShoppingAmenities;
        requestBody['horaires'] = _businessHours;
      } else if (_currentFormType == CategoryFormType.VOITURE) {
        if (_isConcessionnaire) {
          // Format concessionnaire data for API
          final List<String> concessionnaireComodites = [];

          // Ajouter les informations du concessionnaire
          concessionnaireComodites.add(
            'concessionnaire:nom:${_nomConcessionnaireController.text}',
          );
          concessionnaireComodites.add(
            'concessionnaire:nbVehicules:${_nbVehiculesController.text}',
          );
          concessionnaireComodites.add(
            'concessionnaire:minPrice:${_minPriceController.text}',
          );
          concessionnaireComodites.add(
            'concessionnaire:maxPrice:${_maxPriceController.text}',
          );

          // Ajouter les types de véhicules
          for (final type in _selectedVehicleTypes) {
            concessionnaireComodites.add('vehicleType:$type');
          }

          // Ajouter les marques
          for (final brand in _selectedCarBrands) {
            concessionnaireComodites.add('carBrand:$brand');
          }

          // Ajouter les services
          for (final service in _selectedDealerServices) {
            concessionnaireComodites.add('dealerService:$service');
          }

          requestBody['comodites'] = concessionnaireComodites;
          requestBody['services'] = _selectedDealerServices;
        } else {
          // Store car attributes in comodites as "key:value" pairs
          final carComodites = <String>[];
          _carAttributes.forEach((key, value) {
            if (value.isNotEmpty) {
              carComodites.add('$key:$value');
            }
          });

          // Add car-specific fields
          requestBody['comodites'] = carComodites;
          requestBody['services'] =
              _selectedCarEquipements; // Store equipments in services
        }
      }

      final response = await http.patch(
        Uri.parse('https://maroceasy.konnekt.fr/api/annonces/$propertyId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type':
              'application/merge-patch+json', // Changed from 'application/json'
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          _fetchProperties();
          _cancelForm();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('annonce modifiée avec succès')),
          );
        }
      } else if (response.statusCode == 401) {
        await _handleTokenExpiration();
      } else {
        print('Erreur update: ${response.body}');
        throw Exception('Failed to update property: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteProperty(int propertyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.delete(
        Uri.parse('https://maroceasy.konnekt.fr/api/annonces/$propertyId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 204) {
        if (mounted) {
          _fetchProperties();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('annonce supprimée avec succès')),
          );
        }
      } else if (response.statusCode == 401) {
        await _handleTokenExpiration();
      } else {
        throw Exception('Failed to delete property');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showDeleteConfirmation(Map<String, dynamic> property) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmer la suppression'),
            content: Text(
              'Êtes-vous sûr de vouloir supprimer "${property['nom']}" ?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Annuler',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteProperty(property['id']);
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                child: const Text(
                  'Supprimer',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  List<dynamic> get _filteredProperties {
    if (_searchQuery.isEmpty) {
      return _properties;
    }
    _fetchProperties();
    return _properties.where((property) {
      final name = property['nom']?.toString().toLowerCase() ?? '';
      final address = property['adresse']?.toString().toLowerCase() ?? '';
      final description =
          property['descriptionLongue']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return name.contains(query) ||
          address.contains(query) ||
          description.contains(query);
    }).toList();
  }

  Future<void> _updateCoordinatesFromAddress(String address) async {
    if (address.isEmpty) return;

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$address&format=json&limit=1',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          "User-Agent": "MyFlutterApp/1.0 (yvesconstant.ateba@gmail.com)",
        },
      );

      if (response.statusCode == 200) {
        print("okay");
        final data = json.decode(response.body);
        print(data);
        if (data.isNotEmpty) {
          double lat = double.parse(data[0]['lat']);
          double lon = double.parse(data[0]['lon']);

          print(lon);
          setState(() {
            _selectedLocation = LatLng(lat, lon);
            _latitudeController.text = lat.toString();
            _longitudeController.text = lon.toString();
            _updateMarker();
            _mapController!.move(_selectedLocation, 15.0);
          });
        }
      }
    } catch (e) {
      print("Erreur géocodage: $e");
    }
  }

  Timer? _timer;

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary; // 0xFFF1787A

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search + actions row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Rechercher une annonce...',
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                            filled: true,
                            fillColor: Theme.of(
                              context,
                            ).colorScheme.onSecondary.withOpacity(0.05),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                              _fetchProperties();
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    FloatingActionButton.small(
                      heroTag: 'fab_add_property',
                      onPressed: _toggleAddPropertyForm,
                      backgroundColor:
                          _isAddingProperty ? Colors.grey : primary,
                      child: Icon(
                        _isAddingProperty ? Icons.close : Icons.add,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(width: 8),

                    IconButton(
                      tooltip: 'Rafraîchir',
                      onPressed: _fetchProperties,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Pagination (visible si >1)
                if (totalPages > 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed:
                              currentPage > 1
                                  ? () {
                                    setState(() {
                                      currentPage--;
                                      _fetchProperties();
                                    });
                                  }
                                  : null,
                        ),
                        ..._buildPaginationPages(),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed:
                              currentPage < totalPages
                                  ? () {
                                    setState(() {
                                      currentPage++;
                                      _fetchProperties();
                                    });
                                  }
                                  : null,
                        ),
                      ],
                    ),
                  ),

                // Properties list
                Expanded(
                  child:
                      _isLoading
                          ? ListView.builder(
                            itemCount: 4,
                            itemBuilder:
                                (context, index) => const Padding(
                                  padding: EdgeInsets.only(bottom: 12),
                                  child: LoaderAnnonce(),
                                ),
                          )
                          : _properties.isEmpty
                          ? const Center(child: Text('Aucune annonce trouvée'))
                          : ListView.separated(
                            itemCount: _properties.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final property = _properties[index];
                              final gallery =
                                  property['galeriesPhoto'] as List?;
                              final price = property['prix'];
                              final cityName = property['ville']?['nom'];
                              final categoryName = property['category']?['nom'];

                              return Card(
                                elevation: 6,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                clipBehavior: Clip.antiAlias,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Image carousel or placeholder
                                    if (gallery != null && gallery.isNotEmpty)
                                      _buildImageCarousel(gallery)
                                    else
                                      Container(
                                        height: 180,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onTertiaryContainer,
                                        child: Center(
                                          child: Icon(
                                            Icons.image,
                                            size: 48,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onTertiary,
                                          ),
                                        ),
                                      ),

                                    Padding(
                                      padding: const EdgeInsets.all(14.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  property['nom'] ?? 'Sans nom',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                              ),
                                              if (price != null)
                                                Text(
                                                  '${price} MAD',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleSmall
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Theme.of(context)
                                                                .colorScheme
                                                                .primary,
                                                      ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              if (cityName != null) ...[
                                                Icon(
                                                  Icons.location_on_outlined,
                                                  size: 16,
                                                  color:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  cityName,
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall?.copyWith(
                                                    color:
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                              ],
                                              if (categoryName != null) ...[
                                                Icon(
                                                  Icons.category_outlined,
                                                  size: 16,
                                                  color:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  categoryName,
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall?.copyWith(
                                                    color:
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          if (property['adresse'] != null &&
                                              property['adresse'].isNotEmpty)
                                            Text(
                                              property['adresse'],
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodyMedium?.copyWith(
                                                color:
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                              ),
                                            ),
                                          const SizedBox(height: 8),
                                          if (property['descriptionLongue'] !=
                                              null)
                                            Text(
                                              property['descriptionLongue'],
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  Theme.of(
                                                    context,
                                                  ).textTheme.bodyMedium,
                                            ),
                                          const SizedBox(height: 12),

                                          // category-specific info
                                          _buildCategorySpecificInfo(property),

                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              _smallCircleIconButton(
                                                icon: Icons.add_photo_alternate,
                                                onPressed:
                                                    () => _uploadImage(
                                                      property['id'],
                                                    ),
                                                iconColor: primary,
                                                bgColor: Colors.white
                                                    .withOpacity(0.1),
                                              ),
                                              const SizedBox(width: 8),
                                              _smallCircleIconButton(
                                                icon: Icons.edit,
                                                onPressed:
                                                    () => _showEditPropertyForm(
                                                      property,
                                                    ),
                                                iconColor: Colors.blue,
                                                bgColor: Colors.white
                                                    .withOpacity(0.1),
                                              ),
                                              const SizedBox(width: 8),
                                              _smallCircleIconButton(
                                                icon: Icons.delete,
                                                onPressed:
                                                    () =>
                                                        _showDeleteConfirmation(
                                                          property,
                                                        ),
                                                bgColor: Colors.white
                                                    .withOpacity(0.1),
                                                iconColor: Colors.red,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                ),
              ],
            ),
          ),

          // Backdrop + dismiss when form open
          if (_isAddingProperty || _isEditingProperty) ...[
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  _cancelForm();
                },
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(color: Colors.black.withOpacity(0.22)),
                ),
              ),
            ),

            // Bottom sheet form modernisé
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.88,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.background,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 12,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _isEditingProperty
                                        ? 'Modifier l’annonce'
                                        : 'Ajouter une annonce',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: _cancelForm,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Name
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'Nom *',
                                  filled: true,

                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                validator:
                                    (value) =>
                                        (value == null || value.isEmpty)
                                            ? 'Veuillez entrer un nom'
                                            : null,
                              ),
                              const SizedBox(height: 12),

                              // Email + Phone
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _emailController,
                                      decoration: InputDecoration(
                                        labelText: 'Email *',
                                        filled: true,

                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      validator:
                                          (value) =>
                                              (value == null || value.isEmpty)
                                                  ? 'Veuillez entrer un email'
                                                  : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      decoration: InputDecoration(
                                        labelText: 'Téléphone *',
                                        filled: true,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      validator:
                                          (value) =>
                                              (value == null || value.isEmpty)
                                                  ? 'Veuillez entrer un numéro de téléphone'
                                                  : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // City / Category
                              DropdownButtonFormField<int>(
                                decoration: InputDecoration(
                                  labelText: 'Ville *',
                                  filled: true,

                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                value: _selectedCityId,
                                items:
                                    _cities.map<DropdownMenuItem<int>>((city) {
                                      return DropdownMenuItem<int>(
                                        value: city['id'],
                                        child: Text(city['nom']),
                                      );
                                    }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCityId = value;
                                    _selectedCityName =
                                        _cities.firstWhere(
                                          (c) => c["id"] == value,
                                          orElse: () => null,
                                        )['nom'];
                                    _addressController.text = "";
                                  });
                                  FocusScope.of(context).unfocus();
                                },
                                validator:
                                    (v) =>
                                        v == null
                                            ? "Veuillez sélectionner une ville"
                                            : null,
                              ),
                              const SizedBox(height: 12),
                              // Address search field (kept)
                              AddressSearchField(
                                city: _selectedCityName,
                                onAddressSelected: (address, lat, lon) {
                                  _addressController.text = address;
                                  _updateCoordinatesFromAddress(address);
                                },
                              ),
                              const SizedBox(height: 12),

                              // Website
                              TextField(
                                controller: _websiteController,
                                decoration: InputDecoration(
                                  labelText: 'Site Web',
                                  filled: true,

                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<int>(
                                decoration: InputDecoration(
                                  labelText: 'Catégorie *',
                                  filled: true,

                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                value: _selectedCategoryId,
                                items:
                                    _categories.map<DropdownMenuItem<int>>((
                                      category,
                                    ) {
                                      return DropdownMenuItem<int>(
                                        value: category['id'],
                                        child: Text(category['nom']),
                                      );
                                    }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCategoryId = value;
                                    _onCategoryChanged(_selectedCategoryId);
                                  });
                                },
                                validator:
                                    (v) =>
                                        v == null
                                            ? "Veuillez sélectionner une catégorie"
                                            : null,
                              ),

                              const SizedBox(height: 12),

                              // Price
                              TextFormField(
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Prix *',
                                  filled: true,

                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                validator:
                                    (v) =>
                                        (v == null || v.isEmpty)
                                            ? 'Veuillez entrer un prix'
                                            : null,
                              ),

                              const SizedBox(height: 12),

                              // Map for picking location
                              const SizedBox(height: 8),
                              const Text(
                                'Position sur la carte:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 260,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Stack(
                                    children: [
                                      FlutterMap(
                                        mapController: _mapController,
                                        options: MapOptions(
                                          initialCenter: _selectedLocation,
                                          initialZoom: 15,
                                          onTap: (tapPosition, point) {
                                            setState(() {
                                              _selectedLocation = point;
                                              _updateMarker();
                                              _latitudeController.text =
                                                  point.latitude.toString();
                                              _longitudeController.text =
                                                  point.longitude.toString();
                                              _updateAddressFromCoordinates();
                                            });
                                          },
                                        ),
                                        children: [
                                          TileLayer(
                                            urlTemplate:
                                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                            userAgentPackageName:
                                                'com.konnekt.maroceasy',
                                          ),
                                          MarkerLayer(
                                            markers:
                                                _markers
                                                    .map(
                                                      (marker) => Marker(
                                                        point: marker.position,
                                                        width: 40,
                                                        height: 40,
                                                        child: Icon(
                                                          Icons.location_pin,
                                                          color: primary,
                                                          size: 40,
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                          ),
                                        ],
                                      ),
                                      Positioned(
                                        left: 10,
                                        bottom: 10,
                                        child: FloatingActionButton(
                                          mini: true,
                                          backgroundColor:
                                              Theme.of(
                                                context,
                                              ).colorScheme.background,
                                          child: Icon(
                                            Icons.my_location,
                                            color: primary,
                                          ),
                                          onPressed: _getCurrentLocation,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Lat / Lon readonly
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _latitudeController,
                                      decoration: InputDecoration(
                                        labelText: 'Latitude',
                                        filled: true,

                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        suffixIcon: const Icon(
                                          Icons.location_on,
                                        ),
                                      ),
                                      readOnly: true,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _longitudeController,
                                      decoration: InputDecoration(
                                        labelText: 'Longitude',
                                        filled: true,

                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        suffixIcon: const Icon(
                                          Icons.location_on,
                                        ),
                                      ),
                                      readOnly: true,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Description
                              TextFormField(
                                controller: _descriptionController,
                                decoration: InputDecoration(
                                  labelText: 'Description *',
                                  filled: true,

                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                maxLines: 4,
                                validator:
                                    (v) =>
                                        (v == null || v.isEmpty)
                                            ? 'Veuillez entrer une description'
                                            : null,
                              ),

                              const SizedBox(height: 12),

                              // Category-specific fields kept
                              _buildCategorySpecificFields(
                                _isEditingProperty ? _selectedCategoryId! : 0,
                              ),

                              const SizedBox(height: 18),

                              // Submit row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: _cancelForm,
                                    child: const Text('Annuler'),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                        if (_isEditingProperty) {
                                          _updateProperty(_editingPropertyId!);
                                        } else {
                                          _addProperty();
                                        }
                                        FocusScope.of(context).unfocus();
                                        _cancelForm();
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Veillez remplir tous les champs obligatoires.',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primary,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      _isEditingProperty
                                          ? 'Mettre à jour'
                                          : 'Ajouter',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper: small circular icon button (keeps look consistent)
  Widget _smallCircleIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color bgColor = Colors.white,
    Color iconColor = Colors.black,
  }) {
    return Material(
      color: bgColor,
      shape: const CircleBorder(),
      child: IconButton(
        icon: Icon(icon, size: 18, color: iconColor),
        onPressed: onPressed,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildImageCarousel(List<dynamic> images) {
    final PageController pageController = PageController();
    int currentPage = 0;

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            Stack(
              children: [
                // ✅ Carousel avec coins arrondis + ombre
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: PageView.builder(
                      controller: pageController,
                      itemCount: images.length,
                      onPageChanged: (index) {
                        setState(() => currentPage = index);
                      },
                      itemBuilder: (context, index) {
                        final imageUrl = images[index]['urlPhoto'];
                        return GestureDetector(
                          onTap: () {
                            // 🔍 Hero preview plein écran
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => Scaffold(
                                      backgroundColor: Colors.black,
                                      body: GestureDetector(
                                        onTap: () => Navigator.pop(context),
                                        child: Center(
                                          child: Hero(
                                            tag: 'image-$index',
                                            child: Image.network(
                                              imageUrl,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                              ),
                            );
                          },
                          child: Hero(
                            tag: 'image-$index',
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              loadingBuilder: (
                                context,
                                child,
                                loadingProgress,
                              ) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                    size: 60,
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // 🔹 Flèches de navigation
                Positioned(
                  left: 8,
                  top: 0,
                  bottom: 0,
                  child: _carouselNavButton(Icons.arrow_back_ios_new, () {
                    if (currentPage > 0) {
                      pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  }),
                ),
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: _carouselNavButton(Icons.arrow_forward_ios, () {
                    if (currentPage < images.length - 1) {
                      pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  }),
                ),
                // Delete button overlay
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed:
                        () => _showDeleteImageConfirmation(
                          images[currentPage]['id'],
                        ),
                    icon: Icon(
                      Icons.delete,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black26.withOpacity(0.3),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ✅ Indicateur de pages stylé
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  width: currentPage == index ? 18 : 6,
                  decoration: BoxDecoration(
                    color:
                        currentPage == index
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 🔸 Petit helper pour les flèches
  Widget _carouselNavButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildCategorySpecificFields(int categoryId) {
    String _formType =
        _isEditingProperty
            ? _currentFormType = CategoryFormType.getFormTypeForCategory(
              categoryId,
              _categories,
            )
            : _currentFormType;

    Widget buildSectionTitle(String title) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
    }

    Widget buildChipList(
      List<String> items,
      List<String> selectedItems, {
      required void Function(String, bool) onSelected,
    }) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children:
            items.map((item) {
              final isSelected = selectedItems.contains(item);
              return FilterChip(
                label: Text(item),
                selected: isSelected,
                onSelected: (selected) => onSelected(item, selected),
                selectedColor: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(0.1),
                backgroundColor: Colors.grey.shade200,
                checkmarkColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(
                  color:
                      isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.black87,
                ),
              );
            }).toList(),
      );
    }

    Widget buildBusinessHoursRow(String day, String value) {
      final openTimeStr = _getOpenTimeFromString(value);
      final closeTimeStr = _getCloseTimeFromString(value);

      Color getLockColor() {
        return value == 'Fermé'
            ? Theme.of(context).colorScheme.secondary.withOpacity(0.5)
            : Theme.of(context).colorScheme.primary.withOpacity(0.5);
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              child: Text(
                '${day[0].toUpperCase()}${day.substring(1)}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Row(
                children: [
                  // Bouton ouverture
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surface.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant.withOpacity(0.5),
                            ),
                          ),
                          child: TextButton(
                            onPressed:
                                value == 'Fermé'
                                    ? null
                                    : () async {
                                      final TimeOfDay? openTime =
                                          await showTimePicker(
                                            context: context,
                                            initialTime: _parseTimeString(
                                              value,
                                              isOpeningTime: true,
                                            ),
                                          );
                                      if (openTime != null) {
                                        setState(() {
                                          final newOpen =
                                              '${openTime.hour.toString().padLeft(2, '0')}:${openTime.minute.toString().padLeft(2, '0')}';
                                          _businessHours[day] =
                                              '$newOpen-$closeTimeStr';
                                        });
                                      }
                                    },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              value == 'Fermé' ? 'Fermé' : openTimeStr,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '-',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  // Bouton fermeture
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surface.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant.withOpacity(0.5),
                            ),
                          ),
                          child: TextButton(
                            onPressed:
                                value == 'Fermé'
                                    ? null
                                    : () async {
                                      final TimeOfDay? closeTime =
                                          await showTimePicker(
                                            context: context,
                                            initialTime: _parseTimeString(
                                              value,
                                              isOpeningTime: false,
                                            ),
                                          );
                                      if (closeTime != null) {
                                        setState(() {
                                          final newClose =
                                              '${closeTime.hour.toString().padLeft(2, '0')}:${closeTime.minute.toString().padLeft(2, '0')}';
                                          _businessHours[day] =
                                              '$openTimeStr-$newClose';
                                        });
                                      }
                                    },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              value == 'Fermé' ? 'Fermé' : closeTimeStr,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Icône verrou avec verre
                  ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceVariant.withOpacity(0.6),
                        ),
                        child: IconButton(
                          icon: Icon(
                            value == 'Fermé' ? Icons.lock_open : Icons.lock,
                            color: getLockColor(),
                          ),
                          onPressed: () {
                            setState(() {
                              _businessHours[day] =
                                  value == 'Fermé' ? '09:00-18:00' : 'Fermé';
                            });
                          },
                          tooltip: value == 'Fermé' ? 'Ouvrir' : 'Fermer',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget buildToggleOption({
      required IconData icon,
      required String label,
      required bool isSelected,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  color:
                      isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    color:
                        isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.black87,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    switch (_formType) {
      case CategoryFormType.SANTE:
        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildSectionTitle(
                  'Informations spécifiques pour professionnel de santé',
                ),
                buildSectionTitle('Langues parlées'),
                buildChipList(
                  _availableLanguages,
                  _selectedLanguages,
                  onSelected: (item, selected) {
                    setState(() {
                      selected
                          ? _selectedLanguages.add(item)
                          : _selectedLanguages.remove(item);
                    });
                  },
                ),
                buildSectionTitle('Services proposés'),
                buildChipList(
                  _availableServices,
                  _selectedServices,
                  onSelected: (item, selected) {
                    setState(() {
                      selected
                          ? _selectedServices.add(item)
                          : _selectedServices.remove(item);
                    });
                  },
                ),
                buildSectionTitle('Moyens de paiement acceptés'),
                buildChipList(
                  _availablePaymentMethods,
                  _selectedPaymentMethods,
                  onSelected: (item, selected) {
                    setState(() {
                      selected
                          ? _selectedPaymentMethods.add(item)
                          : _selectedPaymentMethods.remove(item);
                    });
                  },
                ),
                buildSectionTitle('Horaires d\'ouverture'),
                ..._businessHours.entries
                    .map(
                      (entry) => buildBusinessHoursRow(entry.key, entry.value),
                    )
                    .toList(),
              ],
            ),
          ),
        );

      case CategoryFormType.LOGEMENT:
        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildSectionTitle('Commodités'),
                buildChipList(
                  _availableAmenities,
                  _selectedAmenities,
                  onSelected: (item, selected) {
                    setState(() {
                      selected
                          ? _selectedAmenities.add(item)
                          : _selectedAmenities.remove(item);
                    });
                  },
                ),
              ],
            ),
          ),
        );

      case CategoryFormType.VOYAGE:
        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildSectionTitle('Commodités voyage'),
                buildChipList(
                  _availableTravelAmenities,
                  _selectedAmenities,
                  onSelected: (item, selected) {
                    setState(() {
                      selected
                          ? _selectedAmenities.add(item)
                          : _selectedAmenities.remove(item);
                    });
                  },
                ),
              ],
            ),
          ),
        );

      case CategoryFormType.VOITURE:
        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildSectionTitle('Informations spécifiques pour véhicule'),
                Row(
                  children: [
                    buildToggleOption(
                      icon: Icons.directions_car,
                      label: 'Véhicule individuel',
                      isSelected: !_isConcessionnaire,
                      onTap: () => setState(() => _isConcessionnaire = false),
                    ),
                    const SizedBox(width: 12),
                    buildToggleOption(
                      icon: Icons.store,
                      label: 'Concessionnaire',
                      isSelected: _isConcessionnaire,
                      onTap: () => setState(() => _isConcessionnaire = true),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _isConcessionnaire
                    ? _buildConcessionnaireFields()
                    : _buildVehiculeIndividuelFields(),
              ],
            ),
          ),
        );

      case CategoryFormType.SHOPPING:
        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildSectionTitle('Informations spécifiques pour shopping'),
                buildSectionTitle('Commodités pour shopping'),
                buildChipList(
                  _availableShoppingAmenities,
                  _selectedShoppingAmenities,
                  onSelected: (item, selected) {
                    setState(() {
                      selected
                          ? _selectedShoppingAmenities.add(item)
                          : _selectedShoppingAmenities.remove(item);
                    });
                  },
                ),
                buildSectionTitle('Horaires d\'ouverture'),
                ..._businessHours.entries
                    .map(
                      (entry) => buildBusinessHoursRow(entry.key, entry.value),
                    )
                    .toList(),
              ],
            ),
          ),
        );

      case CategoryFormType.RESTAURANT:
        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildSectionTitle('Informations spécifiques pour restaurant'),
                buildSectionTitle('Commodités pour restaurant'),
                buildChipList(
                  _availableRestaurantAmenities,
                  _selectedShoppingAmenities,
                  onSelected: (item, selected) {
                    setState(() {
                      selected
                          ? _selectedShoppingAmenities.add(item)
                          : _selectedShoppingAmenities.remove(item);
                    });
                  },
                ),
                buildSectionTitle('Horaires d\'ouverture'),
                ..._businessHours.entries
                    .map(
                      (entry) => buildBusinessHoursRow(entry.key, entry.value),
                    )
                    .toList(),
              ],
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  // Display information specific to lodging properties
  Widget _buildLogementInfo(Map<String, dynamic> property) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (property['comodites'] != null &&
            (property['comodites'] as List).isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Commodités',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children:
                    (property['comodites'] as List)
                        .map(
                          (amenity) => Chip(
                            label: Text(amenity),
                            backgroundColor: Colors.grey[200]?.withOpacity(0.5),
                            labelStyle: const TextStyle(fontSize: 12),
                          ),
                        )
                        .toList(),
              ),
            ],
          ),
      ],
    );
  }

  // Display information specific to healthcare properties
  Widget _buildSanteInfo(Map<String, dynamic> property) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Languages
        if (property['langues'] != null &&
            (property['langues'] as List).isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Langues parlées',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children:
                    (property['langues'] as List)
                        .map(
                          (language) => Chip(
                            label: Text(language),
                            backgroundColor: Colors.blue[50]?.withOpacity(0.5),
                            labelStyle: const TextStyle(fontSize: 12),
                          ),
                        )
                        .toList(),
              ),
            ],
          ),

        const SizedBox(height: 8),

        // Services
        if (property['services'] != null &&
            (property['services'] as List).isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Services proposés',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children:
                    (property['services'] as List)
                        .map(
                          (service) => Chip(
                            label: Text(service),
                            backgroundColor: Colors.green[50]?.withOpacity(0.5),
                            labelStyle: const TextStyle(fontSize: 12),
                          ),
                        )
                        .toList(),
              ),
            ],
          ),

        const SizedBox(height: 8),

        // Payment methods
        if (property['moyensPaiement'] != null &&
            (property['moyensPaiement'] as List).isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Moyens de paiement',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children:
                    (property['moyensPaiement'] as List)
                        .map(
                          (method) => Chip(
                            label: Text(method),
                            backgroundColor: Colors.amber[50]?.withOpacity(0.5),
                            labelStyle: const TextStyle(fontSize: 12),
                          ),
                        )
                        .toList(),
              ),
            ],
          ),

        const SizedBox(height: 8),

        // Business hours
        if (property['horaires'] != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Horaires d\'ouverture',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              _buildBusinessHoursDisplay(property['horaires']),
            ],
          ),
      ],
    );
  }

  Widget _buildShoppingInfo(Map<String, dynamic> property) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Payment methods
        if (property['comodites'] != null &&
            (property['comodites'] as List).isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informations générales',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children:
                    (property['comodites'] as List)
                        .map(
                          (method) => Chip(
                            label: Text(method),
                            backgroundColor: Colors.amber[50]?.withOpacity(0.5),
                            labelStyle: const TextStyle(fontSize: 12),
                          ),
                        )
                        .toList(),
              ),
            ],
          ),

        const SizedBox(height: 8),

        // Business hours
        if (property['horaires'] != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Horaires d\'ouverture',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              _buildBusinessHoursDisplay(property['horaires']),
            ],
          ),
      ],
    );
  }

  // Display information specific to restaurant properties
  Widget _buildRestaurantInfo(Map<String, dynamic> property) {
    // For now, similar to healthcare but can be customized later
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cuisine types or specialties could go here
        if (property['comodites'] != null &&
            (property['comodites'] as List).isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informations générales',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children:
                    (property['comodites'] as List)
                        .map(
                          (specialty) => Chip(
                            label: Text(specialty),
                            backgroundColor: Colors.orange[50]?.withOpacity(
                              0.5,
                            ),
                            labelStyle: const TextStyle(fontSize: 12),
                          ),
                        )
                        .toList(),
              ),
            ],
          ),

        const SizedBox(height: 8),

        // Business hours
        if (property['horaires'] != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Horaires d\'ouverture',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              _buildBusinessHoursDisplay(property['horaires']),
            ],
          ),
      ],
    );
  }

  // Default display for other property types
  Widget _buildDefaultInfo(Map<String, dynamic> property) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (property['comodites'] != null &&
            (property['comodites'] as List).isNotEmpty)
          Wrap(
            spacing: 8,
            children:
                (property['comodites'] as List)
                    .map(
                      (amenity) => Chip(
                        label: Text(amenity),
                        backgroundColor: Colors.grey[200]?.withOpacity(0.5),
                      ),
                    )
                    .toList(),
          ),
      ],
    );
  }

  // Helper method to display business hours
  Widget _buildBusinessHoursDisplay(Map<String, dynamic> horaires) {
    return Column(
      children:
          horaires.entries.map<Widget>((entry) {
            final day = entry.key.toString();
            final hours = entry.value.toString();
            final isClosed = hours.toLowerCase() == 'fermé';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08), // Glass effect
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text(
                            '${day[0].toUpperCase()}${day.substring(1)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isClosed
                                      ? Colors.red.withOpacity(0.2)
                                      : Colors.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isClosed ? 'Fermé' : hours,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color:
                                    isClosed
                                        ? Colors.redAccent
                                        : Colors.green[800],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isClosed ? Icons.lock_open : Icons.lock,
                          color:
                              isClosed ? Colors.redAccent : Colors.green[700],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  // Method to display category-specific information
  Widget _buildCategorySpecificInfo(Map<String, dynamic> property) {
    // Determine the property type based on its category
    final categoryType = CategoryFormType.getFormTypeForCategory(
      property['category']?['id'],
      _categories,
    );

    switch (categoryType) {
      case CategoryFormType.LOGEMENT:
        return _buildLogementInfo(property);
      case CategoryFormType.SANTE:
        return _buildSanteInfo(property);
      case CategoryFormType.RESTAURANT:
        return _buildRestaurantInfo(property);
      case CategoryFormType.VOITURE:
        return _buildVoitureInfo(property);
      case CategoryFormType.SHOPPING:
        return _buildShoppingInfo(property);
      default:
        return _buildDefaultInfo(property);
    }
  }

  // Display information specific to car properties
  Widget _buildVoitureInfo(Map<String, dynamic> property) {
    final isConcessionnaire = _isPropertyConcessionnaire(property);

    if (isConcessionnaire) {
      return _buildConcessionnaireInfo(property);
    } else {
      final carAttributes = _extractCarAttributes(property);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Car specs
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (carAttributes['marque'] != null &&
                  carAttributes['modele'] != null)
                _buildSpecItem(
                  Icons.directions_car,
                  '${carAttributes['marque']} ${carAttributes['modele']}',
                  backgroundColor: Colors.blue[50],
                ),
              if (carAttributes['annee'] != null)
                _buildSpecItem(
                  Icons.calendar_today,
                  'Année: ${carAttributes['annee']}',
                  backgroundColor: Colors.green[50],
                ),
              if (carAttributes['kilometrage'] != null)
                _buildSpecItem(
                  Icons.speed,
                  '${carAttributes['kilometrage']} km',
                  backgroundColor: Colors.amber[50],
                ),
              if (carAttributes['carburant'] != null)
                _buildSpecItem(
                  Icons.local_gas_station,
                  carAttributes['carburant']!,
                  backgroundColor: Colors.red[50],
                ),
              if (carAttributes['transmission'] != null)
                _buildSpecItem(
                  Icons.settings,
                  carAttributes['transmission']!,
                  backgroundColor: Colors.purple[50],
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Équipements (from services)
          if (property['services'] != null &&
              (property['services'] as List).isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Équipements',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children:
                      (property['services'] as List)
                          .map(
                            (equipement) => Chip(
                              label: Text(equipement),
                              backgroundColor: Colors.blue[50]?.withOpacity(
                                0.2,
                              ),
                              labelStyle: const TextStyle(fontSize: 12),
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
        ],
      );
    }
  }

  // Afficher les informations d'un concessionnaire
  Widget _buildConcessionnaireInfo(Map<String, dynamic> property) {
    // Extraire les informations du concessionnaire
    final concessionnaireInfo = _extractConcessionnaireInfo(property);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nom du concessionnaire
        if (concessionnaireInfo['nom'] != null)
          Text(
            concessionnaireInfo['nom']!,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        const SizedBox(height: 12),

        // Nombre de véhicules
        if (concessionnaireInfo['nbVehicules'] != null)
          _buildSpecItem(
            Icons.directions_car,
            'Environ ${concessionnaireInfo['nbVehicules']} véhicules disponibles',
            backgroundColor: Colors.blue[50],
          ),
        const SizedBox(height: 12),

        // Gamme de prix
        if (concessionnaireInfo['minPrice'] != null &&
            concessionnaireInfo['maxPrice'] != null)
          _buildSpecItem(
            Icons.euro,
            'Prix: ${concessionnaireInfo['minPrice']}€ - ${concessionnaireInfo['maxPrice']}€',
            backgroundColor: Colors.green[50],
          ),
        const SizedBox(height: 16),

        // Types de véhicules
        if (concessionnaireInfo['vehicleTypes'] != null &&
            concessionnaireInfo['vehicleTypes'].isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Types de véhicules',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children:
                    (concessionnaireInfo['vehicleTypes'] as List)
                        .map(
                          (type) => Chip(
                            label: Text(type),
                            backgroundColor: Colors.purple[50]?.withOpacity(
                              0.5,
                            ),
                            labelStyle: const TextStyle(fontSize: 12),
                          ),
                        )
                        .toList(),
              ),
            ],
          ),
        const SizedBox(height: 12),

        // Marques disponibles
        if (concessionnaireInfo['carBrands'] != null &&
            concessionnaireInfo['carBrands'].isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Marques disponibles',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children:
                    (concessionnaireInfo['carBrands'] as List)
                        .map(
                          (brand) => Chip(
                            label: Text(brand),
                            backgroundColor: Colors.blue[50]?.withOpacity(0.5),
                            labelStyle: const TextStyle(fontSize: 12),
                          ),
                        )
                        .toList(),
              ),
            ],
          ),
        const SizedBox(height: 12),

        // Services proposés
        if (concessionnaireInfo['dealerServices'] != null &&
            concessionnaireInfo['dealerServices'].isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Services proposés',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children:
                    (concessionnaireInfo['dealerServices'] as List)
                        .map(
                          (service) => Chip(
                            label: Text(service),
                            backgroundColor: Colors.amber[50]?.withOpacity(0.5),
                            labelStyle: const TextStyle(fontSize: 12),
                          ),
                        )
                        .toList(),
              ),
            ],
          ),
      ],
    );
  }

  // Vérifier si une annonce est un concessionnaire
  bool _isPropertyConcessionnaire(Map<String, dynamic> property) {
    if (property['comodites'] != null && property['comodites'] is List) {
      return (property['comodites'] as List).any(
        (item) => item is String && item.startsWith('concessionnaire:'),
      );
    }
    return false;
  }

  // Extraire les informations du concessionnaire
  Map<String, dynamic> _extractConcessionnaireInfo(
    Map<String, dynamic> property,
  ) {
    final result = <String, dynamic>{};

    if (property['comodites'] != null && property['comodites'] is List) {
      for (final item in property['comodites']) {
        if (item is String && item.startsWith('concessionnaire:')) {
          final parts = item.split(':');
          if (parts.length >= 3) {
            result[parts[1]] = parts[2];
          }
        }
      }

      // Extraire les types de véhicules, marques et services
      final vehicleTypes = <String>[];
      final carBrands = <String>[];
      final dealerServices = <String>[];

      for (final item in property['comodites']) {
        if (item is String) {
          if (item.startsWith('vehicleType:')) {
            vehicleTypes.add(item.substring('vehicleType:'.length));
          } else if (item.startsWith('carBrand:')) {
            carBrands.add(item.substring('carBrand:'.length));
          } else if (item.startsWith('dealerService:')) {
            dealerServices.add(item.substring('dealerService:'.length));
          }
        }
      }

      result['vehicleTypes'] = vehicleTypes;
      result['carBrands'] = carBrands;
      result['dealerServices'] = dealerServices;
    }

    return result;
  }

  // Champs pour un concessionnaire avec plusieurs voitures
  Widget _buildConcessionnaireFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nom du concessionnaire
        TextField(
          controller: _nomConcessionnaireController,
          decoration: const InputDecoration(
            labelText: 'Nom du concessionnaire',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // Types de véhicules proposés
        const Text(
          'Types de véhicules proposés',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _availableVehicleTypes.map((type) {
                final isSelected = _selectedVehicleTypes.contains(type);
                return FilterChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedVehicleTypes.add(type);
                      } else {
                        _selectedVehicleTypes.remove(type);
                      }
                    });
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.2),
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                );
              }).toList(),
        ),
        const SizedBox(height: 16),

        // Marques disponibles
        const Text(
          'Marques disponibles',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _availableCarBrands.map((brand) {
                final isSelected = _selectedCarBrands.contains(brand);
                return FilterChip(
                  label: Text(brand),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCarBrands.add(brand);
                      } else {
                        _selectedCarBrands.remove(brand);
                      }
                    });
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.2),
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                );
              }).toList(),
        ),
        const SizedBox(height: 16),

        // Services proposés
        const Text(
          'Services proposés',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _availableDealerServices.map((service) {
                final isSelected = _selectedDealerServices.contains(service);
                return FilterChip(
                  label: Text(service),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedDealerServices.add(service);
                      } else {
                        _selectedDealerServices.remove(service);
                      }
                    });
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.2),
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                );
              }).toList(),
        ),
        const SizedBox(height: 16),

        // Gamme de prix
        const Text(
          'Gamme de prix',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minPriceController,
                decoration: const InputDecoration(
                  labelText: 'Prix minimum',
                  border: OutlineInputBorder(),
                  prefixText: '€ ',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _maxPriceController,
                decoration: const InputDecoration(
                  labelText: 'Prix maximum',
                  border: OutlineInputBorder(),
                  prefixText: '€ ',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Nombre approximatif de véhicules
        TextField(
          controller: _nbVehiculesController,
          decoration: const InputDecoration(
            labelText: 'Nombre approximatif de véhicules',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  // Champs pour un véhicule individuel
  Widget _buildVehiculeIndividuelFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Marque et modèle (stockés dans comodites)
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _marqueController,
                decoration: const InputDecoration(
                  labelText: 'Marque',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _updateCarAttribute('marque', value);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _modeleController,
                decoration: const InputDecoration(
                  labelText: 'Modèle',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _updateCarAttribute('modele', value);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Année et kilométrage
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _anneeController,
                decoration: const InputDecoration(
                  labelText: 'Année',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _updateCarAttribute('annee', value);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _kilometrageController,
                decoration: const InputDecoration(
                  labelText: 'Kilométrage',
                  border: OutlineInputBorder(),
                  suffixText: 'km',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _updateCarAttribute('kilometrage', value);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Carburant et transmission
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedCarburant,
                decoration: const InputDecoration(
                  labelText: 'Carburant',
                  border: OutlineInputBorder(),
                ),
                items:
                    _carburantOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCarburant = newValue;
                    if (newValue != null) {
                      _updateCarAttribute('carburant', newValue);
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedTransmission,
                decoration: const InputDecoration(
                  labelText: 'Transmission',
                  border: OutlineInputBorder(),
                ),
                items:
                    _transmissionOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedTransmission = newValue;
                    if (newValue != null) {
                      _updateCarAttribute('transmission', newValue);
                    }
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Équipements (stockés dans services)
        const Text(
          'Équipements',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _availableCarEquipements.map((equipement) {
                final isSelected = _selectedCarEquipements.contains(equipement);
                return FilterChip(
                  label: Text(equipement),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCarEquipements.add(equipement);
                      } else {
                        _selectedCarEquipements.remove(equipement);
                      }
                    });
                  },
                  backgroundColor: Colors.grey[200]?.withOpacity(0.2),
                  selectedColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.2),
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildSpecItem(IconData icon, String text, {Color? backgroundColor}) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (backgroundColor ?? theme.colorScheme.surfaceVariant)
                .withOpacity(0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
