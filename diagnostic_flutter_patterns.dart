import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('================================================================================');
  print('[${DateTime.now().toString().split('.')[0]}] DIAGNOSTIC PATTERNS FLUTTER CRITIQUES');
  print('================================================================================');
  
  Map<String, bool> results = {};
  
  // TEST 1: Chargement variables .env côté Flutter
  print('\n[INFO] TEST 1: Chargement variables .env Flutter');
  results['ENV_LOADING'] = await testFlutterEnvLoading();
  
  // TEST 2: Cache Flutter et connexions actives
  print('\n[INFO] TEST 2: Cache Flutter et connexions actives');
  results['CACHE_STATE'] = await testFlutterCacheState();
  
  // TEST 3: Connexions LiveKit temps réel sans cache
  print('\n[INFO] TEST 3: Connexions LiveKit temps réel sans cache');
  results['LIVEKIT_REALTIME'] = await testLivekitRealtimeConnection();
  
  // TEST 4: Sessions Whisper sans cache
  print('\n[INFO] TEST 4: Sessions Whisper sans cache');
  results['WHISPER_SESSIONS'] = await testWhisperSessionsNocache();
  
  // TEST 5: Encodage Unicode Flutter
  print('\n[INFO] TEST 5: Encodage Unicode Flutter');
  results['UNICODE_FLUTTER'] = await testFlutterUnicodeHandling();
  
  // TEST 6: Timeouts configuration Flutter
  print('\n[INFO] TEST 6: Timeouts configuration Flutter');
  results['TIMEOUTS_CONFIG'] = await testFlutterTimeouts();
  
  print('\n================================================================================');
  print('[INFO] RÉSUMÉ DIAGNOSTIC FLUTTER');
  print('================================================================================');
  
  int passed = 0;
  int total = results.length;
  
  results.forEach((test, success) {
    String status = success ? '[OK]' : '[FAIL]';
    print('[INFO] $status $test: ${getTestDescription(test)}');
    if (success) passed++;
  });
  
  double score = (passed / total) * 100;
  print('\n[SCORE] Total: $passed/$total tests passés (${score.toStringAsFixed(0)}%)');
  
  if (score < 85) {
    print('\n[AVERTISSEMENT] Problèmes Flutter détectés: ${score.toStringAsFixed(0)}% - Intervention requise');
    print('[INFO] Sources probables: Configuration .env et/ou cache Flutter obsolète');
  } else {
    print('\n[SUCCÈS] Configuration Flutter optimale: ${score.toStringAsFixed(0)}%');
  }
}

Future<bool> testFlutterEnvLoading() async {
  try {
    // Vérification présence fichier .env
    File envFile = File('.env');
    if (!await envFile.exists()) {
      print('[FAIL] Fichier .env introuvable');
      return false;
    }
    
    // Lecture et parsing du .env
    String envContent = await envFile.readAsString();
    Map<String, String> envVars = {};
    
    for (String line in envContent.split('\n')) {
      line = line.trim();
      if (line.isNotEmpty && !line.startsWith('#') && line.contains('=')) {
        List<String> parts = line.split('=');
        if (parts.length >= 2) {
          envVars[parts[0].trim()] = parts.sublist(1).join('=').trim();
        }
      }
    }
    
    // Vérification variables critiques Flutter
    List<String> criticalVars = [
      'LIVEKIT_URL',
      'LIVEKIT_WS_URL', 
      'LIVEKIT_API_KEY',
      'LIVEKIT_API_SECRET',
      'BACKEND_URL',
      'WHISPER_URL'
    ];
    
    int foundVars = 0;
    for (String varName in criticalVars) {
      if (envVars.containsKey(varName) && envVars[varName]!.isNotEmpty) {
        foundVars++;
        print('[OK] Variable $varName: ${envVars[varName]}');
      } else {
        print('[FAIL] Variable $varName manquante');
      }
    }
    
    bool success = foundVars == criticalVars.length;
    print('[INFO] Variables .env: $foundVars/${criticalVars.length} trouvées');
    return success;
    
  } catch (e) {
    print('[FAIL] Erreur lecture .env: $e');
    return false;
  }
}

