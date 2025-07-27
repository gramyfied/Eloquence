// lib/services/eloquence_conversation_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

class EloquenceConversationService {
  final String baseUrl;
  final String wsUrl;
  
  EloquenceConversationService({
    this.baseUrl = 'http://192.168.1.44:8000',  // ← IP locale de ton PC pour accès mobile
  }) : wsUrl = baseUrl.replaceFirst('http', 'ws');
  
  // Test de santé de l'API
  Future<bool> healthCheck() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      print('Erreur health check: $e');
      return false;
    }
  }
  
  // Liste des exercices disponibles
  Future<List<Map<String, dynamic>>> getExercises() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/exercises'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['exercises']);
      }
      return [];
    } catch (e) {
      print('Erreur récupération exercices: $e');
      return [];
    }
  }
  
  // Création session conversationnelle
  Future<Map<String, dynamic>?> createSession({
    required String exerciseType,
    required String userId,
    Map<String, dynamic>? additionalConfig,
  }) async {
    try {
      final requestData = {
        'exercise_type': exerciseType,
        'user_id': userId,
        ...?additionalConfig,
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/sessions/create'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Erreur création session: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Erreur création session: $e');
      return null;
    }
  }
  
  // Connexion WebSocket pour conversation
  WebSocketChannel connectToConversation(String sessionId) {
    final wsUri = Uri.parse('$wsUrl/api/sessions/$sessionId/stream');
    return WebSocketChannel.connect(wsUri);
  }
  
  // Envoi chunk audio via WebSocket
  void sendAudioChunk(WebSocketChannel channel, Uint8List audioData) {
    final message = {
      'type': 'audio_chunk',
      'data': base64Encode(audioData),
      'timestamp': DateTime.now().toIso8601String(),
    };
    channel.sink.add(json.encode(message));
  }
  
  // Fin de session
  void endSession(WebSocketChannel channel) {
    final message = {'type': 'end_session'};
    channel.sink.add(json.encode(message));
  }
  
  // Récupération analyse session
  Future<Map<String, dynamic>?> getSessionAnalysis(String sessionId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/sessions/$sessionId/analysis')
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Erreur analyse session: $e');
      return null;
    }
  }
  
  // Finalisation session avec rapport
  Future<Map<String, dynamic>?> finalizeSession(String sessionId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/sessions/$sessionId/end')
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Erreur finalisation session: $e');
      return null;
    }
  }
}