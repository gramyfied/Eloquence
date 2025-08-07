
import 'package:flutter/material.dart';

class VirelanguesMagiquesScreen extends StatefulWidget {
  const VirelanguesMagiquesScreen({{Key? key}}) : super(key: key);
  
  @override
  State<VirelanguesMagiquesScreen> createState() => 
      _VirelanguesMagiquesScreenState();
}

class _VirelanguesMagiquesScreenState 
    extends State<VirelanguesMagiquesScreen> {
  
  // Configuration de l'exercice
  final String characterName = 'Professeur Articulus';
  final String voiceType = 'echo';
  final int baseXP = 60;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Professeur Articulus - Exercice'),
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
              'Exercice: Virelangues Magiques',
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
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        