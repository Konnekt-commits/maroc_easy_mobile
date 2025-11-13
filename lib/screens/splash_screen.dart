import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  DateTime? dateExpiration;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // ✅ Animation douce Splash
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _checkAuthStatus();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> decodeJWT(String token) async {
    List<String> parts = token.split('.');
    if (parts.length != 3) return;

    String payload = parts[1];
    String decodedPayload = utf8.decode(
      base64Url.decode(base64Url.normalize(payload)),
    );

    var jsonPayload = jsonDecode(decodedPayload);
    setState(() {
      dateExpiration = DateTime.fromMillisecondsSinceEpoch(
        jsonPayload['exp'] * 1000,
      );
    });
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      await decodeJWT(token);

      final userDataString = prefs.getString('userData');

      if (userDataString != null) {
        try {
          final userData = jsonDecode(userDataString);
          final roles = List<String>.from(userData['roles'] ?? []);

          // ✅ Token expiré → logout automatique
          if (dateExpiration != null &&
              DateTime.now().isAfter(dateExpiration!)) {
            await prefs.remove('token');
            await prefs.remove('userData');

            if (!mounted) return;
            Navigator.pushReplacementNamed(context, '/login');
            return;
          }

          if (roles.contains('ROLE_ADMIN')) {
            if (!mounted) return;
            Navigator.pushReplacementNamed(context, '/admin');
          } else if (roles.contains('ROLE_PROFESSIONAL')) {
            if (!mounted) return;
            Navigator.pushReplacementNamed(context, '/professional');
          } else {
            if (!mounted) return;
            Navigator.pushReplacementNamed(context, '/home');
          }
          return;
        } catch (_) {}
      }
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              "assets/images/fond_portrait.jpg",
              fit: BoxFit.cover,
            ),
          ),

          // Gradient layer
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),
          ),

          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'MarocEasy',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Color(0xFFF2A900)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
