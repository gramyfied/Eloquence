import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eloquence_2_0/presentation/theme/eloquence_design_system.dart';
import 'providers/router_provider.dart';

class EloquenceApp extends ConsumerWidget {
  const EloquenceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'Eloquence',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: EloquenceColors.navy,
        fontFamily: 'Montserrat',
        textTheme: const TextTheme(
          headlineLarge: EloquenceTextStyles.headline1,
          headlineMedium: EloquenceTextStyles.headline2,
          bodyLarge: EloquenceTextStyles.body1,
          bodyMedium: EloquenceTextStyles.body1,
          labelSmall: EloquenceTextStyles.caption,
        ),
      ),
      routerConfig: router,
    );
  }
}
