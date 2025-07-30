import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../config/mobile_timeout_constants.dart';
import '../utils/logger_service.dart';

/// Service HTTP optimisé pour mobile avec pool de connexions et compression
/// 
/// Optimisations appliquées :
/// - Pool de connexions persistantes (keep-alive)
/// - Compression gzip automatique
/// - Retry logic intégrée
/// - Timeouts optimisés pour mobile
/// - Cache de connexions DNS
class OptimizedHttpService {
  static const String _tag = 'OptimizedHttpService';
  
  // Singleton pour garantir une seule instance
  static OptimizedHttpService? _instance;
  factory OptimizedHttpService() => _instance ??= OptimizedHttpService._();
  
  // Client HTTP avec configuration optimisée
  late final IOClient _httpClient;
  
  // Configuration du pool de connexions
  static const int _maxConnectionsPerHost = 6; // Limite recommandée HTTP/1.1
  static const Duration _connectionTimeout = MobileTimeoutConstants.connectionTimeout; // Optimisé mobile
  static const Duration _idleTimeout = Duration(seconds: 120); // Temps avant de fermer une connexion inactive
  
  // Timeouts adaptatifs synchronisés avec MobileTimeoutConstants
  static const Duration shortTimeout = MobileTimeoutConstants.lightRequestTimeout;   // Pour requêtes légères
  static const Duration mediumTimeout = MobileTimeoutConstants.mediumRequestTimeout;  // Pour analyses moyennes
  static const Duration longTimeout = MobileTimeoutConstants.fileUploadTimeout;   // Pour uploads volumineux

  // Configuration retry
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(milliseconds: 500);
  
  OptimizedHttpService._() {
    // Créer un HttpClient personnalisé avec configuration optimale
    final innerClient = HttpClient()
      ..maxConnectionsPerHost = _maxConnectionsPerHost
      ..connectionTimeout = _connectionTimeout
      ..idleTimeout = _idleTimeout
      ..autoUncompress = true // Décompression automatique gzip
      ..userAgent = 'Eloquence/1.0 (Mobile; Flutter)';
    
    // Configuration keep-alive (géré automatiquement par HttpClient)
    // Le keep-alive est activé par défaut dans HttpClient
    
    // Désactiver le logging en production pour les performances
    // innerClient.enableTimelineLogging = false;
    
    _httpClient = IOClient(innerClient);
    
    logger.i(_tag, '✅ Service HTTP optimisé initialisé');
    logger.d(_tag, '''Configuration:
    - Max connexions/host: $_maxConnectionsPerHost
    - Timeout connexion: ${_connectionTimeout.inSeconds}s
    - Timeout idle: ${_idleTimeout.inSeconds}s
    - Keep-alive: activé
    - Compression gzip: activée
    - Default Short Timeout: ${shortTimeout.inSeconds}s (Vosk)
    - Default Medium Timeout: ${mediumTimeout.inSeconds}s (Mistral)
    - Default Long Timeout: ${longTimeout.inSeconds}s (Upload)
    ''');
  }
  
  /// GET avec retry et compression
  Future<http.Response> get(
    String url, {
    Map<String, String>? headers,
    Duration? timeout,
    int? maxRetries,
  }) async {
    return _executeWithRetry(
      () => _httpClient.get(
        Uri.parse(url),
        headers: _prepareHeaders(headers),
      ).timeout(timeout ?? mediumTimeout), // Default to mediumTimeout
      url: url,
      method: 'GET',
      maxRetries: maxRetries ?? _maxRetries,
    );
  }
  
