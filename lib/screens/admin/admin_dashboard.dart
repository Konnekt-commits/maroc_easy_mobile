import 'package:flutter/material.dart';
import 'package:maroc_easy/screens/admin/manage_cities.dart';
import 'package:maroc_easy/screens/admin/manage_discoveries.dart';
import 'package:maroc_easy/screens/admin/manage_properties.dart';
import 'package:maroc_easy/screens/admin/manage_reviews.dart';
import 'package:maroc_easy/screens/admin/manage_categories.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ManageCities(),
    const ManageDiscoveries(),
    const ManageProperties(),
    // const ManageReviews(),
    const ManageCategories(),
  ];

  final List<String> _titles = [
    'Gestion des villes',
    'Gestion des découvertes',
    'Gestion des annonces',
    // 'Gestion des avis',
    'Gestion des catégories',
  ];

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
                onPressed: () {
                  // Implement logout functionality
                  Navigator.pop(context);
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
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _showDeconnexionConfirmation,
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: _screens[_selectedIndex],
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
            icon: Icon(Icons.location_city),
            label: 'Villes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Découvertes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign),
            label: 'Annonces',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Catégories',
          ),
        ],
      ),
    );
  }
}
