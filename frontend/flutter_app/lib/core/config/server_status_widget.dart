import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class ServerStatusWidget extends StatefulWidget {
  const ServerStatusWidget({Key? key}) : super(key: key);

  @override
  State<ServerStatusWidget> createState() => _ServerStatusWidgetState();
}

class _ServerStatusWidgetState extends State<ServerStatusWidget> {
  bool _isRemote = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServerStatus();
  }

  Future<void> _loadServerStatus() async {
    final isRemote = await ApiConfig.useRemoteServer;
    setState(() {
      _isRemote = isRemote;
      _isLoading = false;
    });
  }

  Future<void> _toggleServer() async {
    setState(() => _isLoading = true);
    
    await ApiConfig.toggleServer();
    final newStatus = await ApiConfig.useRemoteServer;
    
    setState(() {
      _isRemote = newStatus;
      _isLoading = false;
    });

    // Afficher un message de confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isRemote 
              ? '🌐 Basculé vers serveur distant (51.159.110.4)'
              : '💻 Basculé vers serveur local (localhost)',
          ),
          backgroundColor: _isRemote ? Colors.blue : Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('Chargement...'),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isRemote ? Icons.cloud : Icons.computer,
                  color: _isRemote ? Colors.blue : Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Serveur Actuel',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _isRemote ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isRemote ? Colors.blue : Colors.green,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _isRemote ? Colors.blue : Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isRemote ? 'Distant (51.159.110.4)' : 'Local (localhost)',
                    style: TextStyle(
                      color: _isRemote ? Colors.blue[700] : Colors.green[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _toggleServer,
                icon: Icon(_isRemote ? Icons.computer : Icons.cloud),
                label: Text(
                  _isRemote 
                    ? 'Basculer vers Local'
                    : 'Basculer vers Distant',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRemote ? Colors.green : Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isRemote 
                ? '• Services Vosk et Mistral disponibles\n• Analyse vocale opérationnelle'
                : '• Nécessite services locaux démarrés\n• Développement et tests',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
