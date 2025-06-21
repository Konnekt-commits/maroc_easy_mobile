import 'dart:async';
import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:maroc_easy/widgets/CategoryIconMapper.dart';
import 'package:maroc_easy/widgets/loader.dart';
import 'package:maroc_easy/widgets/range_price.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/property_card.dart';
import 'property_detail_page.dart';
import '../widgets/month_destination.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  Timer? _timer;
  List<dynamic> _categories = [];
  List<dynamic> _villes = [];
  List<dynamic> _annonces = [];
  List<dynamic> _decouvertes = [];
  int _selectedCategoryIndex = 0;
  String _nom = "";
  String _adresse = "";
  int _villeId = 0;
  double _prixMin = 0;
  double _prixMax = 5000;
  List<Widget> carouselItems = [];
  int _selectedIndex = 0;

  bool loading = true;
  fetchTags() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.get(
      Uri.parse("https://maroceasy.konnekt.fr/api/categories?page=1"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      var jsonData = json.decode(response.body);
      print(jsonData["hydra:member"]);
      setState(() {
        _categories = jsonData["hydra:member"];
        _selectedCategoryIndex = _categories[0]['id'];
      });
      return jsonData["hydra:member"];
    } else if (response.statusCode == 426) {
      // Gestion de l'erreur 426 : Mise à jour requise
      var errorData = jsonDecode(response.body);
      String updateUrl = errorData['update_url'];

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Mise à jour requise'),
              content: const Text(
                'Veuillez télécharger la dernière version de l\'application.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Ouvrir le lien de mise à jour
                    launch(updateUrl);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Mettre à jour'),
                ),
              ],
            ),
      );
    } else {
      // Gestion des autres erreurs
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Erreur'),
              content: Text(
                'Status Code: ${response.statusCode} \nResponse Body: ${response.body}',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Ok"),
                ),
              ],
            ),
      );
      throw Exception('Échec de la récupération de données');
    }
  }

  fetchDecouvertes() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.get(
      Uri.parse(
        "https://maroceasy.konnekt.fr/api/decouvertes?page=1&ville.id=$_villeId",
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      var jsonData = json.decode(response.body);
      print(jsonData["hydra:member"]);
      setState(() {
        _decouvertes = jsonData["hydra:member"];
        carouselItems = List.generate(_decouvertes.length, (index) {
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(_decouvertes[index]['picto']),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _decouvertes[index]['titre'],
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _decouvertes[index]['description'],
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      Spacer(),

                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 25,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Découvrir',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
      });
      return jsonData["hydra:member"];
    } else if (response.statusCode == 426) {
      // Gestion de l'erreur 426 : Mise à jour requise
      var errorData = jsonDecode(response.body);
      String updateUrl = errorData['update_url'];

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Mise à jour requise'),
              content: const Text(
                'Veuillez télécharger la dernière version de l\'application.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Ouvrir le lien de mise à jour
                    launch(updateUrl);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Mettre à jour'),
                ),
              ],
            ),
      );
    } else {
      // Gestion des autres erreurs
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Erreur'),
              content: Text(
                'Status Code: ${response.statusCode} \nResponse Body: ${response.body}',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Ok"),
                ),
              ],
            ),
      );
      throw Exception('Échec de la récupération de données');
    }
  }

  fetchAnnonces() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.get(
      Uri.parse(
        "https://maroceasy.konnekt.fr/api/annonces?page=1&nom=$_nom&adresse=$_adresse&category.id=$_selectedCategoryIndex&ville.id=$_villeId&prix%5Bmin%5D=$_prixMin&prix%5Bmax%5D=$_prixMax",
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      var jsonData = json.decode(response.body);
      print(jsonData["hydra:member"]);
      setState(() {
        _annonces = jsonData["hydra:member"];
      });
      return jsonData["hydra:member"];
    } else if (response.statusCode == 426) {
      // Gestion de l'erreur 426 : Mise à jour requise
      var errorData = jsonDecode(response.body);
      String updateUrl = errorData['update_url'];

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Mise à jour requise'),
              content: const Text(
                'Veuillez télécharger la dernière version de l\'application.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Ouvrir le lien de mise à jour
                    launch(updateUrl);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Mettre à jour'),
                ),
              ],
            ),
      );
    } else {
      // Gestion des autres erreurs
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Erreur'),
              content: Text(
                'Status Code: ${response.statusCode} \nResponse Body: ${response.body}',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Ok"),
                ),
              ],
            ),
      );
      throw Exception('Échec de la récupération de données');
    }
  }

  fetchVilles() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.get(
      Uri.parse("https://maroceasy.konnekt.fr/api/villes?page=1"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      var jsonData = json.decode(response.body);
      print(jsonData["hydra:member"]);
      setState(() {
        _villes = jsonData["hydra:member"];
        _villeId = _villes[0]['id'];
      });
      return jsonData["hydra:member"];
    } else if (response.statusCode == 426) {
      // Gestion de l'erreur 426 : Mise à jour requise
      var errorData = jsonDecode(response.body);
      String updateUrl = errorData['update_url'];

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Mise à jour requise'),
              content: const Text(
                'Veuillez télécharger la dernière version de l\'application.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Ouvrir le lien de mise à jour
                    launch(updateUrl);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Mettre à jour'),
                ),
              ],
            ),
      );
    } else {
      // Gestion des autres erreurs
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Erreur'),
              content: Text(
                'Status Code: ${response.statusCode} \nResponse Body: ${response.body}',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Ok"),
                ),
              ],
            ),
      );
      throw Exception('Échec de la récupération de données');
    }
  }

  Future<void> initPage() async {
    await fetchTags();
    await fetchVilles();
    await fetchDecouvertes();
    await fetchAnnonces();
    setState(() {
      loading = false;
    });
  }

  @override
  void initState() {
    initPage();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                onChanged: (value) {
                  if (_timer?.isActive ?? false) _timer!.cancel();
                  _timer = Timer(const Duration(seconds: 1), () {
                    setState(() {
                      _nom = value;
                    });
                    fetchAnnonces();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Commencer ma recherche',
                  prefixIcon: const Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
          DiscreetPriceFilter(
            minPrice: 0,
            maxPrice: 5000,
            onPriceChanged: (min, max) {
              // Filtrez vos données ici
              if (_timer?.isActive ?? false) _timer!.cancel();
              _timer = Timer(const Duration(seconds: 1), () {
                setState(() {
                  _prixMin = min;
                  _prixMax = max;
                });
                fetchAnnonces();
              });
            },
          ),

          // Catégories
          SizedBox(
            height: 60,
            child:
                loading
                    ? ListView.builder(
                      itemCount: 6,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) => LoaderCategory(),
                    )
                    : ListView.builder(
                      itemCount: _categories.length,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategoryIndex = _categories[index]['id'];
                            });
                            fetchAnnonces();
                          },
                          child: _buildCategoryItem(
                            _categories[index]['nom'],
                            CategoryIconMapper.getIconForCategory(
                              _categories[index]['nom'],
                            ),
                            _selectedCategoryIndex == _categories[index]['id'],
                          ),
                        );
                      },
                    ),
          ),

          // Contenu principal avec défilement
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),

                        // Destinations mensuelles
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children:
                                loading
                                    ? List.generate(6, (index) => LoaderVille())
                                    : List.generate(_villes.length, (index) {
                                      return GestureDetector(
                                        onTap: () {
                                          if (_timer?.isActive ?? false)
                                            _timer!.cancel();
                                          _timer = Timer(
                                            const Duration(seconds: 1),
                                            () {
                                              setState(() {
                                                _villeId = _villes[index]['id'];
                                              });
                                              fetchAnnonces();
                                              fetchDecouvertes();
                                            },
                                          );
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.only(
                                            right: 16,
                                          ),
                                          width: 120,
                                          height: 120,
                                          decoration: BoxDecoration(
                                            border:
                                                _villeId == _villes[index]['id']
                                                    ? Border.all(
                                                      color: Colors.pink,
                                                      width: 3,
                                                    )
                                                    : null,
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: CityDestination(
                                            city: _villes[index]['nom'],
                                            imageUrl:
                                                _villes[index]['picto'] != null
                                                    ? _villes[index]['picto']
                                                    : 'https://images.unsplash.com/photo-1597212618440-806262de4f6b?q=80&w=2073&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
                                          ),
                                        ),
                                      );
                                    }),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Section avec image de fond
                        if (_decouvertes.isNotEmpty)
                          CarouselSlider(
                            items: carouselItems,
                            options: CarouselOptions(
                              height: 300,
                              autoPlay: true,
                              enlargeCenterPage: true,
                              viewportFraction: 1.0,
                              autoPlayInterval: Duration(seconds: 5),
                              autoPlayAnimationDuration: Duration(
                                milliseconds: 800,
                              ),
                              scrollDirection: Axis.horizontal,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Liste des propriétés
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children:
                          loading
                              ? List.generate(4, (index) => LoaderAnnonce())
                              : List.generate(_annonces.length, (index) {
                                return PropertyCard(
                                  title: _annonces[index]["nom"],
                                  location: _annonces[index]["adresse"],
                                  price: '${_annonces[index]["prix"]}€',
                                  rating: 4.5,
                                  imageUrls:
                                      (_annonces[index]["galeriesPhoto"]
                                              as List<dynamic>)
                                          .map<String>(
                                            (photo) =>
                                                photo["urlPhoto"] as String,
                                          )
                                          .toList(),

                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => PropertyDetailPage(
                                              id: _annonces[index]["id"],
                                              phone:
                                                  _annonces[index]["telephone"],
                                              title: _annonces[index]["nom"],
                                              location:
                                                  _annonces[index]["adresse"],
                                              price:
                                                  '${_annonces[index]["prix"]}€',
                                              rating: 4.5,
                                              description:
                                                  _annonces[index]["descriptionLongue"],
                                              amenities:
                                                  (_annonces[index]["comodites"]
                                                          as List)
                                                      .cast<String>(),
                                              imageUrls:
                                                  (_annonces[index]["galeriesPhoto"]
                                                          as List<dynamic>)
                                                      .map<String>(
                                                        (photo) =>
                                                            photo["urlPhoto"]
                                                                as String,
                                                      )
                                                      .toList(),
                                              // Add coordinates for the map
                                              coordinates: LatLng(
                                                double.parse(
                                                  _annonces[index]["latitude"]
                                                      .toString(),
                                                ),
                                                double.parse(
                                                  _annonces[index]["longitude"]
                                                      .toString(),
                                                ),
                                              ), // Marrakech coordinates
                                            ),
                                      ),
                                    );
                                  },
                                );
                              }),
                    ),
                  ),
                ],
              ),
            ),
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
