import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart'; // Added import for MediaType
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  Map<String, dynamic> _userData = {};
  File? _newProfileImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('userData');

      if (userDataString == null || userDataString.isEmpty) {
        // No user data found, navigate to login
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (context) => LoginPage()));
        return;
      }

      // Parse user data from SharedPreferences
      final userData = jsonDecode(userDataString);

      setState(() {
        _userData = userData;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de chargement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _newProfileImage = File(image.path);
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userData');
  }

  void _editProfile() {
    final parentContext = context;

    final TextEditingController _nomController = TextEditingController(
      text: _userData['nom'],
    );
    final TextEditingController _prenomController = TextEditingController(
      text: _userData['prenom'],
    );
    final TextEditingController _emailController = TextEditingController(
      text: _userData['email'],
    );

    File? tempProfileImage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Modifier le profil',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),

                  // Image picker
                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (image != null) {
                          setModalState(() {
                            tempProfileImage = File(image.path);
                          });
                        }
                      },
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[200],
                            backgroundImage:
                                tempProfileImage != null
                                    ? FileImage(tempProfileImage!)
                                    : (_userData['picto'] != null
                                            ? NetworkImage(_userData['picto'])
                                            : null)
                                        as ImageProvider?,
                            child:
                                (tempProfileImage == null &&
                                        _userData['picto'] == null)
                                    ? Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.grey[400],
                                    )
                                    : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.pink,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  TextField(
                    controller: _prenomController,
                    decoration: InputDecoration(
                      labelText: 'Prénom',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),

                  TextField(
                    controller: _nomController,
                    decoration: InputDecoration(
                      labelText: 'Nom',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),

                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);

                        setState(() {
                          _isLoading = true;
                        });

                        try {
                          final prefs = await SharedPreferences.getInstance();
                          final token = prefs.getString('token') ?? '';

                          final userId =
                              _userData['id']; // Assure-toi que cet ID est bien présent
                          final uri = Uri.parse(
                            'https://maroceasy.konnekt.fr/api/users-update/$userId',
                          );
                          final picto =
                              "profile_${DateTime.now().millisecondsSinceEpoch}.jpg";

                          final request =
                              http.MultipartRequest('POST', uri)
                                ..headers['Authorization'] = 'Bearer $token'
                                ..fields['nom'] = _nomController.text
                                ..fields['prenom'] = _prenomController.text
                                ..fields['email'] = _emailController.text
                                ..fields['roles'] = ''
                                ..fields['password'] = ''
                                ..fields['pseudoName'] = '';

                          if (tempProfileImage != null) {
                            request.files.add(
                              await http.MultipartFile.fromPath(
                                'pictoFile',
                                tempProfileImage!.path,
                                filename: picto,
                                contentType: MediaType(
                                  'image',
                                  'jpeg',
                                ), // Si nécessaire
                              ),
                            );
                          }

                          final response = await request.send();
                          final responseString =
                              await response.stream.bytesToString();

                          if (response.statusCode == 200 ||
                              response.statusCode == 201) {
                            final json = jsonDecode(responseString);
                            print("object: $json");

                            _userData['nom'] = _nomController.text;
                            _userData['prenom'] = _prenomController.text;
                            _userData['email'] = _emailController.text;
                            if (json['user']['picto'] != null) {
                              _userData['picto'] = json['user']['picto'];
                            }

                            await prefs.setString(
                              'userData',
                              jsonEncode(_userData),
                            );

                            if (mounted) {
                              setState(() {});
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Profil mis à jour avec succès',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Erreur ${response.statusCode} lors de la mise à jour du profil',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          print('Erreur: $e');
                          if (mounted) {
                            ScaffoldMessenger.of(parentContext).showSnackBar(
                              SnackBar(
                                content: Text('Erreur: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Enregistrer'),
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Show confirmation dialog before deconnexion
  void _showDeconnexionConfirmation() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Déconnexion'),
            content: Text('Voulez-vous vraiment vous déconnecter?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Non', style: TextStyle(color: Colors.pink)),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Implement logout functionality
                  Navigator.pop(context);

                  await _logout();
                  Navigator.pushReplacementNamed(context, '/login');
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                    Colors.pink,
                  ),
                ),
                child: const Text('Oui', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mon Profil'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.pink),
            onPressed: _showDeconnexionConfirmation,
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator(color: Colors.pink))
              : SingleChildScrollView(
                child: Center(
                  child: Card(
                    surfaceTintColor: Colors.white,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),

                          // Profile Image
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.grey[200],
                                backgroundImage:
                                    _userData['picto'] != null
                                        ? NetworkImage(_userData['picto'])
                                        : null,
                                child:
                                    _userData['picto'] == null
                                        ? Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Colors.grey[400],
                                        )
                                        : null,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Pseudo Name
                          Text(
                            '@${_userData['pseudoName'] ?? ''}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                            ),
                          ),

                          // User Name
                          Text(
                            '${_userData['prenom'] ?? ''} ${_userData['nom'] ?? ''}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          // Email
                          Text(
                            _userData['email'] ?? '',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Role
                          if (_userData['roles'] != null)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.pink.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _userData['roles'][0] == 'ROLE_CLIENT' ||
                                        _userData['roles'][0] == 'client'
                                    ? 'Client'
                                    : 'Vendeur',
                                style: TextStyle(
                                  color: Colors.pink,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const SizedBox(height: 30),

                          // Edit Profile Button
                          ElevatedButton.icon(
                            onPressed: _editProfile,
                            icon: Icon(Icons.edit, color: Colors.white),
                            label: Text('Modifier le profil'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
    );
  }
}
