import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AddressSearchField extends StatefulWidget {
  final Function(String, double, double) onAddressSelected;

  /// 👉 Nouvelle ville à filtrer
  final String city;

  const AddressSearchField({
    Key? key,
    required this.onAddressSelected,
    required this.city, // 👈 nouvelle propriété
  }) : super(key: key);

  @override
  _AddressSearchFieldState createState() => _AddressSearchFieldState();
}

class _AddressSearchFieldState extends State<AddressSearchField> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  List<dynamic> _suggestions = [];

  Future<void> _searchAddress(String query) async {
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }

    /// 👉 On ajoute la ville dans la recherche Nominatim
    /// Exemple : q="pizza Casablanca"
    final fullQuery = "$query ${widget.city}".trim();

    final url = Uri.parse(
      "https://nominatim.openstreetmap.org/search?q=$fullQuery&format=json&addressdetails=1&limit=5&accept-language=fr&countrycodes=MA",
    );

    final response = await http.get(
      url,
      headers: {
        'User-Agent': 'com.example.app', // Obligatoire pour Nominatim
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _suggestions = json.decode(response.body);
      });
    }
  }

  @override
  void didUpdateWidget(covariant AddressSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Si la ville change → on réinitialise le TextField et les suggestions
    if (oldWidget.city != widget.city) {
      _controller.clear();
      setState(() {
        _suggestions = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: "Adresse *",
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (value) {
            if (_debounce?.isActive ?? false) _debounce!.cancel();

            _debounce = Timer(const Duration(milliseconds: 500), () {
              _searchAddress(value);
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Veuillez sélectionner une adresse";
            }
            return null;
          },
        ),

        if (_suggestions.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = _suggestions[index];

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    final lat = double.parse(suggestion["lat"]);
                    final lon = double.parse(suggestion["lon"]);

                    widget.onAddressSelected(
                      suggestion["display_name"],
                      lat,
                      lon,
                    );

                    setState(() {
                      _controller.text = suggestion["display_name"];
                      _suggestions = [];
                    });

                    FocusScope.of(context).unfocus();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.redAccent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            suggestion["display_name"],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
