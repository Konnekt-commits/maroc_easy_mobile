import 'package:flutter/material.dart';
import 'package:maroc_easy/screens/professional/manage_my_properties.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfessionalDashboard extends StatefulWidget {
  const ProfessionalDashboard({Key? key}) : super(key: key);

  @override
  State<ProfessionalDashboard> createState() => _ProfessionalDashboardState();
}

class _ProfessionalDashboardState extends State<ProfessionalDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [const ManageMyProperties()];

  final List<String> _titles = ['Mes Propriétés'];
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
                  Navigator.of(context).pop();
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
      ),
      body: _screens[_selectedIndex],
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.pink),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Espace Professionnel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Gérez vos propriétés',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            ListTile(
              selectedColor: Colors.pink,
              leading: const Icon(Icons.home),
              title: const Text('Mes Propriétés'),
              selected: _selectedIndex == 0,
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Déconnexion',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                // Implement logout functionality
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('token');
                await prefs.remove('userData');

                if (mounted) {
                  _showDeconnexionConfirmation();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
