import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AnnonceSearchField extends StatefulWidget {
  final TextEditingController controller;
  final void Function(int id, String title)
  onSelected; // callback quand on choisit
  AnnonceSearchField({
    Key? key,
    required this.onSelected,
    required this.controller,
  }) : super(key: key);

  @override
  State<AnnonceSearchField> createState() => _AnnonceSearchFieldState();
}

class _AnnonceSearchFieldState extends State<AnnonceSearchField> {
  int? _selectedAnnonceId;

  Future<List<Map<String, dynamic>>> _searchAnnonces(String query) async {
    if (query.isEmpty) return [];

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userDataString = prefs.getString('userData');
    final userData = json.decode(userDataString!);

    final response = await http.get(
      Uri.parse(
        'https://maroceasy.konnekt.fr/api/annonces?user.id=${userData['id']}&nom=$query',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List annonces = data['hydra:member'];

      return annonces
          .map<Map<String, dynamic>>(
            (annonce) => {'id': annonce['id'], 'nom': annonce['nom']},
          )
          .toList();
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return TypeAheadField<Map<String, dynamic>>(
      suggestionsCallback: (pattern) async => await _searchAnnonces(pattern),
      builder: (context, controller, focusNode) {
        // Assure que le TextField utilise notre widget.controller
        return TextField(
          controller: widget.controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: "Rechercher une annonce",
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              controller.text = value;
            });
          },
        );
      },
      itemBuilder: (context, annonce) {
        return ListTile(
          leading: Icon(Icons.store),
          title: Text(annonce['nom']),
        );
      },
      onSelected: (annonce) {
        widget.controller.text = annonce['nom']; // maintenant ça marche
        _selectedAnnonceId = annonce['id'];
        widget.onSelected(annonce['id'], annonce['nom']);
      },
      emptyBuilder:
          (context) => const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Aucune annonce trouvée"),
          ),
    );
  }
}
