import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/utils/logger_service.dart';
import '../../../../core/utils/constants.dart'; // Pour CacheConstants

/// Modèle pour une réponse en cache
class CachedResponse {
  final String response;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  
  CachedResponse({
    required this.response,
    required this.timestamp,
    this.metadata,
  });
  
  /// Vérifie si le cache est expiré
  bool get isExpired {
    final now = DateTime.now();
    final expirationTime = timestamp.add(CacheConstants.memoryExpiration);
    return now.isAfter(expirationTime);
  }
  
  /// Vérifie si le cache disque est expiré
  bool get isDiskExpired {
    final now = DateTime.now();
    final expirationTime = timestamp.add(CacheConstants.diskExpiration);
    return now.isAfter(expirationTime);
  }
  
  /// Convertir en JSON pour stockage
  Map<String, dynamic> toJson() => {
    'response': response,
    'timestamp': timestamp.toIso8601String(),
    'metadata': metadata,
  };
  
  /// Créer depuis JSON
  factory CachedResponse.fromJson(Map<String, dynamic> json) {
    return CachedResponse(
      response: json['response'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// Service de cache intelligent pour Mistral avec persistance
class MistralCacheService {
  static const String _tag = 'MistralCacheService';
  
  // Cache mémoire pour accès ultra-rapide
  static final Map<String, CachedResponse> _memoryCache = {};
  
  // Instance SharedPreferences
  static SharedPreferences? _prefs;
  
  // Statistiques de cache
  static int _cacheHits = 0;
  static int _cacheMisses = 0;
  static int _diskHits = 0;
  
  /// Initialise le service de cache
  static Future<void> init() async {
    try {
      logger.i(_tag, 'Initialisation du cache Mistral...');
      _prefs = await SharedPreferences.getInstance();
      
      // Charger les entrées non expirées du disque vers la mémoire
      await _loadCacheFromDisk();
      
      // Nettoyer les entrées expirées
      await _cleanExpiredDiskCache();
      
      logger.i(_tag, 'Cache initialisé: ${_memoryCache.length} entrées chargées');
    } catch (e) {
      logger.e(_tag, 'Erreur initialisation cache: $e');
    }
  }
  
  /// Charge le cache depuis le disque
  static Future<void> _loadCacheFromDisk() async {
    if (_prefs == null) return;
    
    try {
      final keys = _prefs!.getKeys().where((key) => key.startsWith(CacheConstants.cachePrefix));
      
      for (final key in keys) {
        final jsonString = _prefs!.getString(key);
        if (jsonString != null) {
          try {
            final json = jsonDecode(jsonString) as Map<String, dynamic>;
            final cached = CachedResponse.fromJson(json);
            
            // Ne charger que les entrées non expirées pour le disque
            if (!cached.isDiskExpired) {
              final cacheKey = key.replaceFirst(CacheConstants.cachePrefix, '');
              _memoryCache[cacheKey] = cached;
            }
          } catch (e) {
            logger.w(_tag, 'Erreur parsing cache entry $key: $e');
          }
        }
      }
    } catch (e) {
      logger.e(_tag, 'Erreur chargement cache depuis disque: $e');
    }
  }
  
  /// Nettoie les entrées expirées du cache disque
  static Future<void> _cleanExpiredDiskCache() async {
    if (_prefs == null) return;
    
    try {
      final keys = _prefs!.getKeys().where((key) => key.startsWith(CacheConstants.cachePrefix));
      final keysToRemove = <String>[];
      
      for (final key in keys) {
        final jsonString = _prefs!.getString(key);
        if (jsonString != null) {
          try {
            final json = jsonDecode(jsonString) as Map<String, dynamic>;
            final cached = CachedResponse.fromJson(json);
            
            if (cached.isDiskExpired) {
              keysToRemove.add(key);
            }
          } catch (e) {
            // Si on ne peut pas parser, on supprime
            keysToRemove.add(key);
          }
        }
      }
      
      // Supprimer les clés expirées
      for (final key in keysToRemove) {
        await _prefs!.remove(key);
      }
      
      if (keysToRemove.isNotEmpty) {
        logger.d(_tag, 'Nettoyage cache disque: ${keysToRemove.length} entrées supprimées');
      }
    } catch (e) {
      logger.e(_tag, 'Erreur nettoyage cache disque: $e');
    }
  }
  
  /// Génère une clé de cache unique
  static String generateCacheKey(String prompt, {int? maxTokens, double? temperature}) {
    // Créer une clé basée sur le prompt et les paramètres
    final params = '${maxTokens ?? 500}_${temperature ?? 0.7}';
    final promptHash = prompt.hashCode.toString();
    return '${promptHash}_$params';
  }
  
  /// Récupère une réponse du cache
  static Future<String?> getCachedResponse(String prompt, {int? maxTokens, double? temperature}) async {
    final key = generateCacheKey(prompt, maxTokens: maxTokens, temperature: temperature);
    
    // 1. Vérifier le cache mémoire d'abord
    final memoryCached = _memoryCache[key];
    if (memoryCached != null && !memoryCached.isExpired) {
      _cacheHits++;
      logger.d(_tag, 'Cache HIT (mémoire) - Stats: Hits=$_cacheHits, Misses=$_cacheMisses');
      return memoryCached.response;
    }
    
    // 2. Si expiré en mémoire mais pas sur disque, rafraîchir
    if (memoryCached != null && memoryCached.isExpired && !memoryCached.isDiskExpired) {
      _diskHits++;
      logger.d(_tag, 'Cache HIT (disque) - Rafraîchissement mémoire');
      return memoryCached.response;
    }
    
    // 3. Vérifier le cache disque si pas en mémoire
    if (_prefs != null && memoryCached == null) {
      final diskKey = '${CacheConstants.cachePrefix}$key';
      final jsonString = _prefs!.getString(diskKey);
      
      if (jsonString != null) {
        try {
          final json = jsonDecode(jsonString) as Map<String, dynamic>;
          final cached = CachedResponse.fromJson(json);
          
          if (!cached.isDiskExpired) {
            // Recharger en mémoire
            _memoryCache[key] = cached;
            _diskHits++;
            logger.d(_tag, 'Cache HIT (disque) - Chargé en mémoire');
            return cached.response;
          }
        } catch (e) {
          logger.w(_tag, 'Erreur lecture cache disque: $e');
        }
      }
    }
    
    // Cache miss
    _cacheMisses++;
    logger.d(_tag, 'Cache MISS - Stats: Hits=$_cacheHits, DiskHits=$_diskHits, Misses=$_cacheMisses');
    return null;
  }
  
  /// Stocke une réponse dans le cache
  static Future<void> cacheResponse(
    String prompt,
    String response, {
    int? maxTokens,
    double? temperature,
    Map<String, dynamic>? metadata,
  }) async {
    final key = generateCacheKey(prompt, maxTokens: maxTokens, temperature: temperature);
    final cached = CachedResponse(
      response: response,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
    
    // 1. Stocker en mémoire
    _memoryCache[key] = cached;
    
    // 2. Gérer la taille du cache mémoire
    if (_memoryCache.length > CacheConstants.maxMemoryCacheSize) {
      await _evictOldestMemoryEntries();
    }
    
    // 3. Stocker sur disque (asynchrone)
    if (_prefs != null) {
      try {
        final diskKey = '${CacheConstants.cachePrefix}$key';
        await _prefs!.setString(diskKey, jsonEncode(cached.toJson()));
        
        // Gérer la taille du cache disque
        await _manageDiskCacheSize();
      } catch (e) {
        logger.e(_tag, 'Erreur sauvegarde cache disque: $e');
      }
    }
    
    logger.d(_tag, 'Réponse mise en cache (mémoire + disque)');
  }
  
  /// Évince les entrées les plus anciennes du cache mémoire
  static Future<void> _evictOldestMemoryEntries() async {
    final sortedEntries = _memoryCache.entries.toList()
      ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));
    
    final entriesToRemove = sortedEntries
        .take(_memoryCache.length - CacheConstants.maxMemoryCacheSize + 10) // Libérer 10 places
        .map((e) => e.key)
        .toList();
    
    for (final key in entriesToRemove) {
      _memoryCache.remove(key);
    }
    
    logger.d(_tag, 'Éviction mémoire: ${entriesToRemove.length} entrées supprimées');
  }
  
  /// Gère la taille du cache disque
  static Future<void> _manageDiskCacheSize() async {
    if (_prefs == null) return;
    
    try {
      final cacheKeys = _prefs!.getKeys()
          .where((key) => key.startsWith(CacheConstants.cachePrefix))
          .toList();
      
      if (cacheKeys.length > CacheConstants.maxDiskCacheSize) {
        // Charger et trier par timestamp
        final entries = <String, DateTime>{};
        
        for (final key in cacheKeys) {
          final jsonString = _prefs!.getString(key);
          if (jsonString != null) {
            try {
              final json = jsonDecode(jsonString) as Map<String, dynamic>;
              final timestamp = DateTime.parse(json['timestamp'] as String);
              entries[key] = timestamp;
            } catch (e) {
              // Supprimer les entrées corrompues
              await _prefs!.remove(key);
            }
          }
        }
        
        // Trier par ancienneté
        final sortedKeys = entries.keys.toList()
          ..sort((a, b) => entries[a]!.compareTo(entries[b]!));
        
        // Supprimer les plus anciennes
        final keysToRemove = sortedKeys.take(sortedKeys.length - CacheConstants.maxDiskCacheSize + 50);
        for (final key in keysToRemove) {
          await _prefs!.remove(key);
        }
        
        logger.d(_tag, 'Gestion taille cache disque: ${keysToRemove.length} entrées supprimées');
      }
    } catch (e) {
      logger.e(_tag, 'Erreur gestion taille cache disque: $e');
    }
  }
  
  /// Efface tout le cache
  static Future<void> clearCache() async {
    _memoryCache.clear();
    _cacheHits = 0;
    _cacheMisses = 0;
    _diskHits = 0;
    
    if (_prefs != null) {
      final keys = _prefs!.getKeys()
          .where((key) => key.startsWith(CacheConstants.cachePrefix))
          .toList();
      
      for (final key in keys) {
        await _prefs!.remove(key);
      }
    }
    
    logger.i(_tag, 'Cache complètement effacé');
  }
  
  /// Obtient les statistiques du cache
  static Map<String, dynamic> getStatistics() {
    final totalRequests = _cacheHits + _cacheMisses;
    final hitRate = totalRequests > 0 ? (_cacheHits / totalRequests * 100).toStringAsFixed(2) : '0.00';
    
    return {
      'memory_entries': _memoryCache.length,
      'cache_hits': _cacheHits,
      'disk_hits': _diskHits,
      'cache_misses': _cacheMisses,
      'hit_rate': '$hitRate%',
      'total_requests': totalRequests,
    };
  }
  
  /// Précharge des prompts courants
  static Future<void> preloadCommonPrompts(List<String> prompts) async {
    logger.i(_tag, 'Préchargement de ${prompts.length} prompts courants...');
    
    for (final prompt in prompts) {
      final cached = await getCachedResponse(prompt);
      if (cached == null) {
        // Le prompt n'est pas en cache, il sera chargé lors de la première utilisation
        logger.d(_tag, 'Prompt non trouvé en cache: ${prompt.substring(0, 30)}...');
      }
    }
  }
}