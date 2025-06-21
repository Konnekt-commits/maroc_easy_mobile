import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
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
  int? _selectedCategoryId;
  List<String> _selectedAmenities = [];

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
          'https://maroceasy.konnekt.fr/api/annonces?&user.id=${userData['id']}',
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

    // Set amenities
    _selectedAmenities = List<String>.from(property['comodites'] ?? []);

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
                child: const Text(
                  'Annuler',
                  style: TextStyle(color: Colors.pink),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteImage(imageId);
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                    Colors.pink,
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

      final Map<String, dynamic> propertyData = {
        'nom': _nameController.text,
        'email': _emailController.text,
        'telephone': _phoneController.text,
        'adresse': _addressController.text,
        'siteWeb': _websiteController.text,
        'descriptionLongue': _descriptionController.text,
        'category': '/api/categories/$_selectedCategoryId',
        'ville': '/api/villes/$_selectedCityId',
        'user': '/api/users/$userId',
        'comodites': _selectedAmenities,
      };

      // Add optional numeric fields if they're not empty
      if (_priceController.text.isNotEmpty) {
        propertyData['prix'] = double.parse(_priceController.text);
      }
      if (_latitudeController.text.isNotEmpty) {
        propertyData['latitude'] = double.parse(_latitudeController.text);
      }
      if (_longitudeController.text.isNotEmpty) {
        propertyData['longitude'] = double.parse(_longitudeController.text);
      }

      final response = await http.post(
        Uri.parse('https://maroceasy.konnekt.fr/api/annonces'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(propertyData),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          _fetchProperties();
          _cancelForm();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Propriété ajoutée avec succès')),
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

      final Map<String, dynamic> propertyData = {
        'nom': _nameController.text,
        'email': _emailController.text,
        'telephone': _phoneController.text,
        'adresse': _addressController.text,
        'siteWeb': _websiteController.text,
        'descriptionLongue': _descriptionController.text,
        'category': '/api/categories/$_selectedCategoryId',
        'ville': '/api/villes/$_selectedCityId',
        'user': '/api/users/$userId',
        'comodites': _selectedAmenities,
      };

      // Add optional numeric fields if they're not empty
      if (_priceController.text.isNotEmpty) {
        propertyData['prix'] = double.parse(_priceController.text);
      }
      if (_latitudeController.text.isNotEmpty) {
        propertyData['latitude'] = double.parse(_latitudeController.text);
      }
      if (_longitudeController.text.isNotEmpty) {
        propertyData['longitude'] = double.parse(_longitudeController.text);
      }

      final response = await http.patch(
        Uri.parse('https://maroceasy.konnekt.fr/api/annonces/$propertyId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type':
              'application/merge-patch+json', // Changed from 'application/json'
        },
        body: json.encode(propertyData),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          _fetchProperties();
          _cancelForm();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Propriété modifiée avec succès')),
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
            const SnackBar(content: Text('Propriété supprimée avec succès')),
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
                child: const Text(
                  'Annuler',
                  style: TextStyle(color: Colors.pink),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteProperty(property['id']);
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.pink),
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

  String _getCityName(String cityIri) {
    final cityId = int.tryParse(cityIri.split('/').last);
    if (cityId == null) return 'Ville inconnue';

    final city = _cities.firstWhere(
      (city) => city['id'] == cityId,
      orElse: () => {'nom': 'Ville inconnue'},
    );

    return city['nom'];
  }

  String _getCategoryName(String categoryIri) {
    final categoryId = int.tryParse(categoryIri.split('/').last);
    if (categoryId == null) return 'Catégorie inconnue';

    final category = _categories.firstWhere(
      (category) => category['id'] == categoryId,
      orElse: () => {'nom': 'Catégorie inconnue'},
    );

    return category['nom'];
  }

  List<dynamic> get _filteredProperties {
    if (_searchQuery.isEmpty) {
      return _properties;
    }
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search and add property row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Rechercher une propriété...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _toggleAddPropertyForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _fetchProperties,
                    tooltip: 'Rafraîchir',
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Properties list
              Expanded(
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredProperties.isEmpty
                        ? const Center(child: Text('Aucune propriété trouvée'))
                        : ListView.builder(
                          itemCount: _filteredProperties.length,
                          itemBuilder: (context, index) {
                            final property = _filteredProperties[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Add image carousel if property has images
                                    if (property['galeriesPhoto'] != null &&
                                        (property['galeriesPhoto'] as List)
                                            .isNotEmpty)
                                      _buildImageCarousel(
                                        property['galeriesPhoto'],
                                      ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            property['nom'] ?? 'Sans nom',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        if (property['prix'] != null)
                                          Text(
                                            '${property['prix']} MAD',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.pink,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        if (property['ville'] != null)
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.location_on,
                                                size: 16,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                property['ville']['nom'],
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        const SizedBox(width: 16),
                                        if (property['category'] != null)
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.category,
                                                size: 16,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                property['category']['nom'],
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    if (property['adresse'] != null &&
                                        property['adresse'].isNotEmpty)
                                      Text(
                                        property['adresse'],
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    if (property['descriptionLongue'] != null)
                                      Text(
                                        property['descriptionLongue'],
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    const SizedBox(height: 8),
                                    if (property['comodites'] != null &&
                                        (property['comodites'] as List)
                                            .isNotEmpty)
                                      Wrap(
                                        spacing: 8,
                                        children:
                                            (property['comodites'] as List)
                                                .map(
                                                  (amenity) => Chip(
                                                    label: Text(amenity),
                                                    backgroundColor:
                                                        Colors.grey[200],
                                                  ),
                                                )
                                                .toList(),
                                      ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add_photo_alternate,
                                            color: Colors.green,
                                          ),
                                          onPressed: () {
                                            _uploadImage(property['id']);
                                          },
                                          tooltip: 'Ajouter une image',
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.blue,
                                          ),
                                          onPressed: () {
                                            _showEditPropertyForm(property);
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () {
                                            _showDeleteConfirmation(property);
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
        // Invisible overlay to detect taps outside the form
        if (_isAddingProperty || _isEditingProperty)
          Positioned.fill(
            child: GestureDetector(
              onTap: _cancelForm,
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),
          ),

        // Form that slides up from bottom
        Align(
          alignment: Alignment.bottomCenter,
          child: Stack(
            children: [
              // Animated form container
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: _formHeight,
                curve: Curves.easeInOut,
                child: SingleChildScrollView(
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _isEditingProperty
                                    ? 'Modifier la propriété'
                                    : 'Ajouter une propriété',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              // Close button
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: _cancelForm,
                                tooltip: 'Fermer',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Form fields
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nom *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _emailController,
                                  decoration: const InputDecoration(
                                    labelText: 'Email *',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextField(
                                  controller: _phoneController,
                                  decoration: const InputDecoration(
                                    labelText: 'Téléphone *',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          TextField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              labelText: 'Adresse',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextField(
                            controller: _websiteController,
                            decoration: const InputDecoration(
                              labelText: 'Site Web',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  decoration: const InputDecoration(
                                    labelText: 'Ville *',
                                    border: OutlineInputBorder(),
                                  ),
                                  value: _selectedCityId,
                                  items:
                                      _cities.map<DropdownMenuItem<int>>((
                                        city,
                                      ) {
                                        return DropdownMenuItem<int>(
                                          value: city['id'],
                                          child: Text(city['nom']),
                                        );
                                      }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCityId = value;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  decoration: const InputDecoration(
                                    labelText: 'Catégorie *',
                                    border: OutlineInputBorder(),
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
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _priceController,
                                  decoration: const InputDecoration(
                                    labelText: 'Prix',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Carte pour sélectionner la position
                          const Text(
                            'Position sur la carte:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 300,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                children: [
                                  Container(
                                    height: 300,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(12),
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
                                                      point.longitude
                                                          .toString();
                                                  _updateAddressFromCoordinates();
                                                });
                                              },
                                            ),
                                            children: [
                                              TileLayer(
                                                urlTemplate:
                                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                                userAgentPackageName:
                                                    'com.konnekt.maroc_easy',
                                              ),
                                              MarkerLayer(
                                                markers:
                                                    _markers
                                                        .map(
                                                          (marker) => Marker(
                                                            point:
                                                                marker.position,
                                                            width: 40,
                                                            height: 40,
                                                            child: Icon(
                                                              Icons
                                                                  .location_pin,
                                                              color:
                                                                  Colors.pink,
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
                                              backgroundColor: Colors.white,
                                              child: Icon(
                                                Icons.my_location,
                                                color: Colors.pink,
                                              ),
                                              onPressed: _getCurrentLocation,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Champs de latitude et longitude (en lecture seule)
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _latitudeController,
                                  decoration: InputDecoration(
                                    labelText: 'Latitude',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    suffixIcon: Icon(Icons.location_on),
                                  ),
                                  readOnly: true,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _longitudeController,
                                  decoration: InputDecoration(
                                    labelText: 'Longitude',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    suffixIcon: Icon(Icons.location_on),
                                  ),
                                  readOnly: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          TextField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 4,
                          ),
                          const SizedBox(height: 16),

                          // Amenities selection
                          Text(
                            'Commodités',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                _availableAmenities.map((amenity) {
                                  final isSelected = _selectedAmenities
                                      .contains(amenity);
                                  return FilterChip(
                                    label: Text(amenity),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedAmenities.add(amenity);
                                        } else {
                                          _selectedAmenities.remove(amenity);
                                        }
                                      });
                                    },
                                    backgroundColor: Colors.grey[200],
                                    selectedColor: Colors.pink[100],
                                    checkmarkColor: Colors.pink,
                                  );
                                }).toList(),
                          ),

                          const SizedBox(height: 24),

                          // Submit button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: _cancelForm,
                                child: const Text('Annuler'),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed:
                                    _isEditingProperty
                                        ? () =>
                                            _updateProperty(_editingPropertyId!)
                                        : _addProperty,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.pink,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(
                                  _isEditingProperty
                                      ? 'Mettre à jour'
                                      : 'Ajouter',
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
            ],
          ),
        ),
      ],
    );
  }

  // Display image carousel for a property
  Widget _buildImageCarousel(List<dynamic> images) {
    if (images.isEmpty) {
      return Container(); // Return empty container if no images
    }

    final PageController pageController = PageController();
    int currentPage = 0;

    return StatefulBuilder(
      builder: (context, setState) {
        return Stack(
          children: [
            Container(
              height: 200,
              child: PageView.builder(
                controller: pageController,
                itemCount: images.length,
                onPageChanged: (index) {
                  setState(() {
                    currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final image = images[index];
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        image['urlPhoto'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text('Erreur de chargement de l\'image'),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                            ),
                          );
                        },
                      ),
                      // Delete button overlay
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: Icon(Icons.delete, color: Colors.pink),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                          ),
                          onPressed: () {
                            _showDeleteImageConfirmation(image['id']);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            // Left navigation arrow
            if (images.length > 1)
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black38,
                    ),
                    onPressed: () {
                      if (currentPage > 0) {
                        pageController.previousPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                ),
              ),
            // Right navigation arrow
            if (images.length > 1)
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: Icon(Icons.arrow_forward_ios, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black38,
                    ),
                    onPressed: () {
                      if (currentPage < images.length - 1) {
                        pageController.nextPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                ),
              ),
            // Page indicators
            if (images.length > 1)
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    images.length,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            currentPage == index
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
