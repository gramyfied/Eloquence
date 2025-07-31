import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'app_config.dart';

/// Widget de configuration pour switcher entre serveur local et distant
class ServerConfigWidget extends StatefulWidget {
  const ServerConfigWidget({super.key});

  @override
  State<ServerConfigWidget> createState() => _ServerConfigWidgetState();
}

class _ServerConfigWidgetState extends State<ServerConfigWidget> {
  bool _useRemoteServer = AppConfig.useRemoteServer;

  @override
  Widget build(BuildContext context) {
    // Afficher seulement en mode debug
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Configuration Serveur',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Switch pour changer de serveur
            SwitchListTile(
              title: const Text('Utiliser le serveur distant'),
              subtitle: Text(
                _useRemoteServer 
                  ? 'Serveur distant: ${AppConfig.remoteServerIp}'
                  : 'Serveur local: ${AppConfig.localServerIp}',
              ),
              value: _useRemoteServer,
              onChanged: (bool value) {
                setState(() {
                  _useRemoteServer = value;
                });
                _showRestartDialog();
              },
            ),
            
            const SizedBox(height: 8),
            
            // Informations sur les URLs actuelles
            ExpansionTile(
              title: const Text('URLs des services'),
              children: [
                _buildUrlInfo('API Base', AppConfig.apiBaseUrl),
                _buildUrlInfo('LiveKit', AppConfig.livekitUrl),
                _buildUrlInfo('LiveKit Tokens', AppConfig.livekitTokenUrl),
                _buildUrlInfo('Exercices API', AppConfig.exercisesApiUrl),
                _buildUrlInfo('Vosk STT', AppConfig.voskServiceUrl),
                _buildUrlInfo('Whisper STT', AppConfig.whisperUrl),
                _buildUrlInfo('Azure TTS', AppConfig.azureTtsUrl),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrlInfo(String service, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$service:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              url,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRestartDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Redémarrage requis'),
          content: const Text(
            'Pour appliquer les changements de configuration serveur, '
            'vous devez redémarrer l\'application.\n\n'
            'Modifiez la constante "useRemoteServer" dans app_config.dart '
            'puis redémarrez l\'app.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _useRemoteServer = AppConfig.useRemoteServer;
                });
              },
              child: const Text('Compris'),
            ),
          ],
        );
      },
    );
  }
}

/// Extension pour faciliter l'affichage du widget de configuration
extension ServerConfigExtension on Widget {
  Widget withServerConfig() {
    return Column(
      children: [
        const ServerConfigWidget(),
        Expanded(child: this),
      ],
    );
  }
}
