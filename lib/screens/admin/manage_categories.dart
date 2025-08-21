import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maroceasy/widgets/categoryIconMapper.dart';
import 'package:maroceasy/widgets/loader.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManageCategories extends StatefulWidget {
  const ManageCategories({Key? key}) : super(key: key);

  @override
  State<ManageCategories> createState() => _ManageCategoriesState();
}

class _ManageCategoriesState extends State<ManageCategories> {
  List<dynamic> _categories = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
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
        Uri.parse('https://maroceasy.konnekt.fr/api/categories'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _categories = data['hydra:member'];
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load categories');
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

  Future<void> _deleteCategory(int categoryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.delete(
        Uri.parse('https://maroceasy.konnekt.fr/api/categories/$categoryId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 204) {
        // Successfully deleted
        _fetchCategories();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Catégorie supprimée avec succès')),
        );
      } else {
        throw Exception('Failed to delete category');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  List<dynamic> get _filteredCategories {
    if (_searchQuery.isEmpty) {
      return _categories;
    }

    return _categories.where((category) {
      final name = category['nom']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();

      return name.contains(query);
    }).toList();
  }

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search and add category row
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Rechercher une catégorie...',
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
                onPressed: () {
                  _showAddCategoryDialog();
                },
                icon: const Icon(Icons.add, color: Colors.white),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _fetchCategories,
                tooltip: 'Rafraîchir',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Categories list
          Expanded(
            child:
                _isLoading
                    ? Center(
                      child: ListView.builder(
                        itemCount: 10,
                        itemBuilder: (context, index) => LoaderCategorieAdmin(),
                      ),
                    )
                    : _filteredCategories.isEmpty
                    ? const Center(child: Text('Aucune catégorie trouvée'))
                    : SingleChildScrollView(
                      child: Wrap(
                        alignment: WrapAlignment.start,
                        spacing: 8,
                        runSpacing: 8,
                        direction: Axis.horizontal,
                        children: List.generate(_categories.length, (index) {
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  if (_categories[index]['icone'] != null)
                                    Image.network(
                                      _categories[index]['icone'],
                                      width: 40,
                                      height: 40,
                                      errorBuilder:
                                          (_, __, ___) => const Icon(
                                            Icons.category,
                                            size: 40,
                                          ),
                                    )
                                  else
                                    Icon(
                                      CategoryIconMapper.getIconForCategory(
                                        _categories[index]['nom'],
                                      ),
                                      size: 40,
                                    ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      _categories[index]['nom'] ?? 'Sans nom',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () {
                                      _showEditCategoryDialog(
                                        _categories[index],
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
                                        _categories[index],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _iconController = TextEditingController();
  String? _selectedCategoryName;
  final List<String> _availableCategories =
      CategoryIconMapper.availableCategories;

  @override
  void dispose() {
    _nameController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  void _showAddCategoryDialog() {
    _nameController.clear();
    _iconController.clear();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Ajouter une catégorie'),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedCategoryName,
                    decoration: const InputDecoration(
                      labelText: 'Nom de la catégorie',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        _availableCategories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Row(
                              children: [
                                Icon(
                                  CategoryIconMapper.getIconForCategory(
                                    category,
                                  ),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(category, style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryName = value!;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return "Veuillez sélectionner une catégorie";
                      }
                      return null; // ✅ pas d'erreur
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Annuler',
                  style: TextStyle(color: Colors.pink),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // ✅ Vérification supplémentaire pour l'image si on ajoute
                    Navigator.pop(context);
                    _addCategory();
                  } else {
                    // ❌ au moins un champ est vide → erreur affichée en rouge
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Veuillez corriger les erreurs.'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                child: const Text(
                  'Ajouter',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _showEditCategoryDialog(Map<String, dynamic> category) {
    _selectedCategoryName = (category['nom'] as String).toLowerCase();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Modifier la catégorie'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedCategoryName,
                  decoration: const InputDecoration(
                    labelText: 'Nom de la catégorie',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      _availableCategories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Row(
                            children: [
                              Icon(
                                CategoryIconMapper.getIconForCategory(category),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(category, style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryName = value!;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Annuler',
                  style: TextStyle(color: Colors.pink),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _updateCategory(category['id']);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                child: const Text(
                  'Enregistrer',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> category) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmer la suppression'),
            content: Text(
              'Êtes-vous sûr de vouloir supprimer la catégorie "${category['nom']}" ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteCategory(category['id']);
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

  Future<void> _addCategory() async {
    if (_selectedCategoryName == null || _selectedCategoryName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom de la catégorie est requis')),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final Map<String, dynamic> categoryData = {'nom': _selectedCategoryName};

      final response = await http.post(
        Uri.parse('https://maroceasy.konnekt.fr/api/categories'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(categoryData),
      );

      if (response.statusCode == 201) {
        _fetchCategories();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Catégorie ajoutée avec succès')),
        );
      } else {
        throw Exception('Failed to add category: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _updateCategory(int categoryId) async {
    if (_selectedCategoryName == null || _selectedCategoryName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom de la catégorie est requis')),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final Map<String, dynamic> categoryData = {'nom': _selectedCategoryName};

      final response = await http.patch(
        Uri.parse('https://maroceasy.konnekt.fr/api/categories/$categoryId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/merge-patch+json',
        },
        body: json.encode(categoryData),
      );

      if (response.statusCode == 200) {
        _fetchCategories();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Catégorie modifiée avec succès')),
        );
      } else {
        throw Exception('Failed to update category: ${response.body}');
      }
    } catch (e) {
      print('Error updating category: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
