
import 'package:flutter/material.dart';

class SouffleDragonScreen extends StatefulWidget {
  const SouffleDragonScreen({{Key? key}}) : super(key: key);
  
  @override
  State<SouffleDragonScreen> createState() => 
      _SouffleDragonScreenState();
}

class _SouffleDragonScreenState 
    extends State<SouffleDragonScreen> {
  
  // Configuration de l'exercice
  final String characterName = 'Maître Draconius';
  final String voiceType = 'onyx';
  final int baseXP = 80;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Maître Draconius - Exercice'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar du personnage
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.purple,
              child: Icon(
                Icons.person,
                size: 50,
                color: Colors.white,
              ),
            ),
            
            SizedBox(height: 20),
            
            // Nom du personnage
            Text(
              characterName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            SizedBox(height: 10),
            
            // Type d'exercice
            Text(
              'Exercice: Souffle Dragon',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            
            SizedBox(height: 30),
            
            // Bouton de démarrage
            ElevatedButton.icon(
              onPressed: () => _startExercise(),
              icon: Icon(Icons.play_arrow),
              label: Text('Commencer l\'exercice'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Indicateur XP
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: Colors.amber),
                  SizedBox(width: 5),
                  Text('XP de base: $baseXP'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _startExercise() {
    // Logique de démarrage de l'exercice
    print('Démarrage de l\'exercice $characterName');
  }
}
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        