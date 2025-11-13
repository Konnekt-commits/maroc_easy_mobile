import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maroceasy/screens/splash_screen.dart';
import 'package:maroceasy/screens/login_page.dart';
import 'package:maroceasy/screens/register_page.dart';
import 'package:maroceasy/screens/home_page.dart';
import 'package:maroceasy/screens/admin/admin_dashboard.dart';
import 'package:maroceasy/screens/professional/professional_dashboard.dart';
import 'package:maroceasy/widgets/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeProvider.init(); // ✅ charge la valeur sauvegardée avant de lancer l’app
  runApp(const MyApp());
}

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFFC62828), // Rouge Maroc
    secondary: Color(0xFF006837), // Vert Maroc
    background: Color(0xFFF7F7F7),
    onSecondary: Color(0xFF121212),
    onTertiary: Color(0xFFE0E0E0),
    onTertiaryContainer: Color(0xFFF5F5F5),
  ),
  useMaterial3: true,
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF0D0D0D),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFE53935),
    secondary: Color(0xFF2E7D32),
    background: Color(0xFF121212),
    onSecondary: Color(0xFFF7F7F7),
    onTertiary: Color(0xFF424242),
    onTertiaryContainer: Color(0xFF505050),
  ),
  appBarTheme: const AppBarTheme(
    elevation: 0,
    backgroundColor: Colors.transparent,
  ),
  useMaterial3: true,
);

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeProvider.isDarkMode,
      builder: (context, isDark, _) {
        return MaterialApp(
          title: "MarocEasy",
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,

          // ✅ Routes inchangées (tu peux continuer à utiliser Navigator.pushNamed)
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
      },
    );
  }
}
