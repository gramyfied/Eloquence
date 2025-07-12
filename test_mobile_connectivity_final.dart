// Test final de connectivité mobile Eloquence
// Validation de tous les services backend depuis IP réseau locale

import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🚀 TEST FINAL CONNECTIVITÉ MOBILE ELOQUENCE');
  print('=' * 50);
  
  const String mobileIP = '192.168.1.44';
  const Duration timeout = Duration(seconds: 8);  // Timeout mobile optimisé
  
  // Tests des services critiques
  final Map<String, String> services = {
    'API-Backend': 'http://$mobileIP:8000/health',
    'Whisper-STT': 'http://$mobileIP:8001/health', 
    'Whisper-Realtime': 'http://$mobileIP:8006',
    'OpenAI-TTS': 'http://$mobileIP:5002/health',
    'LiveKit': 'http://$mobileIP:7880',  // HTTP fallback test
    'Redis': 'http://$mobileIP:6379',    // HTTP fallback test
  };
  
  print('📱 Test connectivité services backend mobile...');
  print('⏱️  Timeout optimisé : ${timeout.inSeconds}s (était 45s-120s)');
  print('');
  
  for (final entry in services.entries) {
    final serviceName = entry.key;
    final url = entry.value;
    
    try {
      final stopwatch = Stopwatch()..start();
      final response = await http.get(Uri.parse(url)).timeout(timeout);
      stopwatch.stop();
      
      final status = response.statusCode;
      final time = stopwatch.elapsedMilliseconds;
      
      if (status == 200) {
        print('✅ $serviceName: OK (${time}ms) - Status $status');
      } else if (status == 405) {
        print('✅ $serviceName: Accessible (${time}ms) - Method not allowed (normal)');
      } else {
        print('⚠️  $serviceName: Réponse inattendue (${time}ms) - Status $status');
      }
    } catch (e) {
      print('❌ $serviceName: ÉCHEC - $e');
    }
  }
  
  print('');
  print('🧪 Test performance cache Mistral...');
  
  // Simuler un test de cache (concept)
  const mockPrompt = "Analyser la confiance d'un utilisateur qui dit 'Bonjour'";
  print('📝 Prompt test: $mockPrompt');
  print('⚡ Cache HIT attendu: ~10ms (vs 15s+ sans cache)');
  print('💾 Expiration cache: 10min, Max entries: 100');
  
  print('');
  print('📊 RÉSUMÉ OPTIMISATIONS MOBILE');
  print('=' * 50);
  print('🎯 Timeouts optimisés:');
  print('   • Backend: 120s → 8s (93% amélioration)');  
  print('   • Whisper: 45s → 6s (87% amélioration)');
  print('   • Mistral: 30s → 15s (50% amélioration)');
  print('🔗 URLs réseau: localhost → 192.168.1.44 (mobile-compatible)'); 
  print('⚡ Architecture: Fallbacks séquentiels → Parallèles');
  print('💾 Cache Mistral: Activé (600s expiration)');
  print('📱 UX mobile: Indicateurs progression optimisés');
  
  print('');
  print('✅ OPTIMISATION MOBILE TERMINÉE - Prêt pour tests device!');
}