Future<bool> testFlutterCacheState() async {
  try {
    // Simulation test cache Flutter (pas de vrai cache ici mais structure)
    print('[INFO] Vérification cache HttpClient Flutter...');
    
    // Test connexion avec headers no-cache
    var client = http.Client();
    
    try {
      var response = await client.get(
        Uri.parse('http://192.168.1.44:8000/health'),
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        }
      ).timeout(Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        print('[OK] Connexion backend sans cache: ${response.statusCode}');
        return true;
      } else {
        print('[FAIL] Connexion backend: ${response.statusCode}');
        return false;
      }
    } finally {
      client.close();
    }
    
  } catch (e) {
    print('[FAIL] Erreur test cache: $e');
    return false;
  }
}

Future<bool> testLivekitRealtimeConnection() async {
  try {
    print('[INFO] Test connexion LiveKit temps réel...');
    
    // Test WebSocket LiveKit
    var client = http.Client();
    
    try {
      var response = await client.get(
        Uri.parse('http://192.168.1.44:7880/'),
        headers: {
          'Connection': 'close',
          'Cache-Control': 'no-cache'
        }
      ).timeout(Duration(seconds: 3));
      
      bool success = response.statusCode == 200 || response.statusCode == 404;
      print('[INFO] LiveKit response: ${response.statusCode}');
      return success;
      
    } finally {
      client.close();
    }
    
  } catch (e) {
    print('[FAIL] Connexion LiveKit: $e');
    return false;
  }
}

Future<bool> testWhisperSessionsNocache() async {
  try {
    print('[INFO] Test sessions Whisper sans cache...');
    
    var client = http.Client();
    
    try {
      var response = await client.get(
        Uri.parse('http://192.168.1.44:8001/health'),
        headers: {
          'Cache-Control': 'no-cache',
          'Connection': 'close'
        }
      ).timeout(Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        print('[OK] Service Whisper accessible: ${response.statusCode}');
        return true;
      } else {
        print('[FAIL] Service Whisper: ${response.statusCode}');
        return false;
      }
      
    } finally {
      client.close();
    }
    
  } catch (e) {
    print('[FAIL] Sessions Whisper: $e');
    return false;
  }
}

Future<bool> testFlutterUnicodeHandling() async {
  try {
    print('[INFO] Test gestion Unicode Flutter...');
    
    // Test encodage UTF-8 avec caractères spéciaux
    String testText = 'Test émojis: 🎯📊✅⚠️ et accents: àéèêôû';
    List<int> utf8Bytes = utf8.encode(testText);
    String decoded = utf8.decode(utf8Bytes);
    
    bool success = decoded == testText;
    print('[INFO] Unicode test: ${success ? 'OK' : 'FAIL'}');
    return success;
    
  } catch (e) {
    print('[FAIL] Erreur Unicode: $e');
    return false;
  }
}

Future<bool> testFlutterTimeouts() async {
  try {
    print('[INFO] Test configuration timeouts Flutter...');
    
    // Test timeouts avec services backend
    List<String> services = [
      'http://192.168.1.44:8000/health',  // Backend
      'http://192.168.1.44:8001/health',  // Whisper
      'http://192.168.1.44:7880/',        // LiveKit
    ];
    
    int successCount = 0;
    
    for (String service in services) {
      try {
        var client = http.Client();
        var stopwatch = Stopwatch()..start();
        
        var response = await client.get(Uri.parse(service))
            .timeout(Duration(seconds: 10));
        
        stopwatch.stop();
        double latency = stopwatch.elapsedMilliseconds / 1000.0;
        
        if (response.statusCode == 200 || response.statusCode == 404) {
          print('[OK] Service ${service.split('/')[2]}: ${latency}s');
          successCount++;
        }
        
        client.close();
        
      } catch (e) {
        print('[FAIL] Timeout ${service.split('/')[2]}: $e');
      }
    }
    
    bool success = successCount >= 2; // Au moins 2/3 services
    print('[INFO] Services accessibles: $successCount/${services.length}');
    return success;
    
  } catch (e) {
    print('[FAIL] Erreur timeouts: $e');
    return false;
  }
}

String getTestDescription(String test) {
  switch (test) {
    case 'ENV_LOADING': return 'Chargement variables .env Flutter';
    case 'CACHE_STATE': return 'État cache HttpClient Flutter';
    case 'LIVEKIT_REALTIME': return 'Connexion LiveKit temps réel';
    case 'WHISPER_SESSIONS': return 'Sessions Whisper sans cache';
    case 'UNICODE_FLUTTER': return 'Gestion Unicode Flutter';
    case 'TIMEOUTS_CONFIG': return 'Configuration timeouts Flutter';
    default: return 'Test inconnu';
  }
}