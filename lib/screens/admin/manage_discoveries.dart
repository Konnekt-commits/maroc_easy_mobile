import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maroceasy/widgets/loader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class ManageDiscoveries extends StatefulWidget {
  const ManageDiscoveries({Key? key}) : super(key: key);

  @override
  State<ManageDiscoveries> createState() => _ManageDiscoveriesState();
}

class _ManageDiscoveriesState extends State<ManageDiscoveries> {
  List<dynamic> _discoveries = [];
  List<dynamic> _cities = [];
  List<dynamic> _categories = []; // Added categories list
  bool _isLoading = true;
  String _searchQuery = '';
  bool _isAddingDiscovery = false;
  bool _isEditingDiscovery = false;
  int? _editingDiscoveryId;
  double _formHeight = 0;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  int? _selectedCityId;
  int? _selectedCategoryId; // Added category selection
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchDiscoveries();
    _fetchCities();
    _fetchCategories(); // Added categories fetch
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    // Remove the line with _imageController.dispose() as it doesn't exist
    super.dispose();
  }

  // Add the missing _filteredDiscoveries getter
  List<dynamic> get _filteredDiscoveries {
    if (_searchQuery.isEmpty) {
      return _discoveries;
    }
    return _discoveries.where((discovery) {
      final title = discovery['titre']?.toString().toLowerCase() ?? '';
      final description =
          discovery['description']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return title.contains(query) || description.contains(query);
    }).toList();
  }

  // Add the missing _getCategoryName method
  String _getCategoryName(String categoryIri) {
    final categoryId = int.tryParse(categoryIri.split('/').last);
    if (categoryId == null) return 'Catégorie inconnue';

    final category = _categories.firstWhere(
      (category) => category['id'] == categoryId,
      orElse: () => {'nom': 'Catégorie inconnue'},
    );

    return category['nom'];
  }

  // Add the missing _deleteDiscovery method
  Future<void> _deleteDiscovery(int discoveryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.delete(
        Uri.parse('https://maroceasy.konnekt.fr/api/decouvertes/$discoveryId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 204) {
        if (mounted) {
          _fetchDiscoveries();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Découverte supprimée avec succès')),
          );
        }
      } else {
        throw Exception('Failed to delete discovery');
      }
    } catch (e) {
      if (mounted) {
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
        setState(() {
          _cities = data['hydra:member'];
        });
      } else {
        throw Exception('Failed to load cities');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading cities: $e')));
    }
  }

  Future<void> _fetchDiscoveries() async {
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
        Uri.parse('https://maroceasy.konnekt.fr/api/decouvertes'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _discoveries = data['hydra:member'];
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load discoveries');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _toggleAddDiscoveryForm() {
    setState(() {
      _isAddingDiscovery = !_isAddingDiscovery;
      _isEditingDiscovery = false;
      _editingDiscoveryId = null;
      _formHeight = _isAddingDiscovery ? 600 : 0;

      if (_isAddingDiscovery) {
        // Clear form fields when opening
        _titleController.clear();
        _descriptionController.clear();
        _selectedImage = null;
        _selectedCityId = null;
        _selectedCategoryId = null;
      }
    });
  }

  void _showEditDiscoveryForm(Map<String, dynamic> discovery) {
    _titleController.text = discovery['titre'] ?? '';
    _descriptionController.text = discovery['description'] ?? '';
    _selectedImage = null;

    // Extract city ID from IRI
    if (discovery['ville'] != null) {
      final cityId = discovery['ville']['id'];
      _selectedCityId = cityId;
    }

    // Extract category ID from IRI
    if (discovery['category'] != null) {
      final categoryId = discovery['category']['id'];
      _selectedCategoryId = categoryId;
    }

    setState(() {
      _isEditingDiscovery = true;
      _isAddingDiscovery = false;
      _editingDiscoveryId = discovery['id'];
      _formHeight = 600;
    });
  }

  void _cancelForm() {
    setState(() {
      _isAddingDiscovery = false;
      _isEditingDiscovery = false;
      _editingDiscoveryId = null;
      _formHeight = 0;
    });
  }

  Future<void> _addDiscovery() async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _selectedCityId == null ||
        _selectedCategoryId == null ||
        _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tous les champs sont requis')),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://maroceasy.konnekt.fr/api/decouvertes'),
      );

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'accept': 'application/ld+json',
      });

      // Add text fields
      request.fields['titre'] = _titleController.text;
      request.fields['description'] = _descriptionController.text;
      request.fields['ville'] = '/api/villes/$_selectedCityId';
      request.fields['category'] = '/api/categories/$_selectedCategoryId';

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
          _fetchDiscoveries();
          _cancelForm();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Découverte ajoutée avec succès')),
          );
        }
      } else {
        throw Exception('Failed to add discovery: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _updateDiscovery(int discoveryId) async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _selectedCityId == null ||
        _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tous les champs sont requis')),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://maroceasy.konnekt.fr/api/decouvertes/$discoveryId'),
      );

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'accept': 'application/ld+json',
      });

      // Add text fields
      request.fields['titre'] = _titleController.text;
      request.fields['description'] = _descriptionController.text;
      request.fields['ville'] = '/api/villes/$_selectedCityId';
      request.fields['category'] = '/api/categories/$_selectedCategoryId';

      // Add file if selected
      if (_selectedImage != null) {
        var imageFile = await http.MultipartFile.fromPath(
          'pictoFile',
          _selectedImage!.path,
          filename: path.basename(_selectedImage!.path),
        );
        request.files.add(imageFile);
      }

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        if (mounted) {
          _fetchDiscoveries();
          _cancelForm();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Découverte modifiée avec succès')),
          );
        }
      } else {
        print(response.body);
        throw Exception('Failed to update discovery: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showDeleteConfirmation(Map<String, dynamic> discovery) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmer la suppression'),
            content: Text(
              'Êtes-vous sûr de vouloir supprimer la découverte "${discovery['titre']}" ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteDiscovery(discovery['id']);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
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
              // Search and add discovery row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Rechercher une découverte...',
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
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: _toggleAddDiscoveryForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _fetchDiscoveries,
                    tooltip: 'Rafraîchir',
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Discoveries list
              Expanded(
                child:
                    _isLoading
                        ? Center(
                          child: ListView.builder(
                            itemCount: 4,
                            itemBuilder: (context, index) => LoaderDecouverte(),
                          ),
                        )
                        : _filteredDiscoveries.isEmpty
                        ? const Center(child: Text('Aucune découverte trouvée'))
                        : ListView.builder(
                          itemCount: _filteredDiscoveries.length,
                          itemBuilder: (context, index) {
                            final discovery = _filteredDiscoveries[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Image
                                  if (discovery['picto'] != null &&
                                      discovery['picto'].isNotEmpty)
                                    Image.network(
                                      discovery['picto'],
                                      width: double.infinity,
                                      height: 200,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (_, __, ___) => Container(
                                            width: double.infinity,
                                            height: 200,
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
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          discovery['titre'] ?? 'Sans titre',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            if (discovery['ville'] != null)
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.location_on,
                                                    size: 16,
                                                    color: Colors.grey,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    discovery['ville']['nom'],
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            const SizedBox(width: 16),
                                            if (discovery['category'] != null)
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.category,
                                                    size: 16,
                                                    color: Colors.grey,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    discovery['category']['nom'],
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          discovery['description'] ??
                                              'Pas de description',
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 16),
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
                                                _showEditDiscoveryForm(
                                                  discovery,
                                                );
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                              onPressed: () {
                                                _showDeleteConfirmation(
                                                  discovery,
                                                );
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
        if (_isAddingDiscovery || _isEditingDiscovery)
          Positioned.fill(
            child: GestureDetector(
              onTap: _cancelForm,
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),
          ),

        // Form that slides up from bottom
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
                              _isEditingDiscovery
                                  ? 'Modifier la découverte'
                                  : 'Ajouter une découverte',
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
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Titre',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer un titre';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer une description';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Ville',
                            border: OutlineInputBorder(),
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
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Veuillez sélectionner une ville';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Catégorie',
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
                          validator: (value) {
                            if (value == null) {
                              return 'Veuillez sélectionner une catégorie';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        if (_isEditingDiscovery && _editingDiscoveryId != null)
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
                                    _discoveries.firstWhere(
                                              (discovery) =>
                                                  discovery['id'] ==
                                                  _editingDiscoveryId,
                                              orElse: () => {'picto': ''},
                                            )['picto'] !=
                                            null
                                        ? Image.network(
                                          _discoveries.firstWhere(
                                            (discovery) =>
                                                discovery['id'] ==
                                                _editingDiscoveryId,
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
                                          _isEditingDiscovery
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
                                  if (!_isEditingDiscovery &&
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
                                  if (_isEditingDiscovery &&
                                      _editingDiscoveryId != null) {
                                    _updateDiscovery(_editingDiscoveryId!);
                                  } else {
                                    _addDiscovery();
                                  }
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
                                _isEditingDiscovery ? 'Enregistrer' : 'Ajouter',
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
