import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import '../core/theme/eloquence_unified_theme.dart';
import 'providers/router_provider.dart';
import '../core/config/app_config.dart';

class App extends ConsumerWidget {
  static final _log = Logger('App');
  
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _log.info('🚀 Building Eloquence App with GoRouter selon les meilleures pratiques');
    
    final router = ref.watch(routerProvider);

    // Widget pour afficher l'URL backend au démarrage
    return MaterialApp.router(
      title: 'Eloquence',
      theme: EloquenceTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final url = AppConfig.apiBaseUrl;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('LLM_SERVICE_URL utilisée : $url'),
              duration: Duration(seconds: 8),
            ),
          );
        });
        return child!;
      },
    );
  }
}
