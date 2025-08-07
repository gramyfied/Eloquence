
import 'package:flutter/material.dart';

class MarcheObjetsScreen extends StatefulWidget {
  const MarcheObjetsScreen({{Key? key}}) : super(key: key);
  
  @override
  State<MarcheObjetsScreen> createState() => 
      _MarcheObjetsScreenState();
}

class _MarcheObjetsScreenState 
    extends State<MarcheObjetsScreen> {
  
  // Configuration de l'exercice
  final String characterName = 'Client Mystérieux';
  final String voiceType = 'alloy';
  final int baseXP = 90;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Client Mystérieux - Exercice'),
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
              'Exercice: Marche Objets',
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
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        