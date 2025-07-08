import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ExercisesListScreen extends StatelessWidget {
  const ExercisesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Définir une liste statique d'exercices pour l'affichage
    final exercises = [
      {
        'title': 'Confiance Express',
        'description': 'Boostez votre confiance en vous avec cet exercice rapide et efficace. Idéal pour commencer la journée.',
        'icon': Icons.star,
        'color': Colors.amber,
        'onTap': () => context.go('/confidence-boost'),
      },
      {
        'title': 'Maîtrise du Débit',
        'description': 'Apprenez à contrôler votre vitesse de parole pour captiver votre audience.',
        'icon': Icons.speed,
        'color': Colors.blue,
        'onTap': () => context.go('/exercises/0'), // Route factice pour l'exemple
      },
      {
        'title': 'Clarté de l\'Articulation',
        'description': 'Exercez-vous à prononcer chaque syllabe clairement pour une meilleure compréhension.',
        'icon': Icons.record_voice_over,
        'color': Colors.green,
        'onTap': () => context.go('/exercises/1'), // Route factice pour l'exemple
      },
      {
        'title': 'Gestion des Tics de Langage',
        'description': 'Identifiez et réduisez les "euh", "alors", et autres tics pour un discours plus fluide.',
        'icon': Icons.chat_bubble_outline,
        'color': Colors.purple,
        'onTap': () => context.go('/exercises/2'), // Route factice pour l'exemple
      },
      {
        'title': 'Puissance de la Voix',
        'description': 'Travaillez sur la projection et la modulation de votre voix pour plus d\'impact.',
        'icon': Icons.waves,
        'color': Colors.red,
        'onTap': () => context.go('/exercises/3'), // Route factice pour l'exemple
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tous les exercices'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          final exercise = exercises[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16.0),
              leading: CircleAvatar(
                backgroundColor: (exercise['color'] as Color).withAlpha(51),
                child: Icon(
                  exercise['icon'] as IconData,
                  color: exercise['color'] as Color,
                ),
              ),
              title: Text(
                exercise['title'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(exercise['description'] as String),
              trailing: const Icon(Icons.chevron_right),
              onTap: exercise['onTap'] as VoidCallback,
            ),
          );
        },
      ),
    );
  }
}