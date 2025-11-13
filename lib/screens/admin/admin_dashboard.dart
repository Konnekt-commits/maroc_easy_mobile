import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:maroceasy/screens/admin/manage_cities.dart';
import 'package:maroceasy/screens/admin/manage_discoveries.dart';
import 'package:maroceasy/screens/admin/manage_properties.dart';
import 'package:maroceasy/screens/admin/manage_reviews.dart';
import 'package:maroceasy/screens/admin/manage_categories.dart';
import 'package:maroceasy/screens/admin/professional_listt.dart';
import 'package:maroceasy/screens/login_page.dart';
import 'package:maroceasy/screens/profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    const ManageProfessionals(),
    const ManageCategories(),
  ];

  final List<String> _titles = [
    'Gestion des villes',
    'Gestion des découvertes',
    'Gestion des annonces',
    'Gestion des professionnels',
    'Gestion des catégories',
  ];
  dynamic _userData;

  final GlobalKey _avatarKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('userData');

      if (userDataString == null || userDataString.isEmpty) {
        // No user data found, navigate to login
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (context) => LoginPage()));
        return;
      }

      // Parse user data from SharedPreferences
      final userData = jsonDecode(userDataString);

      setState(() {
        _userData = userData;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de chargement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
                child: Text(
                  'Non',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // Implement logout functionality
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/login');
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                child: const Text('Oui', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  void _showProfileMenu() async {
    final RenderBox renderBox =
        _avatarKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    await showMenu(
      context: context,
      color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height + 8,
        offset.dx + size.width,
        0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      items: [
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline),
              const SizedBox(width: 8),
              const Text("Profil"),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text("Déconnexion"),
            ],
          ),
        ),
      ],
      elevation: 8,
    ).then((value) {
      if (value == 'logout') _showDeconnexionConfirmation();
      if (value == 'profile')
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => ProfilePage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.primaryContainer.withOpacity(0.9),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              key: _avatarKey,
              onTap: _showProfileMenu,
              child: Hero(
                tag: 'user_avatar',
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: colorScheme.surface.withOpacity(0.5),
                  // safe avatar URL (fallback if _userData is null or picto missing)
                  backgroundImage: NetworkImage(
                    (_userData != null &&
                            _userData['picto'] != null &&
                            _userData['picto'].toString().isNotEmpty)
                        ? _userData['picto'].toString()
                        : "https://i.pravatar.cc/150?img=47",
                  ),
                  // show a small icon while user data not yet loaded / no image
                  child:
                      (_userData == null || _userData['picto'] == null)
                          ? Icon(
                            Icons.person,
                            size: 18,
                            color: colorScheme.onSurfaceVariant,
                          )
                          : null,
                ),
              ),
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder:
            (child, animation) =>
                FadeTransition(opacity: animation, child: child),
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface.withOpacity(0.85),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: BottomNavigationBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  currentIndex: _selectedIndex,
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor: colorScheme.primary,
                  unselectedItemColor: colorScheme.onSurfaceVariant,
                  showUnselectedLabels: true,
                  onTap: (index) => setState(() => _selectedIndex = index),
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.location_city_outlined),
                      activeIcon: Icon(Icons.location_city),
                      label: 'Villes',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.explore_outlined),
                      activeIcon: Icon(Icons.explore),
                      label: 'Découvertes',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.campaign_outlined),
                      activeIcon: Icon(Icons.campaign),
                      label: 'Annonces',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.work_outline),
                      activeIcon: Icon(Icons.work),
                      label: 'Pro',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.category_outlined),
                      activeIcon: Icon(Icons.category),
                      label: 'Catégories',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
