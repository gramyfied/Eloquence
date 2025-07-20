// Provider centralisé pour la configuration réseau adaptative (LAN, fallback, mobile)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NetworkConfig {
  final String llmServiceUrl;
  final String fallbackLlmServiceUrl;
  final String livekitUrl;
  final String fallbackLivekitUrl;
  final String voskUrl;
  final String fallbackVoskUrl;
  final int requestTimeout;

  NetworkConfig({
    required this.llmServiceUrl,
    required this.fallbackLlmServiceUrl,
    required this.livekitUrl,
    required this.fallbackLivekitUrl,
    required this.voskUrl,
    required this.fallbackVoskUrl,
    required this.requestTimeout,
  });

  // Méthode pour choisir dynamiquement l'URL (LAN, fallback, etc.)
  String getBestLlmServiceUrl({bool preferFallback = false}) {
    if (preferFallback) return fallbackLlmServiceUrl;
    return llmServiceUrl;
  }

  String getBestLivekitUrl({bool preferFallback = false}) {
    if (preferFallback) return fallbackLivekitUrl;
    return livekitUrl;
  }

  String getBestVoskUrl({bool preferFallback = false}) {
    if (preferFallback) return fallbackVoskUrl;
    return voskUrl;
  }
}

// Provider Riverpod pour NetworkConfig
final networkConfigProvider = Provider<NetworkConfig>((ref) {
  final env = dotenv.env;

  return NetworkConfig(
    llmServiceUrl: env['LLM_SERVICE_URL'] ?? 'http://localhost:8000',
    fallbackLlmServiceUrl: env['FALLBACK_LLM_SERVICE_URL'] ?? 'http://localhost:8000',
    livekitUrl: env['LIVEKIT_URL'] ?? 'ws://localhost:7880',
    fallbackLivekitUrl: env['FALLBACK_LIVEKIT_URL'] ?? 'ws://localhost:7880',
    voskUrl: env['VOSK_URL'] ?? 'http://localhost:8003',
    fallbackVoskUrl: env['FALLBACK_VOSK_URL'] ?? 'http://localhost:8003',
    requestTimeout: int.tryParse(env['MOBILE_REQUEST_TIMEOUT'] ?? '8') ?? 8,
  );
});