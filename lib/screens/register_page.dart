import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maroceasy/widgets/cropperImage.dart';
import 'package:maroceasy/widgets/imageOption.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  String _selectedRole = 'client';
  File? _profileImage;
  double _passwordStrength = 0.0;
  String _passwordStrengthText = 'Faible';
  Color _passwordStrengthColor = Colors.red;

  String getFormattedTimestamp() {
    return DateTime.now()
        .toIso8601String()
        .replaceAll('-', '_')
        .replaceAll(':', '_')
        .replaceFirst('.', '_');
  }

  Future<void> _selectAndUploadImage(BuildContext context, int type) async {
    final picker = ImagePicker();

    final pickedFile = await picker.pickImage(
      source: type == 1 ? ImageSource.gallery : ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      compressQuality: 90,
      maxWidth: 1080,
      maxHeight: 1080,
      compressFormat: ImageCompressFormat.jpg,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          cropStyle: CropStyle.circle,
          toolbarTitle: 'Recadrage Photo',
          toolbarColor: Colors.pink,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: true,
          activeControlsWidgetColor: Colors.pink,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          cropStyle: CropStyle.circle,
          title: 'Recadrer',
          aspectRatioLockEnabled: true,
          doneButtonTitle: 'OK',
          cancelButtonTitle: 'Annuler',
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _profileImage = File(croppedFile.path);
      });
    }
  }

  void _showImageSourceSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Choisir une photo",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ImageOption(
                    icon: Icons.photo_library_outlined,
                    label: "Galerie",
                    onTap: () {
                      Navigator.pop(context);
                      _selectAndUploadImage(context, 1);
                    },
                  ),
                  ImageOption(
                    icon: Icons.camera_alt_outlined,
                    label: "Caméra",
                    onTap: () {
                      Navigator.pop(context);
                      _selectAndUploadImage(context, 2);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _checkPasswordStrength(String password) {
    // Reset strength
    double strength = 0;
    String displayText = 'Faible';
    Color strengthColor = Colors.red;

    if (password.isEmpty) {
      setState(() {
        _passwordStrength = 0;
        _passwordStrengthText = 'Faible';
        _passwordStrengthColor = Colors.red;
      });
      return;
    }

    // Add points for length
    if (password.length >= 8) strength += 0.25;
    if (password.length >= 12) strength += 0.15;

    // Add points for complexity
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.15;
    if (password.contains(RegExp(r'[a-z]'))) strength += 0.15;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.15;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.15;

    // Determine text and color based on strength
    if (strength > 0.7) {
      displayText = 'Fort';
      strengthColor = Colors.green;
    } else if (strength > 0.4) {
      displayText = 'Moyen';
      strengthColor = Colors.orange;
    }

    setState(() {
      _passwordStrength = strength;
      _passwordStrengthText = displayText;
      _passwordStrengthColor = strengthColor;
    });
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez accepter les conditions d\'utilisation'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_profileImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez ajouter une photo de profil'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create multipart request for profile image
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://maroceasy.konnekt.fr/api/users'),
      );

      // Add text fields
      request.fields['nom'] = _lastNameController.text;
      request.fields['prenom'] = _firstNameController.text;
      request.fields['pseudoName'] = _usernameController.text;
      request.fields['email'] = _emailController.text;
      request.fields['password'] = _passwordController.text;
      request.fields['roles'] = _selectedRole;

      // Add profile image
      request.files.add(
        await http.MultipartFile.fromPath(
          'pictoFile',
          _profileImage!.path,
          filename: "profile${getFormattedTimestamp()}.png",
        ),
      );

      // Send request
      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        // Registration successful
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Inscription réussie! Veuillez vous connecter.'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to login page
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (context) => LoginPage()));
      } else {
        // Show error message
        final errorData = jsonDecode(responseData);
        String errorMessage = 'Erreur lors de l\'inscription';

        if (errorData['violations'] != null) {
          errorMessage = errorData['violations'][0]['message'];
        }
        print(responseData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de connexion: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Créer un compte',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Profile Image
                  Center(
                    child: GestureDetector(
                      onTap: () => _showImageSourceSelector(context),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[200],
                            backgroundImage:
                                _profileImage != null
                                    ? FileImage(_profileImage!)
                                    : null,
                            child:
                                _profileImage == null
                                    ? Icon(
                                      Icons.person,
                                      size: 60,
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
                  const SizedBox(height: 20),

                  // First Name Field
                  TextFormField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: 'Prénom',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre prénom';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Last Name Field
                  TextFormField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: 'Nom',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre nom';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Username Field
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Pseudo',
                      prefixIcon: Icon(Icons.alternate_email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un pseudo';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre email';
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return 'Veuillez entrer un email valide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Role Selection
                  Text(
                    'Choisissez votre rôle:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedRole = 'ROLE_USER';
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color:
                                  _selectedRole == 'ROLE_USER'
                                      ? Colors.pink.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    _selectedRole == 'ROLE_USER'
                                        ? Colors.pink
                                        : Colors.grey.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.person,
                                  color:
                                      _selectedRole == 'ROLE_USER'
                                          ? Colors.pink
                                          : Colors.grey,
                                  size: 28,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Client',
                                  style: TextStyle(
                                    color:
                                        _selectedRole == 'ROLE_USER'
                                            ? Colors.pink
                                            : Colors.black87,
                                    fontWeight:
                                        _selectedRole == 'ROLE_USER'
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedRole = 'ROLE_PROFESSIONAL';
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color:
                                  _selectedRole == 'ROLE_PROFESSIONAL'
                                      ? Colors.pink.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    _selectedRole == 'ROLE_PROFESSIONAL'
                                        ? Colors.pink
                                        : Colors.grey.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.business_center,
                                  color:
                                      _selectedRole == 'ROLE_PROFESSIONAL'
                                          ? Colors.pink
                                          : Colors.grey,
                                  size: 28,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Professionnel',
                                  style: TextStyle(
                                    color:
                                        _selectedRole == 'ROLE_PROFESSIONAL'
                                            ? Colors.pink
                                            : Colors.black87,
                                    fontWeight:
                                        _selectedRole == 'ROLE_PROFESSIONAL'
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: _checkPasswordStrength,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un mot de passe';
                      }
                      if (value.length < 6) {
                        return 'Le mot de passe doit contenir au moins 6 caractères';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Password Strength Indicator
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Force du mot de passe: $_passwordStrengthText',
                        style: TextStyle(
                          color: _passwordStrengthColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: _passwordStrength,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _passwordStrengthColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password Field
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirmer le mot de passe',
                      prefixIcon: Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez confirmer votre mot de passe';
                      }
                      if (value != _passwordController.text) {
                        return 'Les mots de passe ne correspondent pas';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Terms and Conditions
                  Row(
                    children: [
                      Checkbox(
                        value: _acceptTerms,
                        onChanged: (value) {
                          setState(() {
                            _acceptTerms = value ?? false;
                          });
                        },
                        activeColor: Colors.pink,
                      ),
                      Expanded(
                        child: Text(
                          'J\'accepte les conditions d\'utilisation et la politique de confidentialité',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Register Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                              'S\'inscrire',
                              style: TextStyle(fontSize: 16),
                            ),
                  ),
                  const SizedBox(height: 24),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Vous avez déjà un compte?'),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoginPage(),
                            ),
                          );
                        },
                        child: Text(
                          'Se connecter',
                          style: TextStyle(color: Colors.pink),
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
    );
  }

  Widget _socialLoginButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }
}
