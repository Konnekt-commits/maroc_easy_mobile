import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';

Future<void> addUser({
  required String email,
  required String password,
  required List<String> roles,
  String? nom,
  String? prenom,
  String? pseudoName,
  File? imageFile,
}) async {
  final uri = Uri.parse('https://maroceasy.konnekt.fr/api/users');

  final request = http.MultipartRequest('POST', uri);

  // Champs simples
  request.fields['email'] = email;
  request.fields['password'] = password;
  request.fields['roles[]'] = roles.join(
    ',',
  ); // ou envoyer plusieurs fois 'roles[]'

  if (nom != null) request.fields['nom'] = nom;
  if (prenom != null) request.fields['prenom'] = prenom;
  if (pseudoName != null) request.fields['pseudoName'] = pseudoName;

  // Fichier image
  if (imageFile != null) {
    request.files.add(
      await http.MultipartFile.fromPath(
        'pictoFile',
        imageFile.path,
        filename: basename(imageFile.path),
        contentType: MediaType('image', 'jpg'), // ajuste si PNG ou autre
      ),
    );
  }

  try {
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201 || response.statusCode == 200) {
      print('Utilisateur ajouté : ${response.body}');
    } else {
      print('Erreur ${response.statusCode}: ${response.body}');
    }
  } catch (e) {
    print('Erreur lors de la requête : $e');
  }
}
