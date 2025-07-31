import 'package:flutter/material.dart';
import 'api_config.dart';

/// Widget pour basculer entre serveur local et distant
class ServerToggleWidget extends StatefulWidget {
  final Function(bool)? onServerChanged;
  
  const ServerToggleWidget({
    Key? key,
    this.onServerChanged,
  }) : super(key: key);

  @override
  State<ServerToggleWidget> createState() => _ServerToggleWidgetState();
}

class _ServerToggleWidgetState extends State<ServerToggleWidget> {
  bool _isRemoteServer = true;
  bool _isLoading = true;
  String _serverLabel = '';
  String _serverDescription = '';

  @override
  void initState() {
    super.initState();
    _loadServerConfig();
  }

  Future<void> _loadServerConfig() async {
    try {
      final isRemote = await ApiConfig.useRemoteServer;
      final label = await ApiConfig.currentServerLabel;
      final description = await ApiConfig.currentServerDescription;
      
      if (mounted) {
        setState(() {
          _isRemoteServer = isRemote;
          _serverLabel = label;
          _serverDescription = description;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement de la config serveur: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleServer() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ApiConfig.setUseRemoteServer(!_isRemoteServer);
      await _loadServerConfig();
      
      if (widget.onServerChanged != null) {
        widget.onServerChanged!(!_isRemoteServer);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Basculé vers: $_serverLabel'),
            backgroundColor: _isRemoteServer ? Colors.blue : Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur lors du basculement serveur: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors du changement de serveur'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Chargement de la configuration...'),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isRemoteServer ? Icons.cloud : Icons.computer,
                  color: _isRemoteServer ? Colors.blue : Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _serverLabel,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _isRemoteServer ? Colors.blue : Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _serverDescription,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isRemoteServer,
                  onChanged: (_) => _toggleServer(),
                  activeColor: Colors.blue,
                  inactiveThumbColor: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: (_isRemoteServer ? Colors.blue : Colors.green).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (_isRemoteServer ? Colors.blue : Colors.green).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isRemoteServer ? Icons.info_outline : Icons.developer_mode,
                    size: 16,
                    color: _isRemoteServer ? Colors.blue : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isRemoteServer 
                          ? 'Mode Production - Serveur distant actif'
                          : 'Mode Développement - Serveur local actif',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isRemoteServer ? Colors.blue[700] : Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget compact pour la barre d'outils
class CompactServerToggle extends StatefulWidget {
  final Function(bool)? onServerChanged;
  
  const CompactServerToggle({
    Key? key,
    this.onServerChanged,
  }) : super(key: key);

  @override
  State<CompactServerToggle> createState() => _CompactServerToggleState();
}

class _CompactServerToggleState extends State<CompactServerToggle> {
  bool _isRemoteServer = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServerConfig();
  }

  Future<void> _loadServerConfig() async {
    try {
      final isRemote = await ApiConfig.useRemoteServer;
      if (mounted) {
        setState(() {
          _isRemoteServer = isRemote;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement de la config serveur: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleServer() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ApiConfig.setUseRemoteServer(!_isRemoteServer);
      await _loadServerConfig();
      
      if (widget.onServerChanged != null) {
        widget.onServerChanged!(!_isRemoteServer);
      }
    } catch (e) {
      debugPrint('Erreur lors du basculement serveur: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Tooltip(
      message: _isRemoteServer ? 'Serveur Distant (Cliquer pour Local)' : 'Serveur Local (Cliquer pour Distant)',
      child: InkWell(
        onTap: _toggleServer,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (_isRemoteServer ? Colors.blue : Colors.green).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isRemoteServer ? Colors.blue : Colors.green,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isRemoteServer ? Icons.cloud : Icons.computer,
                size: 16,
                color: _isRemoteServer ? Colors.blue : Colors.green,
              ),
              const SizedBox(width: 6),
              Text(
                _isRemoteServer ? 'Distant' : 'Local',
                style: TextStyle(
                  fontSize: 12,
                  color: _isRemoteServer ? Colors.blue : Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
