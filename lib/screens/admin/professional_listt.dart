import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ManageProfessionals extends StatefulWidget {
  const ManageProfessionals({Key? key}) : super(key: key);

  @override
  State<ManageProfessionals> createState() => _ManageProfessionalsState();
}

class _ManageProfessionalsState extends State<ManageProfessionals> {
  List<dynamic> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _isAddingUser = false;
  bool _isEditingUser = false;
  int? _editingUserId;
  double _formHeight = 0;

  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers({int page = 1}) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) throw Exception("Not authenticated");

      final response = await http.get(
        Uri.parse(
          "https://maroceasy.konnekt.fr/api/users?page=$page&roles=ROLE_PROFESSIONAL",
        ),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _users = data['hydra:member'];
          _isLoading = false;
        });
      } else {
        throw Exception("Failed to load users");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erreur: $e")));
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  Future<void> _addUser() async {
    try {
      if (_lastNameController.text.isEmpty ||
          _firstNameController.text.isEmpty ||
          _usernameController.text.isEmpty ||
          _emailController.text.isEmpty ||
          _passwordController.text.isEmpty) {
        throw Exception("Tous les champs sont obligatoires");
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception("Not authenticated");

      var request = http.MultipartRequest(
        'POST',
        Uri.parse("https://maroceasy.konnekt.fr/api/users"),
      );

      request.headers['Authorization'] = "Bearer $token";
      request.headers['accept'] = "application/ld+json";

      request.fields['nom'] = _lastNameController.text;
      request.fields['prenom'] = _firstNameController.text;
      request.fields['pseudoName'] = _usernameController.text;
      request.fields['email'] = _emailController.text;
      request.fields['password'] = _passwordController.text;
      request.fields['roles'] = "ROLE_PROFESSIONAL";

      if (_profileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'pictoFile',
            _profileImage!.path,
            filename: "profile_${DateTime.now().millisecondsSinceEpoch}.png",
          ),
        );
      }

      var response = await request.send();
      var responseData = await http.Response.fromStream(response);

      if (responseData.statusCode == 201) {
        _fetchUsers();
        _cancelForm();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Utilisateur ajouté")));
      } else {
        print("Erreur: ${responseData.statusCode} - ${responseData.body}");
        throw Exception("Erreur: ${responseData.body}");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur: $e")));
    }
  }

  Future<void> _updateUser(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception("Not authenticated");

      var request = http.MultipartRequest(
        'PATCH',
        Uri.parse("https://maroceasy.konnekt.fr/api/users/$userId"),
      );

      request.headers['Authorization'] = "Bearer $token";
      request.headers['accept'] = "application/ld+json";

      request.fields['nom'] = _lastNameController.text;
      request.fields['prenom'] = _firstNameController.text;
      request.fields['pseudoName'] = _usernameController.text;
      request.fields['email'] = _emailController.text;
      if (_passwordController.text.isNotEmpty) {
        request.fields['password'] = _passwordController.text;
      }

      if (_profileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'pictoFile',
            _profileImage!.path,
            filename: "profile_${DateTime.now().millisecondsSinceEpoch}.png",
          ),
        );
      }

      var response = await request.send();
      var responseData = await http.Response.fromStream(response);

      if (responseData.statusCode == 200) {
        _fetchUsers();
        _cancelForm();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Utilisateur modifié")));
      } else {
        throw Exception("Erreur: ${responseData.body}");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur: $e")));
    }
  }

  Future<void> _deleteUser(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception("Not authenticated");

      final response = await http.delete(
        Uri.parse("https://maroceasy.konnekt.fr/api/users/$userId"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 204) {
        _fetchUsers();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Utilisateur supprimé")));
      } else {
        throw Exception("Failed to delete: ${response.body}");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur: $e")));
    }
  }

  List<dynamic> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((user) {
      final name = (user['nom'] ?? "").toString().toLowerCase();
      final prenom = (user['prenom'] ?? "").toString().toLowerCase();
      final email = (user['email'] ?? "").toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) ||
          prenom.contains(query) ||
          email.contains(query);
    }).toList();
  }

  void _toggleAddUserForm() {
    setState(() {
      _isAddingUser = !_isAddingUser;
      _isEditingUser = false;
      _editingUserId = null;
      _formHeight = _isAddingUser ? 600 : 0;

      if (_isAddingUser) {
        _lastNameController.clear();
        _firstNameController.clear();
        _usernameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _profileImage = null;
      }
    });
  }

  void _showEditUserForm(Map<String, dynamic> user) {
    setState(() {
      _isEditingUser = true;
      _isAddingUser = false;
      _editingUserId = user['id'];
      _formHeight = 600;

      _lastNameController.text = user['nom'] ?? "";
      _firstNameController.text = user['prenom'] ?? "";
      _usernameController.text = user['pseudoName'] ?? "";
      _emailController.text = user['email'] ?? "";
      _passwordController.clear();
      _profileImage = null;
    });
  }

  void _cancelForm() {
    setState(() {
      _isAddingUser = false;
      _isEditingUser = false;
      _editingUserId = null;
      _formHeight = 0;
    });
  }

  void _showDeleteConfirmation(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Supprimer l'utilisateur"),
            content: Text(
              "Voulez-vous supprimer ${user['prenom']} ${user['nom']} ?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Annuler",
                  style: TextStyle(color: Colors.pink),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteUser(user['id']);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                child: const Text(
                  "Supprimer",
                  style: TextStyle(color: Colors.white),
                ),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: "Rechercher un utilisateur...",
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: Icon(
                      _isAddingUser ? Icons.close : Icons.add,
                      color: Colors.white,
                    ),
                    onPressed: _toggleAddUserForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isAddingUser ? Colors.grey : Colors.pink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredUsers.isEmpty
                        ? const Center(child: Text("Aucun utilisateur trouvé"))
                        : ListView.builder(
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            return buildUserCard(user);
                          },
                        ),
              ),
            ],
          ),
        ),
        if (_isAddingUser || _isEditingUser)
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
            child: SingleChildScrollView(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Text(
                          _isEditingUser
                              ? "Modifier un utilisateur"
                              : "Ajouter un utilisateur",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(
                            labelText: "Nom",
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v!.isEmpty ? "Champ requis" : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(
                            labelText: "Prénom",
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v!.isEmpty ? "Champ requis" : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: "Pseudo",
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v!.isEmpty ? "Champ requis" : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: "Email",
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v!.isEmpty ? "Champ requis" : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: "Mot de passe",
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 16),
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
                                _profileImage != null
                                    ? Image.file(
                                      _profileImage!,
                                      fit: BoxFit.cover,
                                    )
                                    : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Icon(
                                          Icons.add_a_photo,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                        Text("Choisir une photo"),
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
                                "Annuler",
                                style: TextStyle(color: Colors.pink),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  if (_isEditingUser &&
                                      _editingUserId != null) {
                                    _updateUser(_editingUserId!);
                                  } else {
                                    _addUser();
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pink,
                              ),
                              child: Text(
                                _isEditingUser ? "Enregistrer" : "Ajouter",
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

  Widget buildUserCard(Map<String, dynamic> user) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Avatar
            user['picto'] != null
                ? CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(user['picto']),
                )
                : const CircleAvatar(radius: 24, child: Icon(Icons.person)),

            const SizedBox(width: 12),

            // Infos utilisateur
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${user['prenom'] ?? ''} ${user['nom'] ?? ''}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user['email'] ?? "",
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showEditUserForm(user),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _showDeleteConfirmation(user),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
