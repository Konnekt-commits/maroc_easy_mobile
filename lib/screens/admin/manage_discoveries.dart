import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maroceasy/widgets/annonceSearchField.dart';
import 'package:maroceasy/widgets/categoryIconMapper.dart';
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
  String _searchQueryAnnonce = '';
  bool _isAddingDiscovery = false;
  bool _isEditingDiscovery = false;
  int? _editingDiscoveryId;
  double _formHeight = 0;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _annonceController = TextEditingController();
  int? _selectedCityId;
  int? _selectedCategoryId; // Added category selection
  File? _selectedImage;
  int? _selectedAnnonceId;
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

  Future<void> _fetchAnnonces() async {
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
        Uri.parse(
          'https://maroceasy.konnekt.fr/api/annonces?page=1&nom=$_searchQueryAnnonce',
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
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
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
    _annonceController.text = '${discovery['annonce']['nom'] ?? ''}';
    _selectedAnnonceId = discovery['annonce']['id'] ?? '';
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
        _annonceController.text.isEmpty ||
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
      request.fields['annonce'] = '/api/annonces/$_selectedAnnonceId';

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
        _annonceController.text.isEmpty ||
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
      request.fields['annonce'] = '/api/annonces/$_selectedAnnonceId';

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
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary; // 0xFFF1787A
    final accent = theme.colorScheme.secondary; // 0xFF789E9E
    final neutral = Colors.grey[100]!;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Stack(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search + actions row
                Row(
                  children: [
                    // Search field - rounded, subtle shadow
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
                            hintText: 'Rechercher une découverte...',
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
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                          },
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Add (FAB-style small)
                    FloatingActionButton.small(
                      heroTag: 'fab_add_discovery',
                      onPressed: _toggleAddDiscoveryForm,
                      backgroundColor:
                          _isAddingDiscovery ? Colors.grey : primary,
                      child: Icon(
                        _isAddingDiscovery ? Icons.close : Icons.add,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Refresh
                    IconButton(
                      tooltip: 'Rafraîchir',
                      onPressed: _fetchDiscoveries,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Header / optional filters row (place for future)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: Text(
                    'Découvertes',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // List
                Expanded(
                  child:
                      _isLoading
                          ? ListView.builder(
                            itemCount: 4,
                            itemBuilder:
                                (context, index) => const Padding(
                                  padding: EdgeInsets.only(bottom: 12),
                                  child: LoaderDecouverte(),
                                ),
                          )
                          : _filteredDiscoveries.isEmpty
                          ? const Center(
                            child: Text('Aucune découverte trouvée'),
                          )
                          : ListView.separated(
                            itemCount: _filteredDiscoveries.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final discovery = _filteredDiscoveries[index];
                              final picto = discovery['picto'] as String?;
                              final title = discovery['titre'] ?? 'Sans titre';
                              final villeName = discovery['ville']?['nom'];
                              final categoryName =
                                  discovery['category']?['nom'];

                              return GestureDetector(
                                onTap: () {
                                  // Optionnel : ouvrir détails
                                },
                                child: Card(
                                  elevation: 6,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  child: Column(
                                    children: [
                                      // Image with gradient overlay & title
                                      Stack(
                                        children: [
                                          if (picto != null && picto.isNotEmpty)
                                            SizedBox(
                                              height: 200,
                                              width: double.infinity,
                                              child: Image.network(
                                                picto,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (_, __, ___) => Container(
                                                      color: Colors.grey[300],
                                                      child: const Center(
                                                        child: Icon(
                                                          Icons
                                                              .image_not_supported,
                                                          size: 50,
                                                        ),
                                                      ),
                                                    ),
                                              ),
                                            )
                                          else
                                            Container(
                                              height: 200,
                                              color: Colors.grey[200],
                                              child: const Center(
                                                child: Icon(
                                                  Icons.image,
                                                  size: 50,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),

                                          // gradient for legibility
                                          Container(
                                            height: 200,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.bottomCenter,
                                                end: Alignment.topCenter,
                                                colors: [
                                                  Colors.black.withOpacity(
                                                    0.55,
                                                  ),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                          ),

                                          // Title bottom-left
                                          Positioned(
                                            left: 16,
                                            bottom: 16,
                                            child: Text(
                                              title,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                shadows: [
                                                  Shadow(
                                                    blurRadius: 6,
                                                    color: Colors.black26,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),

                                          // Action buttons top-right
                                          Positioned(
                                            top: 12,
                                            right: 12,
                                            child: Row(
                                              children: [
                                                _smallCircleIconButton(
                                                  icon: Icons.edit,
                                                  onPressed:
                                                      () =>
                                                          _showEditDiscoveryForm(
                                                            discovery,
                                                          ),
                                                  bgColor: Colors.black26,
                                                  iconColor: Colors.white,
                                                ),
                                                const SizedBox(width: 8),
                                                _smallCircleIconButton(
                                                  icon: Icons.delete,
                                                  onPressed:
                                                      () =>
                                                          _showDeleteConfirmation(
                                                            discovery,
                                                          ),
                                                  bgColor: Colors.black26,
                                                  iconColor: Colors.white,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Meta + description excerpt
                                      Padding(
                                        padding: const EdgeInsets.all(14.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                if (villeName != null) ...[
                                                  const Icon(
                                                    Icons.location_on,
                                                    size: 16,
                                                    color: Colors.grey,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    villeName,
                                                    style: TextStyle(
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                ],
                                                if (categoryName != null) ...[
                                                  Icon(
                                                    CategoryIconMapper.getIconForCategory(
                                                      categoryName,
                                                    ),
                                                    size: 16,
                                                    color: Colors.grey,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    categoryName,
                                                    style: TextStyle(
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              discovery['description'] ??
                                                  'Pas de description',
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
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

          // Overlay + blurred background when form open
          if (_isAddingDiscovery || _isEditingDiscovery) ...[
            // Backdrop blur + dim
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  _cancelForm();
                },
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(color: Colors.black.withOpacity(0.25)),
                ),
              ),
            ),

            // Slide-up modern bottom form
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.78,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.background,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
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
                                    _isEditingDiscovery
                                        ? 'Modifier la découverte'
                                        : 'Ajouter une découverte',
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

                              // Title
                              TextFormField(
                                controller: _titleController,
                                decoration: InputDecoration(
                                  labelText: 'Titre',
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                validator:
                                    (v) =>
                                        (v == null || v.isEmpty)
                                            ? 'Veuillez entrer un titre'
                                            : null,
                              ),
                              const SizedBox(height: 12),

                              // Description
                              TextFormField(
                                controller: _descriptionController,
                                decoration: InputDecoration(
                                  labelText: 'Description',
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

                              // City & Category dropdowns (kept behavior)
                              DropdownButtonFormField<int>(
                                decoration: InputDecoration(
                                  labelText: 'Ville',
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
                                onChanged:
                                    (v) => setState(() => _selectedCityId = v),
                                validator:
                                    (v) =>
                                        v == null
                                            ? 'Veuillez sélectionner une ville'
                                            : null,
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<int>(
                                decoration: InputDecoration(
                                  labelText: 'Catégorie',
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
                                onChanged:
                                    (v) =>
                                        setState(() => _selectedCategoryId = v),
                                validator:
                                    (v) =>
                                        v == null
                                            ? 'Veuillez sélectionner une catégorie'
                                            : null,
                              ),

                              const SizedBox(height: 12),

                              // AnnonceSearchField preserved
                              AnnonceSearchField(
                                ville: _selectedCityId ?? -1,
                                category: _selectedCategoryId ?? -1,
                                controller: _annonceController,
                                onSelected: (id, title) {
                                  _annonceController.text = title;
                                  setState(() => _selectedAnnonceId = id);
                                },
                              ),

                              const SizedBox(height: 12),

                              // Current image preview when editing
                              if (_isEditingDiscovery &&
                                  _editingDiscoveryId != null) ...[
                                const Text('Image actuelle:'),
                                const SizedBox(height: 8),
                                Container(
                                  height: 100,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child:
                                      _discoveries.firstWhere(
                                                (d) =>
                                                    d['id'] ==
                                                    _editingDiscoveryId,
                                                orElse: () => {'picto': ''},
                                              )['picto'] !=
                                              null
                                          ? Image.network(
                                            _discoveries.firstWhere(
                                              (d) =>
                                                  d['id'] ==
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
                                            child: Text("Pas d'image"),
                                          ),
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Pick image area
                              InkWell(
                                onTap: _pickImage,
                                child: Container(
                                  height: 150,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  child:
                                      _selectedImage != null
                                          ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Image.file(
                                              _selectedImage!,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                          : Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add_photo_alternate,
                                                size: 46,
                                                color: Colors.grey[500],
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

                              const SizedBox(height: 18),

                              // Actions
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
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                        if (!_isEditingDiscovery &&
                                            _selectedImage == null) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Veuillez sélectionner une image.",
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        if (_isEditingDiscovery &&
                                            _editingDiscoveryId != null) {
                                          _updateDiscovery(
                                            _editingDiscoveryId!,
                                          );
                                        } else {
                                          _addDiscovery();
                                        }
                                        FocusScope.of(context).unfocus();
                                        _cancelForm();
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Veuillez corriger les erreurs.',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primary,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      _isEditingDiscovery
                                          ? 'Enregistrer'
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

  // Helper - small circular icon button
  Widget _smallCircleIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color bgColor = Colors.black12,
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
}
