import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/navigation/navigation_state.dart';
import '../../../features/confidence_boost/presentation/screens/confidence_boost_entry.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Définir une liste statique d'exercices pour l'affichage
    final exercises = [
      {
        'title': 'Confiance Express',
        'description': 'Boostez votre confiance en 1 minute.',
        'icon': Icons.star,
        'color': Colors.amber,
        'onTap': () => context.read<NavigationState>().navigateTo('/confidence-boost', context, 'user123'), // Utilisateur par défaut pour la démo
      },
      {
        'title': 'Roulette des Virelangues',
        'description': 'Exercice gamifié avec collection de gemmes magiques.',
        'icon': Icons.casino,
        'color': Colors.deepPurple,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConfidenceBoostEntry.virelangueRoulette(),
          ),
        ),
      },
      {
        'title': 'Exercice 1',
        'description': 'Description courte de l\'exercice 1',
        'icon': Icons.record_voice_over,
        'color': Colors.blue,
        'onTap': () => context.read<NavigationState>().navigateTo('/exercise_detail', context, '0'),
      },
      {
        'title': 'Exercice 2',
        'description': 'Description courte de l\'exercice 2',
        'icon': Icons.speed,
        'color': Colors.green,
        'onTap': () => context.read<NavigationState>().navigateTo('/exercise_detail', context, '1'),
      },
      {
        'title': 'Exercice 3',
        'description': 'Description courte de l\'exercice 3',
        'icon': Icons.waves,
        'color': Colors.orange,
        'onTap': () => context.read<NavigationState>().navigateTo('/exercise_detail', context, '2'),
      },
      {
        'title': 'Exercice 4',
        'description': 'Description courte de l\'exercice 4',
        'icon': Icons.chat,
        'color': Colors.purple,
        'onTap': () => context.read<NavigationState>().navigateTo('/exercise_detail', context, '3'),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eloquence'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.read<NavigationState>().navigateTo('/profile', context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section de bienvenue
            const Text(
              'Bienvenue dans votre coach vocal',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Améliorez votre expression orale avec nos exercices personnalisés',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            
            // Section des exercices recommandés
            _buildSectionHeader(
              'Exercices recommandés',
              onSeeAll: () => context.read<NavigationState>().navigateTo('/exercises', context),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  final exercise = exercises[index];
                  return _buildExerciseCard(
                    context,
                    title: exercise['title'] as String,
                    description: exercise['description'] as String,
                    icon: exercise['icon'] as IconData,
                    color: exercise['color'] as Color,
                    onTap: exercise['onTap'] as VoidCallback,
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            
            // Section des statistiques
            _buildSectionHeader('Vos statistiques'),
            const SizedBox(height: 16),
            _buildStatsCard(),
            const SizedBox(height: 24),
            
            // Section des dernières activités
            _buildSectionHeader('Dernières activités'),
            const SizedBox(height: 16),
            _buildActivityList(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Exercices',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mic),
            label: 'Pratiquer',
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            context.read<NavigationState>().navigateTo('/exercises', context);
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Lancer une session de pratique
        },
        child: const Icon(Icons.mic),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: const Text('Voir tout'),
          ),
      ],
    );
  }

  Widget _buildExerciseCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(77)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            const Row(
              children: [
                Icon(
                  Icons.timer,
                  size: 14,
                  color: Colors.black54,
                ),
                SizedBox(width: 4),
                Text(
                  '1 min', // Durée fixe pour la démo
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  value: '12',
                  label: 'Exercices\nterminés',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                _StatItem(
                  value: '3h 45m',
                  label: 'Temps\ntotal',
                  icon: Icons.timer,
                  color: Colors.blue,
                ),
                _StatItem(
                  value: '85%',
                  label: 'Score\nmoyen',
                  icon: Icons.star,
                  color: Colors.amber,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Progression hebdomadaire',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Afficher les statistiques détaillées
                  },
                  child: const Text('Détails'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Simuler un graphique de progression
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
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

  Widget _buildActivityList() {
    final List<Map<String, dynamic>> activities = [
      {
        'title': 'Exercice de prononciation terminé',
        'time': 'Il y a 2 heures',
        'icon': Icons.record_voice_over,
        'color': Colors.blue,
      },
      {
        'title': 'Exercice de fluidité commencé',
        'time': 'Hier',
        'icon': Icons.speed,
        'color': Colors.green,
      },
      {
        'title': 'Nouvel objectif défini',
        'time': 'Il y a 2 jours',
        'icon': Icons.flag,
        'color': Colors.orange,
      },
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: activities.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final activity = activities[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: activity['color'].withAlpha(51),
              child: Icon(
                activity['icon'],
                color: activity['color'],
              ),
            ),
            title: Text(activity['title']),
            subtitle: Text(activity['time']),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Afficher les détails de l'activité
            },
          );
        },
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