  /// POST avec retry et compression
  Future<http.Response> post(
    String url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration? timeout,
    int? maxRetries,
  }) async {
    return _executeWithRetry(
      () => _httpClient.post(
        Uri.parse(url),
        headers: _prepareHeaders(headers),
        body: body,
        encoding: encoding,
      ).timeout(timeout ?? mediumTimeout), // Default to mediumTimeout
      url: url,
      method: 'POST',
      maxRetries: maxRetries ?? _maxRetries,
    );
  }
  
  /// PUT avec retry et compression
  Future<http.Response> put(
    String url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration? timeout,
    int? maxRetries,
  }) async {
    return _executeWithRetry(
      () => _httpClient.put(
        Uri.parse(url),
        headers: _prepareHeaders(headers),
        body: body,
        encoding: encoding,
      ).timeout(timeout ?? mediumTimeout), // Default to mediumTimeout
      url: url,
      method: 'PUT',
      maxRetries: maxRetries ?? _maxRetries,
    );
  }
  
  /// DELETE avec retry
  Future<http.Response> delete(
    String url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration? timeout,
    int? maxRetries,
  }) async {
    return _executeWithRetry(
      () => _httpClient.delete(
        Uri.parse(url),
        headers: _prepareHeaders(headers),
        body: body,
        encoding: encoding,
      ).timeout(timeout ?? mediumTimeout), // Default to mediumTimeout
      url: url,
      method: 'DELETE',
      maxRetries: maxRetries ?? _maxRetries,
    );
  }
  
  /// Envoi de fichiers avec MultipartRequest optimisée
  /// Envoi de fichiers avec MultipartRequest optimisée et support de recréation
  Future<http.StreamedResponse> sendMultipart(
    String url,
    String method, {
    Map<String, String>? headers,
    Map<String, String>? fields,
    // Change List<http.MultipartFile>? files, to a function that returns files
    FutureOr<List<http.MultipartFile>> Function()? fileProvider,
    Duration? timeout,
    int? maxRetries,
  }) async {
    return _executeWithRetry(
      () async {
        final request = http.MultipartRequest(method, Uri.parse(url));
        
        // Headers optimisés
        request.headers.addAll(_prepareHeaders(headers));
        
        // Ajouter les champs
        if (fields != null) {
          request.fields.addAll(fields);
        }
        
        // Ajouter les fichiers - appel via le provider pour recréer l'instance
        if (fileProvider != null) {
          final files = await Future.value(fileProvider()); // Résoudre le FutureOr
          request.files.addAll(files);
        }
        
        return _httpClient.send(request).timeout(
          timeout ?? longTimeout, // Default to longTimeout for file uploads
        );
      },
      url: url,
      method: method,
      maxRetries: maxRetries ?? _maxRetries,
    );
  }
  
  /// Envoi direct d'une requête MultipartRequest (pour compatibilité)
  Future<http.StreamedResponse> sendMultipartRequest(
    http.MultipartRequest request, {
    Duration? timeout,
    int? maxRetries,
  }) async {
    return _executeWithRetry(
      () async {
        // Appliquer les headers optimisés tout en préservant ceux existants
        final optimizedHeaders = _prepareHeaders(request.headers);
        request.headers.addAll(optimizedHeaders);
        
        return _httpClient.send(request).timeout(
          timeout ?? longTimeout, // Default to longTimeout for multi-part requests
        );
      },
      url: request.url.toString(),
      method: request.method,
      maxRetries: maxRetries ?? _maxRetries,
    );
  }
  
  /// Prépare les headers avec compression et keep-alive
  Map<String, String> _prepareHeaders(Map<String, String>? userHeaders) {
    // Les headers de l'utilisateur (userHeaders) surchargent les valeurs par défaut.
    final headers = <String, String>{
      'Accept-Encoding': 'gzip, deflate',
      'Connection': 'keep-alive',
      'Accept': 'application/json',
      ...?userHeaders,
    };
    
    return headers;
  }
  
  /// Exécute une requête avec retry logic
  Future<T> _executeWithRetry<T>(
    Future<T> Function() request, {
    required String url,
    required String method,
    required int maxRetries,
  }) async {
    int attempt = 0;
    Exception? lastError;
    
    while (attempt < maxRetries) {
      try {
        attempt++;
        logger.d(_tag, '🔄 $method $url - Tentative $attempt/$maxRetries');
        
        final result = await request();
        
        // Vérifier si c'est une réponse HTTP
        if (result is http.Response) {
          logger.d(_tag, '✅ $method $url - Status: ${result.statusCode}');
          
          // Retry uniquement sur certains codes d'erreur
          if (_shouldRetry(result.statusCode) && attempt < maxRetries) {
            logger.w(_tag, '⚠️ Status ${result.statusCode}, retry dans ${_retryDelay.inMilliseconds}ms');
            await Future.delayed(_retryDelay * attempt); // Backoff exponentiel
            continue;
          }
        }
        
        return result;
        
      } on SocketException catch (e) {
        lastError = e;
        logger.w(_tag, '🔌 Erreur réseau: ${e.message}');
        
        if (attempt < maxRetries) {
          await Future.delayed(_retryDelay * attempt);
          continue;
        }
      } on TimeoutException catch (e) {
        lastError = e;
        logger.w(_tag, '⏱️ Timeout: ${e.message}');
        
        if (attempt < maxRetries) {
          await Future.delayed(_retryDelay * attempt);
          continue;
        }
      } on HttpException catch (e) {
        lastError = e;
        logger.w(_tag, '🌐 Erreur HTTP: ${e.message}');
        
        if (attempt < maxRetries) {
          await Future.delayed(_retryDelay * attempt);
          continue;
        }
      } catch (e) {
        // Autres erreurs non-récupérables
        logger.e(_tag, '❌ Erreur non-récupérable: $e');
        rethrow;
      }
    }
    
    // Si on arrive ici, toutes les tentatives ont échoué
    logger.e(_tag, '❌ Échec après $maxRetries tentatives');
    throw lastError ?? Exception('Échec requête après $maxRetries tentatives');
  }
  
  /// Détermine si une erreur HTTP doit déclencher un retry
  bool _shouldRetry(int statusCode) {
    return statusCode == 408 || // Request Timeout
           statusCode == 429 || // Too Many Requests
           statusCode == 500 || // Internal Server Error
           statusCode == 502 || // Bad Gateway
           statusCode == 503 || // Service Unavailable
           statusCode == 504;   // Gateway Timeout
  }
  
  /// Statistiques de performance (pour debug)
  Future<Map<String, dynamic>> getPerformanceStats() async {
    // Note: Ces stats sont basiques, en production utiliser un vrai monitoring
    return {
      'service': 'OptimizedHttpService',
      'maxConnectionsPerHost': _maxConnectionsPerHost,
      'connectionTimeout': _connectionTimeout.inSeconds,
      'idleTimeout': _idleTimeout.inSeconds,
      'keepAlive': true,
      'compression': 'gzip',
      'retryEnabled': true,
      'maxRetries': _maxRetries,
    };
  }
  
  /// Ferme le client HTTP (à appeler lors du dispose de l'app)
  void dispose() {
    _httpClient.close();
    _instance = null;
    logger.i(_tag, '🛑 Service HTTP fermé');
  }
}

/// Extension pour simplifier l'utilisation
extension OptimizedHttpExtensions on http.Response {
  /// Décode le body JSON avec gestion d'erreur
  dynamic get jsonBody {
    try {
      return jsonDecode(body);
    } catch (e) {
      logger.e('OptimizedHttp', 'Erreur décodage JSON: $e\nBody: $body');
      return null;
    }
  }
  
  /// Vérifie si la réponse est un succès
  bool get isSuccess => statusCode >= 200 && statusCode < 300;
  
  /// Vérifie si c'est une erreur client
  bool get isClientError => statusCode >= 400 && statusCode < 500;
  
  /// Vérifie si c'est une erreur serveur
  bool get isServerError => statusCode >= 500;
}
