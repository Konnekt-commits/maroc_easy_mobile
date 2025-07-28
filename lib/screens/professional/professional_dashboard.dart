import 'package:flutter/material.dart';
import 'package:maroceasy/screens/professional/manage_my_properties.dart';
import 'package:maroceasy/screens/profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfessionalDashboard extends StatefulWidget {
  const ProfessionalDashboard({super.key});

  @override
  State<ProfessionalDashboard> createState() => _ProfessionalDashboardState();
}

class _ProfessionalDashboardState extends State<ProfessionalDashboard> {
  // Inside _ProfessionalDashboardState class
  int _selectedIndex = 0;
  final List<Widget> _screens = [];

  @override
  void initState() {
    // Initialize screens
    _screens.addAll([
      ManageMyProperties(), // Main explore screen
      // FavoritesPage(), // You'll need to create this
      // AdminPage(), // You'll need to create this
      ProfilePage(), // We already created this
    ]);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex], // Display the selected screen
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.manage_accounts),
            label: 'Gérer mes annonces',
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.favorite_border),
          //   label: 'Favoris',
          // ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.admin_panel_settings_outlined),
          //   label: 'Administration',
          // ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String title, IconData icon, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? Colors.black : Colors.grey),
          const SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
