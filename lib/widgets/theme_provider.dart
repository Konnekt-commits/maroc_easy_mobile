import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider {
  static final ValueNotifier<bool> isDarkMode = ValueNotifier(false);

  static const _key = "isDarkMode";

  /// 🔹 Initialise le thème en lisant la valeur sauvegardée
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedValue = prefs.getBool(_key) ?? false;
    isDarkMode.value = savedValue;
  }

  /// 🔹 Bascule le thème et sauvegarde la nouvelle valeur
  static Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode.value = !isDarkMode.value;
    await prefs.setBool(_key, isDarkMode.value);
  }

  /// 🔹 Change explicitement le thème
  static Future<void> setTheme(bool dark) async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode.value = dark;
    await prefs.setBool(_key, dark);
  }
}
