/*
 DOC: Screen
 Title: Leaderboard Screen
 Purpose: Displays global ranking with category+difficulty filters and user highlight.
*/
import 'package:flutter/material.dart';
import 'package:quiznetic_flutter/services/leaderboard_service.dart';

class LeaderboardScreenArgs {
  final String categoryKey;
  final String difficulty;

  LeaderboardScreenArgs({required this.categoryKey, required this.difficulty});
}

class LeaderboardScreen extends StatefulWidget {
  static const routeName = '/leaderboard';
  final LeaderboardService? leaderboardService;

  const LeaderboardScreen({super.key, this.leaderboardService});

  /// Creates state that handles filters and data refresh.
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  static const _categoryLabels = {
    'flag': 'Flag Quiz',
    'capital': 'Capital Quiz',
  };
  static const _difficultyLabels = {
    'easy': 'Easy',
    'intermediate': 'Intermediate',
    'expert': 'Expert',
  };

  late final LeaderboardService _leaderboardService =
      widget.leaderboardService ?? LeaderboardService();
  late Future<LeaderboardSnapshot> _leaderboardFuture;
  bool _didInit = false;
  String _selectedCategory = 'flag';
  String _selectedDifficulty = 'easy';

  /// Initializes filter defaults from optional route args.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is LeaderboardScreenArgs) {
      if (_categoryLabels.containsKey(args.categoryKey)) {
        _selectedCategory = args.categoryKey;
      }
      if (_difficultyLabels.containsKey(args.difficulty)) {
        _selectedDifficulty = args.difficulty;
      }
    }
    _leaderboardFuture = _loadLeaderboard();
  }

  /// Loads one leaderboard snapshot for the selected filters.
  Future<LeaderboardSnapshot> _loadLeaderboard() {
    return _leaderboardService.load(
      categoryKey: _selectedCategory,
      difficulty: _selectedDifficulty,
    );
  }

  /// Updates category filter and reloads the board.
  void _onCategoryChanged(String? value) {
    if (value == null || value == _selectedCategory) return;
    setState(() {
      _selectedCategory = value;
      _leaderboardFuture = _loadLeaderboard();
    });
  }

  /// Updates difficulty filter and reloads the board.
  void _onDifficultyChanged(String? value) {
    if (value == null || value == _selectedDifficulty) return;
    setState(() {
      _selectedDifficulty = value;
      _leaderboardFuture = _loadLeaderboard();
    });
  }

  /// Retries loading leaderboard data for the current filters.
  void _retry() {
    setState(() {
      _leaderboardFuture = _loadLeaderboard();
    });
  }

  /// Returns display name for one leaderboard entry.
  String _entryDisplayName(LeaderboardRow row) {
    final normalized = row.entry.displayName?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      return normalized;
    }
    return 'Player ${row.uid.substring(0, row.uid.length < 4 ? row.uid.length : 4)}';
  }

  /// Builds a reusable centered status panel.
  Widget _buildStatusState({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required Key actionKey,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(
              key: actionKey,
              onPressed: _retry,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds one leaderboard row tile with optional current-user highlight.
  Widget _buildLeaderboardRow({
    required BuildContext context,
    required LeaderboardSnapshot snapshot,
    required LeaderboardRow row,
  }) {
    final isCurrentUser =
        snapshot.currentUserUid != null && row.uid == snapshot.currentUserUid;
    final cs = Theme.of(context).colorScheme;

    return Card(
      key: Key('leaderboard-row-${row.rank}'),
      color: isCurrentUser ? cs.primaryContainer : null,
      child: ListTile(
        leading: CircleAvatar(child: Text('${row.rank}')),
        title: Row(
          children: [
            Expanded(
              child: Text(
                _entryDisplayName(row),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (row.entry.isAnonymous)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Chip(label: Text('Guest')),
              ),
          ],
        ),
        subtitle: isCurrentUser ? const Text('You') : null,
        trailing: Text(
          '${row.score}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  /// Builds the global leaderboard view with filter controls.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Global Leaderboard')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          SizedBox(
                            width: 260,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Category',
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  key: const Key('leaderboard-category-filter'),
                                  value: _selectedCategory,
                                  isExpanded: true,
                                  items: _categoryLabels.entries
                                      .map(
                                        (entry) => DropdownMenuItem(
                                          value: entry.key,
                                          child: Text(
                                            entry.value,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: _onCategoryChanged,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 260,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Difficulty',
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  key: const Key(
                                    'leaderboard-difficulty-filter',
                                  ),
                                  value: _selectedDifficulty,
                                  isExpanded: true,
                                  items: _difficultyLabels.entries
                                      .map(
                                        (entry) => DropdownMenuItem(
                                          value: entry.key,
                                          child: Text(
                                            entry.value,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: _onDifficultyChanged,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: FutureBuilder<LeaderboardSnapshot>(
                      future: _leaderboardFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return _buildStatusState(
                            icon: Icons.cloud_off,
                            title: 'Could not load leaderboard',
                            message: 'Check your connection and try again.',
                            actionLabel: 'Retry',
                            actionKey: const Key(
                              'leaderboard-error-retry-button',
                            ),
                          );
                        }

                        final data = snapshot.data!;
                        if (data.rows.isEmpty) {
                          return _buildStatusState(
                            icon: Icons.leaderboard_outlined,
                            title: 'No leaderboard entries yet',
                            message: 'Complete a quiz to post the first score.',
                            actionLabel: 'Refresh',
                            actionKey: const Key(
                              'leaderboard-empty-refresh-button',
                            ),
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: () async {
                            _retry();
                            await _leaderboardFuture;
                          },
                          child: ListView(
                            padding: const EdgeInsets.only(bottom: 24),
                            children: [
                              Card(
                                key: const Key('leaderboard-scope-summary'),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Showing top ${data.rows.length}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${_categoryLabels[data.categoryKey]} - '
                                        '${_difficultyLabels[data.difficulty]}',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (data.currentUserRow != null)
                                Card(
                                  key: const Key('leaderboard-your-rank-card'),
                                  child: ListTile(
                                    leading: const Icon(Icons.person),
                                    title: Text(
                                      'Your rank: #${data.currentUserRow!.rank}',
                                    ),
                                    subtitle: Text(
                                      'Score: ${data.currentUserRow!.score}',
                                    ),
                                  ),
                                )
                              else
                                const Card(
                                  key: Key('leaderboard-not-ranked-card'),
                                  child: ListTile(
                                    leading: Icon(Icons.info_outline),
                                    title: Text(
                                      'You are not ranked in this top list yet.',
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              ...data.rows.map(
                                (row) => _buildLeaderboardRow(
                                  context: context,
                                  snapshot: data,
                                  row: row,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
