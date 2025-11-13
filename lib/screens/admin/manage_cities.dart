import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maroceasy/widgets/loader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class ManageCities extends StatefulWidget {
  const ManageCities({Key? key}) : super(key: key);

  @override
  State<ManageCities> createState() => _ManageCitiesState();
}

class _ManageCitiesState extends State<ManageCities> {
  List<dynamic> _cities = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _isAddingCity = false;
  bool _isEditingCity = false;
  int? _editingCityId;
  double _formHeight = 0;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchCities();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _regionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _fetchCities() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

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
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load cities');
      }
    } catch (e) {
      print("Erreur $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _addCity() async {
    try {
      if (_nameController.text.isEmpty) {
        throw Exception('Le nom de la ville est requis');
      }

      if (_selectedImage == null) {
        throw Exception('Une image est requise');
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://maroceasy.konnekt.fr/api/villes'),
      );

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'accept': 'application/ld+json',
      });

      // Add text fields
      request.fields['nom'] = _nameController.text;

      if (_regionController.text.isNotEmpty) {
        request.fields['region'] = _regionController.text;
      } else
        request.fields['region'] = "Non défini";

      // Add file
      var imageFile = await http.MultipartFile.fromPath(
        'pictoFile',
        _selectedImage!.path,
        filename: path.basename(_selectedImage!.path),
      );
      request.files.add(imageFile);

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        if (mounted) {
          _fetchCities();
          _nameController.clear();
          _regionController.clear();
          setState(() {
            _selectedImage = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ville ajoutée avec succès')),
          );
        }
      } else {
        throw Exception('Failed to add city: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _updateCity(int cityId) async {
    try {
      if (_nameController.text.isEmpty) {
        throw Exception('Le nom de la ville est requis');
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Non authentifié');
      }

      final uri = Uri.parse('https://maroceasy.konnekt.fr/api/villes/$cityId');
      final request =
          http.MultipartRequest('POST', uri)
            ..headers['Authorization'] = 'Bearer $token'
            ..headers['accept'] = 'application/ld+json'
            ..fields['nom'] = _nameController.text;

      if (_regionController.text.isNotEmpty) {
        request.fields['region'] = _regionController.text;
      }

      if (_selectedImage != null) {
        final imageFile = await http.MultipartFile.fromPath(
          'pictoFile',
          _selectedImage!.path,
          filename: path.basename(_selectedImage!.path),
        );
        request.files.add(imageFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        if (mounted) {
          _fetchCities();
          _nameController.clear();
          _regionController.clear();
          setState(() {
            _selectedImage = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ville modifiée avec succès')),
          );
        }
      } else {
        throw Exception(
          'Échec de la mise à jour de la ville: ${response.body}',
        );
      }
    } catch (e) {
      print('Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _deleteCity(int cityId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.delete(
        Uri.parse('https://maroceasy.konnekt.fr/api/villes/$cityId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 204) {
        if (mounted) {
          _fetchCities();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ville supprimée avec succès')),
          );
        }
      } else {
        throw Exception('Failed to delete city');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  List<dynamic> get _filteredCities {
    if (_searchQuery.isEmpty) {
      return _cities;
    }

    return _cities.where((city) {
      final name = city['nom']?.toString().toLowerCase() ?? '';
      final description = city['description']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();

      return name.contains(query) || description.contains(query);
    }).toList();
  }

  void _toggleAddCityForm() {
    setState(() {
      _isAddingCity = !_isAddingCity;
      _isEditingCity = false;
      _editingCityId = null;
      _formHeight = _isAddingCity ? 600 : 0;

      if (_isAddingCity) {
        // Clear form fields when opening
        _nameController.clear();
        _descriptionController.clear();
        _regionController.clear();
        _latitudeController.clear();
        _longitudeController.clear();
        _selectedImage = null;
      }
    });
  }

  void _showEditCityForm(Map<String, dynamic> city) {
    setState(() {
      _isEditingCity = true;
      _isAddingCity = false;
      _editingCityId = city['id'];
      _formHeight = 600;

      // Fill form fields with city data
      _nameController.text = city['nom'] ?? '';
      _descriptionController.text = city['description'] ?? '';
      _regionController.text = city['region'] ?? '';
      _latitudeController.text = city['latitude']?.toString() ?? '';
      _longitudeController.text = city['longitude']?.toString() ?? '';
      _selectedImage = null;
    });
  }

  void _cancelForm() {
    setState(() {
      _isAddingCity = false;
      _isEditingCity = false;
      _editingCityId = null;
      _formHeight = 0;
    });
  }

  void _showDeleteConfirmation(Map<String, dynamic> city) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmer la suppression'),
            content: Text(
              'Êtes-vous sûr de vouloir supprimer la ville "${city['nom']}" ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Annuler',
                  style: const TextStyle(color: Colors.pink),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteCity(city['id']);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Supprimer'),
              ),
            ],
          ),
    );
  }

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barre de recherche + bouton ajouter
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Rechercher une ville...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.grey,
                        ),
                        filled: true,
                        fillColor: Theme.of(
                          context,
                        ).colorScheme.onSecondary.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                      onChanged:
                          (value) => setState(() {
                            _searchQuery = value;
                          }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton.small(
                    onPressed: _toggleAddCityForm,
                    backgroundColor:
                        _isAddingCity
                            ? Colors.grey
                            : Theme.of(context).colorScheme.primary,
                    child: Icon(
                      _isAddingCity ? Icons.close : Icons.add,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Liste des villes
              Expanded(
                child:
                    _isLoading
                        ? ListView.builder(
                          itemCount: 4,
                          itemBuilder: (_, __) => LoaderVille(),
                        )
                        : _filteredCities.isEmpty
                        ? const Center(child: Text('Aucune ville trouvée'))
                        : ListView.builder(
                          itemCount: _filteredCities.length,
                          itemBuilder: (context, index) {
                            final city = _filteredCities[index];
                            return Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              margin: const EdgeInsets.only(bottom: 16),
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                children: [
                                  if (city['picto'] != null &&
                                      city['picto'].isNotEmpty)
                                    Image.network(
                                      city['picto'],
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (_, __, ___) => Container(
                                            color: Colors.grey[300],
                                            height: 180,
                                            child: const Icon(
                                              Icons.image,
                                              size: 50,
                                            ),
                                          ),
                                    ),
                                  Container(
                                    height: 180,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.black.withOpacity(0.6),
                                          Colors.transparent,
                                        ],
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 12,
                                    left: 16,
                                    child: Text(
                                      city['nom'] ?? 'Sans nom',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Row(
                                      children: [
                                        IconButton(
                                          onPressed:
                                              () => _showEditCityForm(city),
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.white,
                                          ),
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.black26
                                                .withOpacity(0.3),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed:
                                              () =>
                                                  _showDeleteConfirmation(city),
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.white,
                                          ),
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.black26
                                                .withOpacity(0.3),
                                          ),
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

        // Overlay sombre et flou pour le formulaire
        if (_isAddingCity || _isEditingCity)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
                _cancelForm();
              },
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(color: Colors.black.withOpacity(0.3)),
              ),
            ),
          ),

        // Formulaire moderne
        if (_isAddingCity || _isEditingCity)
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _isEditingCity
                                  ? 'Modifier la ville'
                                  : 'Ajouter une ville',
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
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Nom de la ville *',
                            filled: true,
                            fillColor: Theme.of(
                              context,
                            ).colorScheme.onSecondary.withOpacity(0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator:
                              (value) =>
                                  (value == null || value.isEmpty)
                                      ? "Veuillez entrer le nom de la ville"
                                      : null,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _regionController,
                          decoration: InputDecoration(
                            labelText: 'Région',
                            filled: true,
                            fillColor: Theme.of(
                              context,
                            ).colorScheme.onSecondary.withOpacity(0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: _pickImage,
                          child: Container(
                            height: 160,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child:
                                _selectedImage != null
                                    ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        _selectedImage!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                    : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.add_photo_alternate,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _isEditingCity
                                              ? 'Nouvelle image (optionnel)'
                                              : 'Sélectionner une image',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _cancelForm,
                              child: const Text(
                                'Annuler',
                                style: TextStyle(color: Colors.pink),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  if (!_isEditingCity &&
                                      _selectedImage == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Veuillez sélectionner une image.",
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  if (_isEditingCity &&
                                      _editingCityId != null) {
                                    _updateCity(_editingCityId!);
                                  } else {
                                    _addCity();
                                  }
                                  FocusScope.of(context).unfocus();
                                  _cancelForm();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pink,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                _isEditingCity ? 'Enregistrer' : 'Ajouter',
                                style: const TextStyle(color: Colors.white),
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
      ],
    );
  }
}
