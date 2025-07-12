#!/usr/bin/env dart
// =================================================
// 🪲 DIAGNOSTIC BACKEND PROBLEMS - ELOQUENCE
// =================================================
// Validation des problèmes identifiés avec logs détaillés

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  print('🪲 === DIAGNOSTIC BACKEND PROBLEMS ===\n');
  
  // Test 1: Configuration réseau mobile
  await testMobileNetworkConfiguration();
  
  // Test 2: Stabilité backend gunicorn
  await testBackendStability();
  
  // Test 3: Comparaison localhost vs IP réseau
  await testLocalhostVsNetworkIP();
  
  print('\n✅ Diagnostic terminé');
}

/// Test 1: Validation configuration réseau mobile
Future<void> testMobileNetworkConfiguration() async {
  print('📱 === TEST 1: CONFIGURATION RÉSEAU MOBILE ===');
  
  // URLs à tester
  final urls = [
    'http://localhost:8000/health',           // ❌ Problématique mobile
    'http://192.168.1.44:8000/health',       // ✅ IP réseau
    'http://127.0.0.1:8000/health',          // ❌ Problématique mobile
  ];
  
  for (final url in urls) {
    print('\n🔍 Test connectivité: $url');
    
    try {
      final stopwatch = Stopwatch()..start();
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'EloquenceMobileDiagnostic/1.0'},
      ).timeout(Duration(seconds: 5));
      
      stopwatch.stop();
      
      print('  ✅ SUCCESS: ${response.statusCode} (${stopwatch.elapsedMilliseconds}ms)');
      print('  📊 Headers: ${response.headers}');
      
    } on SocketException catch (e) {
      print('  ❌ SOCKET ERROR: ${e.message}');
      print('  🔬 errno: ${e.osError?.errorCode}');
      
    } on HttpException catch (e) {
      print('  ❌ HTTP ERROR: ${e.message}');
      
    } catch (e) {
      print('  ❌ GENERAL ERROR: $e');
    }
  }
}

/// Test 2: Analyse stabilité backend gunicorn
Future<void> testBackendStability() async {
  print('\n🔧 === TEST 2: STABILITÉ BACKEND GUNICORN ===');
  
  final baseUrl = 'http://192.168.1.44:8000';
  
  // Test santé basique
  await testEndpoint('$baseUrl/health', 'Health Check');
  
  // Test charge simulée (5 requêtes parallèles)
  print('\n⚡ Test charge simulée (5 requêtes parallèles)...');
  
  final futures = List.generate(5, (i) async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'User-Agent': 'LoadTest-$i'},
      ).timeout(Duration(seconds: 10));
      
      stopwatch.stop();
      return 'Thread-$i: ✅ ${response.statusCode} (${stopwatch.elapsedMilliseconds}ms)';
      
    } catch (e) {
      stopwatch.stop();
      return 'Thread-$i: ❌ $e (${stopwatch.elapsedMilliseconds}ms)';
    }
  });
  
  final results = await Future.wait(futures);
  for (final result in results) {
    print('  $result');
  }
}

/// Test 3: Comparaison localhost vs IP réseau
Future<void> testLocalhostVsNetworkIP() async {
  print('\n🌐 === TEST 3: LOCALHOST VS IP RÉSEAU ===');
  
  final endpoints = [
    {'name': 'localhost', 'url': 'http://localhost:8000'},
    {'name': 'IP réseau', 'url': 'http://192.168.1.44:8000'},
    {'name': '127.0.0.1', 'url': 'http://127.0.0.1:8000'},
  ];
  
  for (final endpoint in endpoints) {
    final name = endpoint['name']!;
    final url = endpoint['url']!;
    
    print('\n🔍 Test $name: $url');
    
    // DNS resolution check
    try {
      final uri = Uri.parse(url);
      final addresses = await InternetAddress.lookup(uri.host);
      print('  🌐 DNS résolution: ${addresses.map((a) => a.address).join(', ')}');
      
      // Network connectivity check
      final socket = await Socket.connect(uri.host, uri.port, timeout: Duration(seconds: 3));
      socket.destroy();
      print('  🔌 Socket connexion: ✅ Succès');
      
    } catch (e) {
      print('  🔌 Socket connexion: ❌ $e');
      continue;
    }
    
    // HTTP health check
    await testEndpoint('$url/health', 'Health Check ($name)');
  }
}

/// Fonction helper pour tester un endpoint
Future<void> testEndpoint(String url, String description) async {
  print('\n🏥 $description: $url');
  
  try {
    final stopwatch = Stopwatch()..start();
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'User-Agent': 'EloquenceDiagnostic/1.0',
        'Accept': 'application/json',
      },
    ).timeout(Duration(seconds: 8));
    
    stopwatch.stop();
    
    print('  ✅ Status: ${response.statusCode}');
    print('  ⏱️  Latence: ${stopwatch.elapsedMilliseconds}ms');
    print('  📏 Taille: ${response.contentLength ?? response.body.length} bytes');
    
    // Parse response si JSON
    try {
      final data = jsonDecode(response.body);
      print('  📋 Données: ${data.toString().substring(0, min(100, data.toString().length))}...');
    } catch (e) {
      print('  📋 Body: ${response.body.substring(0, min(100, response.body.length))}...');
    }
    
  } catch (e) {
    print('  ❌ ERREUR: $e');
  }
}

int min(int a, int b) => a < b ? a : b;