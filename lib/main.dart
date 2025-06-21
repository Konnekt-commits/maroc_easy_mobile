import 'package:flutter/material.dart';
import 'package:maroceasy/screens/splash_screen.dart';
import 'package:maroceasy/screens/login_page.dart';
import 'package:maroceasy/screens/register_page.dart';
import 'package:maroceasy/screens/home_page.dart';
import 'package:maroceasy/screens/admin/admin_dashboard.dart';
import 'package:maroceasy/screens/professional/professional_dashboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MarocEasy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.pink,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Make sure you have a home property OR initialRoute, not both
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/admin': (context) => const AdminDashboard(),
        '/professional': (context) => const ProfessionalDashboard(),
      },
    );
  }
}
