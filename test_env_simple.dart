import 'dart:io';

Future<void> main() async {
  print('🔍 TEST CONTENU FICHIER .env');
  print('=' * 50);
  
  try {
    // Lire le fichier .env directement
    final file = File('.env');
    if (!await file.exists()) {
      print('❌ ERREUR: Fichier .env introuvable');
      return;
    }
    
    final content = await file.readAsString();
    final lines = content.split('\n');
    
    print('✅ Fichier .env trouvé (${lines.length} lignes)');
    
    // Extraire les variables critiques
    final criticalVars = <String, String?>{};
    for (final line in lines) {
      if (line.trim().isEmpty || line.startsWith('#')) continue;
      
      final parts = line.split('=');
      if (parts.length >= 2) {
        final key = parts[0].trim();
        final value = parts.sublist(1).join('=').trim();
        
        if ([
          'LLM_SERVICE_URL',
          'STT_SERVICE_URL', 
          'WHISPER_STT_URL',
          'MOBILE_MODE',
          'ENVIRONMENT',
          'HYBRID_EVALUATION_URL'
        ].contains(key)) {
          criticalVars[key] = value;
        }
      }
    }
    
    print('\n🎯 VARIABLES CRITIQUES TROUVÉES:');
    criticalVars.forEach((key, value) {
      final status = value != null ? '✅' : '❌';
      print('  $status $key: ${value ?? "NON TROUVÉE"}');
    });
    
    // Compter URLs réseau vs localhost
    int networkUrls = 0;
    int localhostUrls = 0;
    
    for (final line in lines) {
      if (line.contains('192.168.1.44')) networkUrls++;
      if (line.contains('localhost') || line.contains('127.0.0.1')) {
        if (!line.startsWith('#')) localhostUrls++;
      }
    }
    
    print('\n🌐 ANALYSE URL:');
    print('  📍 URLs réseau (192.168.1.44): $networkUrls');
    print('  🏠 URLs localhost actives: $localhostUrls');
    
    // Rechercher les URLs spécifiques
    final llmUrl = criticalVars['LLM_SERVICE_URL'];
    final whisperUrl = criticalVars['WHISPER_STT_URL'];
    final hybridUrl = criticalVars['HYBRID_EVALUATION_URL'];
    
    print('\n🔍 URLS CLÉS:');
    print('  LLM_SERVICE_URL: $llmUrl');
    print('  WHISPER_STT_URL: $whisperUrl');
    print('  HYBRID_EVALUATION_URL: $hybridUrl');
    
    // Diagnostic final
    final hasCorrectLlm = llmUrl?.contains('192.168.1.44:8000') == true;
    final hasNetworkConfig = networkUrls > 5;
    final mobileMode = criticalVars['MOBILE_MODE'];
    
    print('\n🎯 DIAGNOSTIC FINAL:');
    print('  ${hasCorrectLlm ? "✅" : "❌"} LLM_SERVICE_URL configurée pour mobile');
    print('  ${hasNetworkConfig ? "✅" : "❌"} Configuration réseau activée');
    print('  ${mobileMode == 'true' ? "✅" : "❌"} MOBILE_MODE activé');
    
    if (hasCorrectLlm && hasNetworkConfig) {
      print('\n🚀 RÉSULTAT: Configuration mobile CORRECTE');
    } else {
      print('\n⚠️  RÉSULTAT: Configuration mobile INCORRECTE');
    }
    
  } catch (e) {
    print('❌ ERREUR: $e');
  }
}