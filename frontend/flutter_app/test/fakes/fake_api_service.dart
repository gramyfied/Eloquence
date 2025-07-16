import 'dart:async';
import 'dart:typed_data';
import 'package:eloquence_2_0/data/services/api_service.dart';
import 'package:eloquence_2_0/data/models/scenario_model.dart';
import 'package:eloquence_2_0/data/models/session_model.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class FakeApiService extends ApiService {
  FakeApiService() : super(apiKey: 'fake-api-key');
  @override
  String get baseUrl => 'http://fake.url';

  @override
  String? get authToken => 'fake_token';

  @override
  String get apiKey => 'fake_api_key';

  @override
  Map<String, String> get headers => {'Content-Type': 'application/json'};

  @override
  Future<List<ScenarioModel>> getScenarios({
    String? type,
    String? difficulty,
    String language = 'fr',
  }) async {
    return [];
  }

  @override
  Future<ScenarioModel?> getScenario(String scenarioId) async {
    return null;
  }

  @override
  bool isApiAuthError(dynamic error) {
    return false;
  }

  @override
  Future<SessionModel> startSession(
    String scenarioId,
    String userId, {
    String language = 'fr',
    String? goal,
    String? agentProfileId,
    bool isMultiAgent = false,
  }) async {
    return SessionModel(
      sessionId: 'fake_session_id',
      roomName: 'fake_room_name',
      token: 'fake_livekit_token',
      livekitUrl: 'ws://fake.livekit.url',
      initialMessage: {},
    );
  }

  @override
  Future<WebSocketChannel> connectWebSocket(String sessionId) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> endSession(String sessionId) async {
    return true;
  }

  @override
  Future<String> transcribeAudio(String audioFilePath) async {
    return 'fake transcription';
  }

  @override
  Future<String> generateResponse(String prompt) async {
    return 'fake response';
  }

  @override
  Future<Uint8List> synthesizeAudio(String text) async {
    return Uint8List(0);
  }
}