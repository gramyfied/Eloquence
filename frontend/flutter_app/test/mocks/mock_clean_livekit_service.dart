import 'package:mockito/mockito.dart';
import 'package:eloquence_2_0/src/services/clean_livekit_service.dart';

class MockCleanLiveKitService extends Mock implements CleanLiveKitService {
  @override
  Future<bool> startSession(Map<String, dynamic> sessionData) async {
    return true;
  }

  @override
  Future<bool> stopSession() async {
    return true;
  }

  @override
  Stream<Map<String, dynamic>> getAnalysisStream() {
    return Stream.value({
      'overallScore': 85.0,
      'confidenceScore': 80.0,
      'fluencyScore': 90.0,
      'clarityScore': 85.0,
      'energyScore': 88.0,
      'feedback': 'Test feedback',
      'wordCount': 150,
      'speakingRate': 120.0,
      'keywordsUsed': ['test', 'keywords'],
      'transcription': 'Test transcription',
      'strengths': ['Clear speech'],
      'improvements': ['More confidence'],
    });
  }

  @override
  Future<void> sendMessage(Map<String, dynamic> message) async {
    // Mock implementation
  }

  @override
  bool get isConnected => true;
}