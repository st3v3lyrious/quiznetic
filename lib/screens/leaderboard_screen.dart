/*
 DOC: Screen
 Title: Leaderboard Screen
 Purpose: Displays global ranking with category+difficulty filters and user highlight.
*/
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:quiznetic_flutter/screens/upgrade_account_screen.dart';
import 'package:quiznetic_flutter/services/leaderboard_service.dart';
import 'package:quiznetic_flutter/services/score_repository.dart';
import 'package:quiznetic_flutter/services/score_submission_validator.dart';
import 'package:quiznetic_flutter/utils/app_logger.dart';

class LeaderboardScreenArgs {
  final String categoryKey;
  final String difficulty;

  LeaderboardScreenArgs({required this.categoryKey, required this.difficulty});
}

class LeaderboardScreen extends StatefulWidget {
  static const routeName = '/leaderboard';
  final LeaderboardService? leaderboardService;
  final ScoreRepository? scoreRepository;
  final bool Function()? hasFirebaseApp;

  const LeaderboardScreen({
    super.key,
    this.leaderboardService,
    this.scoreRepository,
    this.hasFirebaseApp,
  });

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
  ScoreRepository? _defaultScoreRepository;
  late final bool Function() _hasFirebaseAppChecker =
      widget.hasFirebaseApp ?? _defaultHasFirebaseApp;
  late Future<(LeaderboardSnapshot, int)> _leaderboardFuture;
  bool _didInit = false;
  String _selectedCategory = 'flag';
  String _selectedDifficulty = 'easy';
  final Set<String> _repairAttemptedScopes = <String>{};

  static bool _defaultHasFirebaseApp() {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  bool _hasFirebaseApp() {
    try {
      return _hasFirebaseAppChecker();
    } catch (e) {
      AppLogger.d('Leaderboard Firebase availability check failed: $e');
      return false;
    }
  }

  ScoreRepository get _scoreRepository {
    final injected = widget.scoreRepository;
    if (injected != null) return injected;
    return _defaultScoreRepository ??= LocalFirstScoreRepository();
  }

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
  Future<(LeaderboardSnapshot, int)> _loadLeaderboard() async {
    // Force one retry before reading leaderboard so recent local-first score
    // writes are not left stale behind retry backoff windows.
    if (_hasFirebaseApp()) {
      try {
        await _scoreRepository.syncPendingScores(forceRetry: true);
      } catch (e) {
        AppLogger.d('Leaderboard pre-load score sync failed: $e');
      }
    }
    var snapshot = await _leaderboardService.load(
      categoryKey: _selectedCategory,
      difficulty: _selectedDifficulty,
    );
    final repaired = await _attemptLeaderboardRepair(snapshot);
    if (repaired) {
      snapshot = await _leaderboardService.load(
        categoryKey: _selectedCategory,
        difficulty: _selectedDifficulty,
      );
    }

    var guestLocalBest = 0;
    if (snapshot.currentUserIsAnonymous && snapshot.currentUserRow == null) {
      try {
        guestLocalBest = await _scoreRepository.getBestScore(
          categoryKey: _selectedCategory,
          difficulty: _selectedDifficulty,
        );
      } catch (e) {
        AppLogger.d('Leaderboard guest local best fetch failed: $e');
      }
    }

    return (snapshot, guestLocalBest);
  }

  /// If current user is missing from this scope but local best exists,
  /// resubmit once to heal stale/missing leaderboard projection.
  Future<bool> _attemptLeaderboardRepair(LeaderboardSnapshot snapshot) async {
    if (!_hasFirebaseApp()) return false;
    if (snapshot.currentUserRow != null) return false;
    if (snapshot.currentUserIsAnonymous) return false;
    final currentUserUid = snapshot.currentUserUid;
    if (currentUserUid == null || currentUserUid.isEmpty) return false;

    final scopeKey = '${snapshot.categoryKey}:${snapshot.difficulty}';
    if (_repairAttemptedScopes.contains(scopeKey)) return false;

    final expectedTotal = ScoreSubmissionValidator.expectedTotalQuestions(
      snapshot.difficulty,
    );
    if (expectedTotal == null) return false;

    final localBest = await _scoreRepository.getBestScore(
      categoryKey: snapshot.categoryKey,
      difficulty: snapshot.difficulty,
    );
    if (localBest <= 0 || localBest > expectedTotal) {
      return false;
    }

    // Mark this scope as attempted only once we know a repair write is valid.
    _repairAttemptedScopes.add(scopeKey);

    final result = await _scoreRepository.saveScore(
      categoryKey: snapshot.categoryKey,
      difficulty: snapshot.difficulty,
      score: localBest,
      totalQuestions: expectedTotal,
    );

    if (result.queuedForSync) {
      AppLogger.d(
        'Leaderboard repair queued for $scopeKey; '
        'syncError=${result.syncError}',
      );
    } else {
      AppLogger.d('Leaderboard repair synced for $scopeKey.');
    }
    return result.synced || !result.queuedForSync;
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

  /// Builds the guest "not ranked" card with rank-aware messaging.
  Widget _buildGuestNotRankedCard({
    required BuildContext context,
    required int guestLocalBest,
    required LeaderboardSnapshot snapshot,
  }) {
    final IconData icon;
    final String title;
    final String subtitle;

    if (guestLocalBest <= 0) {
      icon = Icons.leaderboard_outlined;
      title = 'Play a quiz to see where you rank.';
      subtitle = 'Create an account to appear on the leaderboard.';
    } else {
      final rank = _computeHypotheticalRank(snapshot.rows, guestLocalBest);
      if (rank <= 100) {
        icon = Icons.emoji_events_outlined;
        title = 'Your score of $guestLocalBest would put you at #$rank.';
        subtitle = 'Create an account to claim your spot!';
      } else {
        icon = Icons.trending_up;
        title = 'Your score of $guestLocalBest isn\'t in the top 100 yet.';
        subtitle =
            'Create an account and keep playing to climb the ranks!';
      }
    }

    return Card(
      key: const Key('leaderboard-not-ranked-card'),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: TextButton(
          key: const Key('leaderboard-create-account-button'),
          onPressed: () =>
              Navigator.pushNamed(context, UpgradeAccountScreen.routeName),
          child: const Text('Create Account'),
        ),
      ),
    );
  }

  /// Returns the rank the guest's score would achieve among the loaded rows.
  ///
  /// Counts entries with strictly higher scores; the guest slots in after them.
  int _computeHypotheticalRank(List<LeaderboardRow> rows, int score) {
    return rows.where((r) => r.score > score).length + 1;
  }

  /// Builds the global leaderboard view with filter controls.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Leaderboard'),
        actions: [
          IconButton(
            key: const Key('leaderboard-refresh-action'),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _retry,
          ),
        ],
      ),
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
                    child: FutureBuilder<(LeaderboardSnapshot, int)>(
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

                        final (data, guestLocalBest) = snapshot.data!;
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
                            physics: const AlwaysScrollableScrollPhysics(),
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
                              else if (data.currentUserIsAnonymous)
                                _buildGuestNotRankedCard(
                                  context: context,
                                  guestLocalBest: guestLocalBest,
                                  snapshot: data,
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
