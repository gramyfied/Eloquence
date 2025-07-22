import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import '../core/theme/eloquence_unified_theme.dart';
import 'providers/router_provider.dart';

class App extends ConsumerWidget {
  static final _log = Logger('App');
  
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _log.info('🚀 Building Eloquence App with GoRouter selon les meilleures pratiques');
    
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'Eloquence',
      theme: EloquenceTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
