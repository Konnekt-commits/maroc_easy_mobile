import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:maroceasy/screens/professional/professional_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maroceasy/screens/home_page.dart';
import 'package:maroceasy/screens/login_page.dart';
import 'package:maroceasy/screens/admin/admin_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  DateTime? dateExpiration;

  Future<void> decodeJWT(String token) async {
    // Le JWT est divisé en trois parties : header, payload, et signature
    List<String> parts = token.split('.');

    if (parts.length != 3) {
      print("Token invalide");
      return;
    }

    // Décoder la deuxième partie (Payload)
    String payload = parts[1];
    String decodedPayload = utf8.decode(
      base64Url.decode(base64Url.normalize(payload)),
    );

    // Convertir en JSON
    var jsonPayload = jsonDecode(decodedPayload);
    setState(() {
      dateExpiration = DateTime.fromMillisecondsSinceEpoch(
        jsonPayload['exp'] * 1000,
      );
    });

    // Afficher le timestamp de création (iat) et d'expiration (exp)
    print(
      "Date de création (iat): ${DateTime.fromMillisecondsSinceEpoch(jsonPayload['iat'] * 1000)}",
    );
    print(
      "Date d'expiration (exp): ${DateTime.fromMillisecondsSinceEpoch(jsonPayload['exp'] * 1000)}",
    );
  }

  Future<void> _checkAuthStatus() async {
    // Simulate loading time
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      // Verify token validity by making a test API call
      await decodeJWT(token);

      // User is logged in with valid token, check role
      final userDataString = prefs.getString('userData');

      if (userDataString != null) {
        try {
          final userData = jsonDecode(userDataString);
          final roles = List<String>.from(userData['roles'] ?? []);
          if (dateExpiration != null) {
            // Vérifier si le token est expiré
            if (DateTime.now().isAfter(dateExpiration!)) {
              // Token expiré, rediriger vers la page de connexion
              print("Token expiré, redirection vers login");
              await prefs.remove('token'); // Supprimer le token expiré
              await prefs.remove(
                'userData',
              ); // Supprimer les données utilisateur

              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }
              return; // Important: arrêter l'exécution ici
            }
            print("État du token: ${DateTime.now().isAfter(dateExpiration!)}");
          }

          if (roles.contains('ROLE_ADMIN')) {
            // Navigate to admin dashboard
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const AdminDashboard()),
            );
          } else if (roles.contains('ROLE_PROFESSIONAL')) {
            // Navigate to professional dashboard
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const ProfessionalDashboard(),
              ),
            );
          } else {
            // Navigate to regular user home page
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          }
        } catch (e) {
          // Error parsing user data, redirect to login
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      } else {
        // No user data found, redirect to login
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } else {
      // No token found, user is not logged in
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo or app name
            Text(
              'MarocEasy',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
            ),
            const SizedBox(height: 24),
            // Loading indicator
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
            ),
          ],
        ),
      ),
    );
  }
}
