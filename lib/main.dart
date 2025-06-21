import 'package:flutter/material.dart';
import 'package:maroc_easy/screens/splash_screen.dart';
import 'package:maroc_easy/screens/login_page.dart';
import 'package:maroc_easy/screens/register_page.dart';
import 'package:maroc_easy/screens/home_page.dart';
import 'package:maroc_easy/screens/admin/admin_dashboard.dart';
import 'package:maroc_easy/screens/professional/professional_dashboard.dart';

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
