import 'dart:convert';
import 'dart:io';
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
              // Search and add city row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Rechercher une ville...',
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
                  const SizedBox(width: 16),
                  IconButton(
                    icon: Icon(
                      _isAddingCity ? Icons.close : Icons.add,
                      color: Colors.white,
                    ),
                    onPressed: _toggleAddCityForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isAddingCity ? Colors.grey : Colors.pink,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Cities list
              Expanded(
                child:
                    _isLoading
                        ? Center(
                          child: ListView.builder(
                            itemCount: 4,
                            itemBuilder: (context, index) => LoaderVille(),
                          ),
                        )
                        : _filteredCities.isEmpty
                        ? const Center(child: Text('Aucune ville trouvée'))
                        : ListView.builder(
                          itemCount: _filteredCities.length,
                          itemBuilder: (context, index) {
                            final city = _filteredCities[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Image
                                  if (city['picto'] != null &&
                                      city['picto'].isNotEmpty)
                                    Image.network(
                                      city['picto'],
                                      width: double.infinity,
                                      height: 150,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (_, __, ___) => Container(
                                            width: double.infinity,
                                            height: 150,
                                            color: Colors.grey[300],
                                            child: const Icon(
                                              Icons.image_not_supported,
                                              size: 50,
                                              color: Colors.grey,
                                            ),
                                          ),
                                    ),

                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          city['nom'] ?? 'Sans nom',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit,
                                                color: Colors.blue,
                                              ),
                                              onPressed: () {
                                                _showEditCityForm(city);
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.pink,
                                              ),
                                              onPressed: () {
                                                _showDeleteConfirmation(city);
                                              },
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

        // Invisible overlay to detect taps outside the form
        if (_isAddingCity || _isEditingCity)
          Positioned.fill(
            child: GestureDetector(
              onTap: _cancelForm,
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),
          ),
        Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            height: _formHeight,
            curve: Curves.easeInOut,
            child: SingleChildScrollView(
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
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
                        // Rest of the form content remains the same
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nom de la ville *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Veuillez entrer le nom de la ville";
                            }
                            return null; // ✅ pas d'erreur
                          },
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _regionController,
                          decoration: const InputDecoration(
                            labelText: 'Région',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 16),
                        if (_isEditingCity && _editingCityId != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Image actuelle:'),
                              const SizedBox(height: 8),
                              Container(
                                height: 100,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child:
                                    _cities.firstWhere(
                                              (city) =>
                                                  city['id'] == _editingCityId,
                                              orElse: () => {'picto': ''},
                                            )['picto'] !=
                                            null
                                        ? Image.network(
                                          _cities.firstWhere(
                                            (city) =>
                                                city['id'] == _editingCityId,
                                            orElse: () => {'picto': ''},
                                          )['picto'],
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (_, __, ___) => const Center(
                                                child: Icon(
                                                  Icons.image_not_supported,
                                                  size: 50,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                        )
                                        : const Center(
                                          child: Text('Pas d\'image'),
                                        ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        InkWell(
                          onTap: _pickImage,
                          child: Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child:
                                _selectedImage != null
                                    ? Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
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
                                style: const TextStyle(color: Colors.pink),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  // ✅ Vérification supplémentaire pour l'image si on ajoute
                                  if (!_isEditingCity &&
                                      _selectedImage == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Veuillez sélectionner une image.",
                                        ),
                                      ),
                                    );
                                    return; // ❌ Stoppe l'ajout
                                  }

                                  // ✅ tous les champs obligatoires sont remplis
                                  if (_isEditingCity &&
                                      _editingCityId != null) {
                                    _updateCity(_editingCityId!);
                                  } else {
                                    _addCity();
                                  }
                                  _cancelForm();
                                  // 🔽 Fermer le clavier
                                  FocusScope.of(context).unfocus();
                                } else {
                                  // ❌ au moins un champ est vide → erreur affichée en rouge
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Veuillez corriger les erreurs.',
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pink,
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
        ),
      ],
    );
  }
}
