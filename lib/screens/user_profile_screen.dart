/*
 DOC: Screen
 Title: User Profile Screen
 Purpose: Displays user profile, saved high-score records, and guest conversion CTA.
*/
// lib/screens/user_profile_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quiznetic_flutter/screens/upgrade_account_screen.dart';
import 'package:quiznetic_flutter/services/auth_service.dart';
import 'package:quiznetic_flutter/services/leaderboard_band_service.dart';
import 'package:quiznetic_flutter/services/score_repository.dart';
import '../services/score_service.dart';
import 'package:quiznetic_flutter/utils/helpers.dart';

class UserProfileScreen extends StatefulWidget {
  static const routeName = '/profile';
  final Future<List<CategoryScore>> Function()? scoreLoader;
  final ScoreRepository? scoreRepository;
  final AuthService? authService;
  final LeaderboardBandService? leaderboardBandService;

  const UserProfileScreen({
    super.key,
    this.scoreLoader,
    this.scoreRepository,
    this.authService,
    this.leaderboardBandService,
  });

  // Human-readable labels for your category keys:
  static const _labels = {
    'flag': 'Flag Quiz',
    'logo': 'Logo Quiz',
    'capital': 'Capital Quiz',
    // add more as you introduce them...
  };

  /// Creates state for user-profile score loading and guest CTA resolution.
  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late Future<_ProfileData> _profileDataFuture;
  bool _dismissGuestCta = false;

  /// Loads profile data once for this widget lifecycle.
  @override
  void initState() {
    super.initState();
    _profileDataFuture = _loadProfileData();
  }

  /// Loads all profile scores and resolves optional guest leaderboard messaging.
  Future<_ProfileData> _loadProfileData() async {
    final repository = widget.scoreRepository ?? LocalFirstScoreRepository();
    final authService = widget.authService ?? AuthService();
    final leaderboardBandService =
        widget.leaderboardBandService ?? LeaderboardBandService();
    final scores = await (widget.scoreLoader ?? repository.getAllHighScores)();
    final guestBand = await _loadGuestBand(
      scores: scores,
      authService: authService,
      leaderboardBandService: leaderboardBandService,
    );
    return _ProfileData(scores: scores, guestBand: guestBand);
  }

  /// Resolves the strongest anonymous leaderboard rank from the user's scores.
  Future<LeaderboardBandResult?> _loadGuestBand({
    required List<CategoryScore> scores,
    required AuthService authService,
    required LeaderboardBandService leaderboardBandService,
  }) async {
    final user = _safeCurrentUser(authService);
    if (scores.isEmpty || user == null || !user.isAnonymous) {
      return null;
    }

    final candidates = await Future.wait(
      scores.map(
        (score) => _resolveBandForScore(
          score: score,
          user: user,
          leaderboardBandService: leaderboardBandService,
        ),
      ),
    );

    LeaderboardBandResult? bestRank;
    for (final band in candidates) {
      if (band == null) continue;
      if (bestRank == null || band.rank < bestRank.rank) {
        bestRank = band;
      }
    }
    return bestRank;
  }

  /// Looks up leaderboard rank band for one category+difficulty high score.
  Future<LeaderboardBandResult?> _resolveBandForScore({
    required CategoryScore score,
    required User user,
    required LeaderboardBandService leaderboardBandService,
  }) async {
    try {
      return await leaderboardBandService.getBandForScore(
        categoryKey: score.categoryKey,
        difficulty: score.difficulty,
        score: score.highScore,
        candidateUid: user.uid,
        candidateIsAnonymous: true,
        candidateDisplayName: user.displayName,
      );
    } catch (e) {
      debugPrint(
        'Leaderboard band lookup failed for ${score.categoryKey}/${score.difficulty}: $e',
      );
      return null;
    }
  }

  /// Reads current user in a safe way for environments without Firebase setup.
  User? _safeCurrentUser(AuthService authService) {
    try {
      return authService.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Returns user-facing copy for profile conversion CTA by leaderboard band.
  String _guestBandMessage(LeaderboardBand band) {
    return switch (band) {
      LeaderboardBand.top10 => "Your best score is in the top 10 as a guest.",
      LeaderboardBand.top20 => "Your best score is in the top 20 as a guest.",
      LeaderboardBand.top100 => "Your best score is in the top 100 as a guest.",
      LeaderboardBand.outsideTop100 =>
        "Your best score is climbing the rankings as a guest.",
    };
  }

  /// Opens account-upgrade flow and hides CTA when guest converts successfully.
  Future<void> _openUpgradeFlow() async {
    await Navigator.pushNamed(context, UpgradeAccountScreen.routeName);

    final authService = widget.authService ?? AuthService();
    final user = _safeCurrentUser(authService);
    if (mounted && user != null && !user.isAnonymous) {
      setState(() {
        _dismissGuestCta = true;
      });
    }
  }

  /// Builds profile content with the user's saved high scores.
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Your Profile')),
      body: FutureBuilder<_ProfileData>(
        future: _profileDataFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          final profileData = snap.data!;
          final scores = profileData.scores;

          // If you want to show categories even with zero score,
          // unify `scores` with _labels.keys here.

          if (scores.isEmpty) {
            return const Center(child: Text('No scores yet.'));
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const CircleAvatar(
                radius: 40,
                child: Icon(Icons.person, size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                'High Scores',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              if (!_dismissGuestCta && profileData.guestBand != null) ...[
                Card(
                  key: const Key('guest-profile-conversion-cta'),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          _guestBandMessage(profileData.guestBand!.band),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Create an account to compete globally.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          key: const Key('guest-profile-conversion-cta-action'),
                          onPressed: _openUpgradeFlow,
                          child: const Text('Create Account'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ...scores.map((sc) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: Icon(Icons.star, color: cs.primary),
                    title: Text(
                      // e.g. "Flag Quiz (Easy)"
                      '${UserProfileScreen._labels[sc.categoryKey] ?? sc.categoryKey} '
                      '(${toUpperCase(sc.difficulty[0])})',
                    ),
                    trailing: Text(
                      '${sc.highScore}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileData {
  final List<CategoryScore> scores;
  final LeaderboardBandResult? guestBand;

  _ProfileData({required this.scores, required this.guestBand});
}
