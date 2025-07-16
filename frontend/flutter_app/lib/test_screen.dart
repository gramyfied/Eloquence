import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/navigation/navigation_state.dart';

class TestScreen extends StatelessWidget {
  const TestScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                debugPrint('=== SIMPLE TEST BUTTON CLICKED ===');
                try {
                  final navigationState = context.read<NavigationState>();
                  debugPrint('NavigationState found: $navigationState');
                  navigationState.navigateTo('/home', context);
                  debugPrint('Navigation successful');
                } catch (e) {
                  debugPrint('Navigation error: $e');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                'Test Simple Button',
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  debugPrint('=== SIMPLE INKWELL CLICKED ===');
                  try {
                    final navigationState = context.read<NavigationState>();
                    navigationState.navigateTo('/home', context);
                    debugPrint('InkWell navigation successful');
                  } catch (e) {
                    debugPrint('InkWell navigation error: $e');
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Test InkWell',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                debugPrint('=== SIMPLE GESTURE DETECTOR CLICKED ===');
                try {
                  final navigationState = context.read<NavigationState>();
                  navigationState.navigateTo('/home', context);
                  debugPrint('GestureDetector navigation successful');
                } catch (e) {
                  debugPrint('GestureDetector navigation error: $e');
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Test GestureDetector',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}