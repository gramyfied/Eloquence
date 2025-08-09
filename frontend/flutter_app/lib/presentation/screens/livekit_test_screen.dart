import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../core/services/livekit_test_service.dart';
import '../../core/services/universal_livekit_audio_service.dart';

/// Écran de test pour vérifier la connectivité LiveKit
class LiveKitTestScreen extends StatefulWidget {
  const LiveKitTestScreen({super.key});

  @override
  State<LiveKitTestScreen> createState() => _LiveKitTestScreenState();
}

class _LiveKitTestScreenState extends State<LiveKitTestScreen> {
  final Logger _logger = Logger();
  final Map<String, bool> _testResults = {};
  bool _isRunningTests = false;
  bool _isConnecting = false;
  String _connectionStatus = 'Non connecté';
  
  late UniversalLiveKitAudioService _liveKitService;

  @override
  void initState() {
    super.initState();
    _liveKitService = UniversalLiveKitAudioService();
    _setupLiveKitCallbacks();
  }

  void _setupLiveKitCallbacks() {
    _liveKitService.onConnected = () {
      setState(() {
        _connectionStatus = 'Connecté';
        _isConnecting = false;
      });
      _logger.i('✅ Connexion LiveKit établie');
    };

    _liveKitService.onDisconnected = () {
      setState(() {
        _connectionStatus = 'Déconnecté';
        _isConnecting = false;
      });
      _logger.i('🔌 Déconnexion LiveKit');
    };

    _liveKitService.onErrorOccurred = (error) {
      setState(() {
        _connectionStatus = 'Erreur: $error';
        _isConnecting = false;
      });
      _logger.e('❌ Erreur LiveKit: $error');
    };
  }

  /// Exécuter tous les tests de connectivité
  Future<void> _runConnectivityTests() async {
    setState(() {
      _isRunningTests = true;
      _testResults.clear();
    });

    try {
      final results = await LiveKitTestService.runFullTest();
      
      setState(() {
        _testResults.addAll(results);
        _isRunningTests = false;
      });
      
      _logger.i('Tests terminés: $results');
      
    } catch (e) {
      _logger.e('Erreur lors des tests: $e');
      setState(() {
        _isRunningTests = false;
      });
    }
  }

  /// Test de connexion LiveKit
  Future<void> _testLiveKitConnection() async {
    setState(() {
      _isConnecting = true;
      _connectionStatus = 'Connexion en cours...';
    });

    try {
      final success = await _liveKitService.connectToExercise(
        exerciseType: 'test',
        userId: 'test_user_${DateTime.now().millisecondsSinceEpoch}',
        exerciseConfig: {'test': true},
      );

      if (success) {
        _logger.i('✅ Test de connexion LiveKit réussi');
      } else {
        _logger.e('❌ Test de connexion LiveKit échoué');
      }
      
    } catch (e) {
      _logger.e('❌ Erreur test connexion: $e');
      setState(() {
        _connectionStatus = 'Erreur: $e';
        _isConnecting = false;
      });
    }
  }

  /// Déconnexion LiveKit
  Future<void> _disconnectLiveKit() async {
    try {
      await _liveKitService.disconnect();
      _logger.i('✅ Déconnexion LiveKit réussie');
    } catch (e) {
      _logger.e('❌ Erreur déconnexion: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Test LiveKit'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section tests de connectivité
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🌐 Tests de Connectivité',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isRunningTests ? null : _runConnectivityTests,
                      child: _isRunningTests
                          ? const CircularProgressIndicator()
                          : const Text('Lancer Tests Connectivité'),
                    ),
                    const SizedBox(height: 16),
                    if (_testResults.isNotEmpty) ...[
                      Text(
                        'Résultats:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ..._testResults.entries.map((entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              entry.value ? Icons.check_circle : Icons.error,
                              color: entry.value ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(entry.key),
                            const Spacer(),
                            Text(entry.value ? 'OK' : 'ÉCHEC'),
                          ],
                        ),
                      )),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Section test connexion LiveKit
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔗 Test Connexion LiveKit',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isConnecting ? null : _testLiveKitConnection,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: _isConnecting
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Se Connecter'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _liveKitService.isConnected ? _disconnectLiveKit : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Se Déconnecter'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getStatusColor(),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getStatusIcon(),
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _connectionStatus,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Section informations
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ℹ️ Informations',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('État Connexion', _liveKitService.isConnected ? 'Connecté' : 'Déconnecté'),
                    _buildInfoRow('Publication Audio', _liveKitService.isPublishing ? 'Active' : 'Inactive'),
                    _buildInfoRow('Type Exercice', _liveKitService.currentExerciseType ?? 'Aucun'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (_isConnecting) return Colors.orange;
    if (_liveKitService.isConnected) return Colors.green;
    if (_connectionStatus.contains('Erreur')) return Colors.red;
    return Colors.grey;
  }

  IconData _getStatusIcon() {
    if (_isConnecting) return Icons.sync;
    if (_liveKitService.isConnected) return Icons.check_circle;
    if (_connectionStatus.contains('Erreur')) return Icons.error;
    return Icons.info;
  }

  @override
  void dispose() {
    _liveKitService.dispose();
    super.dispose();
  }
}
