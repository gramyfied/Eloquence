import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/eloquence_unified_theme.dart';
import '../providers/story_generator_provider.dart';
import '../../domain/entities/story_models.dart';
import '../widgets/story_card_widget.dart';

class StoryLibraryScreen extends ConsumerStatefulWidget {
  const StoryLibraryScreen({super.key});

  @override
  ConsumerState<StoryLibraryScreen> createState() => _StoryLibraryScreenState();
}

class _StoryLibraryScreenState extends ConsumerState<StoryLibraryScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  String _searchQuery = '';
  SortType _sortType = SortType.dateDesc;
  FilterType _filterType = FilterType.all;
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    // Démarrer les animations
    _slideController.forward();
    _fadeController.forward();

    // Charger les histoires
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(storyGeneratorProvider.notifier).loadUserStats();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storyGeneratorProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(theme),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: _buildBody(context, theme, state),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios,
          color: theme.colorScheme.primary,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: _showSearch ? _buildSearchField(theme) : _buildTitle(theme),
      actions: _buildAppBarActions(theme),
      bottom: _showSearch ? null : _buildTabBar(theme),
    );
  }

  Widget _buildTitle(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withOpacity(0.2),
                theme.colorScheme.secondary.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.library_books,
            color: theme.colorScheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ma Bibliothèque',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            Consumer(
              builder: (context, ref, _) {
                final state = ref.watch(storyGeneratorProvider);
                final count = _getFilteredStories(state.recentStories).length;
                return Text(
                  '$count histoire${count > 1 ? 's' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return TextField(
      controller: _searchController,
      autofocus: true,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: 'Rechercher une histoire...',
        hintStyle: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
        border: InputBorder.none,
        prefixIcon: Icon(
          Icons.search,
          color: theme.colorScheme.primary,
        ),
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
    );
  }

  List<Widget> _buildAppBarActions(ThemeData theme) {
    return [
      if (!_showSearch) ...[
        IconButton(
          icon: Icon(
            Icons.search,
            color: theme.colorScheme.primary,
          ),
          onPressed: () {
            setState(() {
              _showSearch = true;
            });
          },
        ),
        PopupMenuButton<SortType>(
          icon: Icon(
            Icons.sort,
            color: theme.colorScheme.primary,
          ),
          onSelected: (SortType type) {
            setState(() {
              _sortType = type;
            });
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: SortType.dateDesc,
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 8),
                  Text('Plus récente'),
                ],
              ),
            ),
            PopupMenuItem(
              value: SortType.dateAsc,
              child: Row(
                children: [
                  Icon(Icons.history, size: 16),
                  const SizedBox(width: 8),
                  Text('Plus ancienne'),
                ],
              ),
            ),
            PopupMenuItem(
              value: SortType.scoreDesc,
              child: Row(
                children: [
                  Icon(Icons.star, size: 16),
                  const SizedBox(width: 8),
                  Text('Meilleur score'),
                ],
              ),
            ),
            PopupMenuItem(
              value: SortType.durationDesc,
              child: Row(
                children: [
                  Icon(Icons.timer, size: 16),
                  const SizedBox(width: 8),
                  Text('Plus longue'),
                ],
              ),
            ),
          ],
        ),
      ] else ...[
        IconButton(
          icon: Icon(
            Icons.close,
            color: theme.colorScheme.primary,
          ),
          onPressed: () {
            setState(() {
              _showSearch = false;
              _searchQuery = '';
              _searchController.clear();
            });
          },
        ),
      ],
      const SizedBox(width: 8),
    ];
  }

  PreferredSizeWidget? _buildTabBar(ThemeData theme) {
    return TabBar(
      controller: TabController(length: 4, vsync: this),
      labelColor: theme.colorScheme.primary,
      unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
      indicatorColor: theme.colorScheme.primary,
      onTap: (index) {
        setState(() {
          _filterType = FilterType.values[index];
        });
      },
      tabs: const [
        Tab(text: 'Toutes'),
        Tab(text: 'Récentes'),
        Tab(text: 'Favoris'),
        Tab(text: 'Complètes'),
      ],
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, StoryGeneratorState state) {
    if (state.isLoading) {
      return _buildLoadingState(theme);
    }

    final filteredStories = _getFilteredStories(state.recentStories);

    if (filteredStories.isEmpty) {
      return _buildEmptyState(theme);
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(storyGeneratorProvider.notifier).loadUserStats();
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: filteredStories.length,
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _fadeController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, (1 - _fadeAnimation.value) * 20 * (index + 1)),
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: StoryCard(
                      story: filteredStories[index],
                      onTap: () => _openStoryDetails(filteredStories[index]),
                      onPlay: () => _playStory(filteredStories[index]),
                      onShare: () => _shareStory(filteredStories[index]),
                      onDelete: () => _deleteStory(filteredStories[index]),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Chargement de vos histoires...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.1),
                    theme.colorScheme.secondary.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getEmptyStateIcon(),
                size: 64,
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _getEmptyStateTitle(),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _getEmptyStateSubtitle(),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_filterType == FilterType.all) ...[
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.add),
                label: const Text('Créer ma première histoire'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getEmptyStateIcon() {
    switch (_filterType) {
      case FilterType.recent:
        return Icons.schedule;
      case FilterType.favorites:
        return Icons.favorite_border;
      case FilterType.completed:
        return Icons.check_circle_outline;
      default:
        return Icons.library_books;
    }
  }

  String _getEmptyStateTitle() {
    if (_searchQuery.isNotEmpty) {
      return 'Aucun résultat';
    }
    switch (_filterType) {
      case FilterType.recent:
        return 'Aucune histoire récente';
      case FilterType.favorites:
        return 'Aucun favori';
      case FilterType.completed:
        return 'Aucune histoire complète';
      default:
        return 'Votre bibliothèque est vide';
    }
  }

  String _getEmptyStateSubtitle() {
    if (_searchQuery.isNotEmpty) {
      return 'Essayez avec d\'autres mots-clés';
    }
    switch (_filterType) {
      case FilterType.recent:
        return 'Vos histoires des 7 derniers jours apparaîtront ici';
      case FilterType.favorites:
        return 'Marquez vos histoires préférées pour les retrouver ici';
      case FilterType.completed:
        return 'Les histoires avec un score élevé apparaîtront ici';
      default:
        return 'Commencez à créer des histoires pour les voir apparaître ici';
    }
  }

  List<Story> _getFilteredStories(List<Story> stories) {
    var filtered = stories.where((story) {
      // Filtre de recherche
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final titleMatch = story.title?.toLowerCase().contains(query) ?? false;
        final contentMatch = story.transcription?.toLowerCase().contains(query) ?? false;
        final elementsMatch = story.elements.any(
          (element) => element.name.toLowerCase().contains(query) ||
                      element.description.toLowerCase().contains(query),
        );
        if (!titleMatch && !contentMatch && !elementsMatch) {
          return false;
        }
      }

      // Filtre par type
      switch (_filterType) {
        case FilterType.recent:
          final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
          return story.createdAt.isAfter(sevenDaysAgo);
        case FilterType.favorites:
          return story.isFavorite ?? false;
        case FilterType.completed:
          return story.metrics.overallScore >= 80;
        default:
          return true;
      }
    }).toList();

    // Tri
    switch (_sortType) {
      case SortType.dateDesc:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortType.dateAsc:
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortType.scoreDesc:
        filtered.sort((a, b) {
          final scoreA = a.metrics.overallScore;
          final scoreB = b.metrics.overallScore;
          return scoreB.compareTo(scoreA);
        });
        break;
      case SortType.durationDesc:
        filtered.sort((a, b) {
          final durationA = a.metrics.totalDuration.inSeconds;
          final durationB = b.metrics.totalDuration.inSeconds;
          return durationB.compareTo(durationA);
        });
        break;
    }

    return filtered;
  }

  void _openStoryDetails(Story story) {
    Navigator.of(context).pushNamed(
      '/story-details',
      arguments: story,
    );
  }

  void _playStory(Story story) {
    // TODO: Implémenter la lecture
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lecture de "${story.title}" en cours de développement')),
    );
  }

  void _shareStory(Story story) {
    // TODO: Implémenter le partage
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Partage de "${story.title}" en cours de développement')),
    );
  }

  void _deleteStory(Story story) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'histoire'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${story.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implémenter la suppression
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Suppression de "${story.title}" en cours de développement')),
              );
            },
            child: const Text('Supprimer'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}

enum SortType {
  dateDesc,
  dateAsc,
  scoreDesc,
  durationDesc,
}

enum FilterType {
  all,
  recent,
  favorites,
  completed,
}