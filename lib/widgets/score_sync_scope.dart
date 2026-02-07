/*
 DOC: Widget
 Title: Score Sync Scope
 Purpose: Triggers background score sync on startup, auth changes, resume, and periodic intervals.
*/
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quiznetic_flutter/services/score_repository.dart';

class ScoreSyncScope extends StatefulWidget {
  final Widget child;
  final ScoreRepository? scoreRepository;
  final Stream<User?>? authStateChanges;
  final Duration periodicSyncInterval;

  const ScoreSyncScope({
    required this.child,
    super.key,
    this.scoreRepository,
    this.authStateChanges,
    this.periodicSyncInterval = const Duration(seconds: 45),
  });

  /// Creates state that monitors lifecycle and auth changes for sync triggers.
  @override
  State<ScoreSyncScope> createState() => _ScoreSyncScopeState();
}

class _ScoreSyncScopeState extends State<ScoreSyncScope>
    with WidgetsBindingObserver {
  late final ScoreRepository _scoreRepository =
      widget.scoreRepository ?? LocalFirstScoreRepository();
  late final Stream<User?> _authStateChanges =
      widget.authStateChanges ?? FirebaseAuth.instance.authStateChanges();
  StreamSubscription<User?>? _authSub;
  Timer? _periodicTimer;
  bool _syncInProgress = false;
  bool _syncQueued = false;
  bool _forceSyncQueued = false;

  /// Subscribes to sync triggers for startup, auth changes, and app lifecycle.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _authSub = _authStateChanges.listen((user) {
      if (user != null) {
        _requestSync('auth-state', forceRetry: true);
      }
    });

    _periodicTimer = Timer.periodic(widget.periodicSyncInterval, (_) {
      _requestSync('periodic');
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestSync('startup', forceRetry: true);
    });
  }

  /// Triggers sync when app returns to foreground.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _requestSync('resume', forceRetry: true);
    }
  }

  /// Queues and runs pending-sync work without overlapping concurrent runs.
  Future<void> _requestSync(String reason, {bool forceRetry = false}) async {
    if (!mounted) return;

    if (_syncInProgress) {
      _syncQueued = true;
      _forceSyncQueued = _forceSyncQueued || forceRetry;
      return;
    }

    _syncInProgress = true;
    var nextRunForce = forceRetry;
    do {
      _syncQueued = false;
      final runForce = nextRunForce || _forceSyncQueued;
      _forceSyncQueued = false;
      nextRunForce = false;
      try {
        await _scoreRepository.syncPendingScores(forceRetry: runForce);
      } catch (e) {
        debugPrint('Score sync ($reason) failed: $e');
      }
    } while (_syncQueued && mounted);
    _syncInProgress = false;
  }

  /// Releases subscriptions and observers used for automatic sync.
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSub?.cancel();
    _periodicTimer?.cancel();
    super.dispose();
  }

  /// Renders the wrapped application subtree.
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
