import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:eloquence_2_0/src/services/clean_livekit_service.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_models.dart';
import 'package:eloquence_2_0/features/confidence_boost/domain/entities/confidence_scenario.dart';

class FakeCleanLiveKitService extends CleanLiveKitService {
  FakeCleanLiveKitService() : super();
  @override
  bool get isConnected => true;

  @override
  Room? get room => null;

  @override
  LocalParticipant? get localParticipant => null;

  @override
  Stream<Uint8List> get onAudioReceivedStream => const Stream.empty();

  @override
  Future<bool> connect(String url, String token) async => true;

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> publishMyAudio() async {}

  @override
  Future<void> unpublishMyAudio() async {}

  @override
  Future<ConfidenceAnalysis> requestConfidenceAnalysis({
    required ConfidenceScenario scenario,
    required int recordingDurationSeconds,
  }) async {
    return ConfidenceAnalysis(
      overallScore: 85.0,
      confidenceScore: 0.85,
      fluencyScore: 0.80,
      clarityScore: 0.82,
      energyScore: 0.90,
      feedback: 'Test analysis feedback',
      wordCount: 100,
      speakingRate: 120,
      keywordsUsed: [],
      transcription: '',
      strengths: [],
      improvements: [],
    );
  }
  
  // TODO: implement analysisStream
  Stream<ConfidenceAnalysis> get analysisStream => throw UnimplementedError();
  
  Future<void> endSession() {
    // TODO: implement endSession
    throw UnimplementedError();
  }
  
  // TODO: implement isSessionActive
  bool get isSessionActive => throw UnimplementedError();
  
  Future<bool> startRecording() {
    // TODO: implement startRecording
    throw UnimplementedError();
  }
  
  Future<String?> startSession(Map<String, dynamic> sessionData) {
    // TODO: implement startSession
    throw UnimplementedError();
  }
  
  Future<bool> stopRecordingAndAnalyze() {
    // TODO: implement stopRecordingAndAnalyze
    throw UnimplementedError();
  }
}