import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('rememberMe') ?? false;
      if (_rememberMe) {
        _emailController.text = prefs.getString('email') ?? "";
        _passwordController.text = prefs.getString('password') ?? "";
      }
    });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("https://maroceasy.konnekt.fr/auth"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _emailController.text,
          "password": _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final token = decoded["token"];
        final userData = decoded["user"];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString("userData", jsonEncode(userData));

        // Remember me
        if (_rememberMe) {
          prefs.setBool("rememberMe", true);
          prefs.setString("email", _emailController.text);
          prefs.setString("password", _passwordController.text);
        } else {
          prefs.remove("rememberMe");
          prefs.remove("email");
          prefs.remove("password");
        }

        // Redirect depending on role
        if (userData["roles"].contains("ROLE_ADMIN")) {
          Navigator.pushReplacementNamed(context, "/admin");
        } else if (userData["roles"].contains("ROLE_PROFESSIONAL")) {
          Navigator.pushReplacementNamed(context, "/professional");
        } else {
          Navigator.pushReplacementNamed(context, "/home");
        }
      } else {
        _showSnackbar("Identifiants incorrects.");
      }
    } catch (e) {
      _showSnackbar("Erreur : $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
          child: Column(
            children: [
              const SizedBox(height: 30),

              /// ✅ branding amélioré avec dégradé + nom
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    "MarocEasy",
                    style: TextStyle(
                      fontSize: 42,
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              Text(
                "Connexion",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _inputField(
                      controller: _emailController,
                      label: "Email",
                      icon: Icons.email,
                      validatorMsg: "Veuillez entrer un email valide",
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    /// mot de passe
                    _inputField(
                      controller: _passwordController,
                      label: "Mot de passe",
                      icon: Icons.lock,
                      isPassword: true,
                      obscurePassword: _obscurePassword,
                      togglePasswordVisibility: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                      validatorMsg: "Veuillez entrer votre mot de passe",
                    ),

                    const SizedBox(height: 10),

                    /// remember me + forgot password
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged:
                              (v) => setState(() => _rememberMe = v ?? false),
                          activeColor: theme.colorScheme.primary,
                        ),
                        const Text("Se souvenir de moi"),
                      ],
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        "Mot de passe oublié ?",
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    /// bouton login avec gradient
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child:
                            _isLoading
                                ? CircularProgressIndicator(
                                  color: theme.colorScheme.background,
                                )
                                : Text(
                                  "Se connecter",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.background,
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// lien vers register
              const Text("Vous n'avez pas de compte ?"),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, "/register"),
                child: Text(
                  "Créer un compte",
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ fonction champ input moderne
  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String validatorMsg,
    bool isPassword = false,
    bool obscurePassword = false,
    VoidCallback? togglePasswordVisibility,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscurePassword,
      keyboardType: keyboardType,
      validator: (v) => (v == null || v.isEmpty) ? validatorMsg : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon:
            isPassword
                ? IconButton(
                  onPressed: togglePasswordVisibility,
                  icon: Icon(
                    obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                )
                : null,
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
