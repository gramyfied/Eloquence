import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Client HTTP avec timeout
  final http.Client _client = http.Client();

  // Test de connectivité au serveur
  Future<bool> testConnection() async {
    try {
      final response = await _client
          .get(
            Uri.parse(ApiConfig.healthEndpoint),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.connectionTimeout);
      
      return response.statusCode == 200;
    } catch (e) {
      print('Erreur de connexion au serveur: $e');
      return false;
    }
  }

  // GET request générique
  Future<http.Response> get(String endpoint) async {
    try {
      final response = await _client
          .get(
            Uri.parse(endpoint),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.requestTimeout);
      
      return response;
    } on SocketException {
      throw Exception('Pas de connexion internet');
    } on HttpException {
      throw Exception('Erreur HTTP');
    } on FormatException {
      throw Exception('Réponse mal formatée');
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // POST request générique
  Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _client
          .post(
            Uri.parse(endpoint),
            headers: ApiConfig.defaultHeaders,
            body: json.encode(data),
          )
          .timeout(ApiConfig.requestTimeout);
      
      return response;
    } on SocketException {
      throw Exception('Pas de connexion internet');
    } on HttpException {
      throw Exception('Erreur HTTP');
    } on FormatException {
      throw Exception('Réponse mal formatée');
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // PUT request générique
  Future<http.Response> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _client
          .put(
            Uri.parse(endpoint),
            headers: ApiConfig.defaultHeaders,
            body: json.encode(data),
          )
          .timeout(ApiConfig.requestTimeout);
      
      return response;
    } on SocketException {
      throw Exception('Pas de connexion internet');
    } on HttpException {
      throw Exception('Erreur HTTP');
    } on FormatException {
      throw Exception('Réponse mal formatée');
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // DELETE request générique
  Future<http.Response> delete(String endpoint) async {
    try {
      final response = await _client
          .delete(
            Uri.parse(endpoint),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.requestTimeout);
      
      return response;
    } on SocketException {
      throw Exception('Pas de connexion internet');
    } on HttpException {
      throw Exception('Erreur HTTP');
    } on FormatException {
      throw Exception('Réponse mal formatée');
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Méthodes spécifiques pour les items
  Future<List<dynamic>> getItems() async {
    final response = await get(ApiConfig.itemsEndpoint);
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur lors du chargement des items: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> createItem(String name, String description, double price) async {
    final data = {
      'name': name,
      'description': description,
      'price': price,
    };
    
    final response = await post(ApiConfig.itemsEndpoint, data);
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur lors de la création de l\'item: ${response.statusCode}');
    }
  }

  // Nettoyage des ressources
  void dispose() {
    _client.close();
  }
}
