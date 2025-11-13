import 'dart:ui';

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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBody: true,
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
                      icon: Icon(Icons.campaign_outlined),
                      activeIcon: Icon(Icons.campaign),
                      label: 'Annonces',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.work_outline),
                      activeIcon: Icon(Icons.work),
                      label: 'Profil',
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
