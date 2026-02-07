import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/services/score_repository.dart';
import 'package:quiznetic_flutter/services/score_service.dart';
import 'package:quiznetic_flutter/widgets/score_sync_scope.dart';

void main() {
  testWidgets('triggers sync on startup', (tester) async {
    final repo = _FakeScoreRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ScoreSyncScope(
          scoreRepository: repo,
          authStateChanges: const Stream<User?>.empty(),
          periodicSyncInterval: const Duration(hours: 1),
          child: const SizedBox.shrink(),
        ),
      ),
    );

    await tester.pump();
    expect(repo.syncCalls, equals(1));
    expect(repo.forceRetryCalls, equals([true]));
  });

  testWidgets('triggers sync when auth stream emits a signed-in user', (
    tester,
  ) async {
    final repo = _FakeScoreRepository();
    final authController = StreamController<User?>();
    addTearDown(authController.close);

    await tester.pumpWidget(
      MaterialApp(
        home: ScoreSyncScope(
          scoreRepository: repo,
          authStateChanges: authController.stream,
          periodicSyncInterval: const Duration(hours: 1),
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pump();
    expect(repo.syncCalls, equals(1));

    authController.add(_FakeUser());
    await tester.pump();
    expect(repo.syncCalls, equals(2));
    expect(repo.forceRetryCalls, equals([true, true]));
  });

  testWidgets('triggers sync when app resumes', (tester) async {
    final repo = _FakeScoreRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: ScoreSyncScope(
          scoreRepository: repo,
          authStateChanges: const Stream<User?>.empty(),
          periodicSyncInterval: const Duration(hours: 1),
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pump();
    expect(repo.syncCalls, equals(1));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(repo.syncCalls, equals(2));
    expect(repo.forceRetryCalls, equals([true, true]));
  });

  testWidgets('periodic timer retries sync while app stays active', (
    tester,
  ) async {
    final repo = _FakeScoreRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: ScoreSyncScope(
          scoreRepository: repo,
          authStateChanges: const Stream<User?>.empty(),
          periodicSyncInterval: const Duration(seconds: 1),
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pump();
    expect(repo.syncCalls, equals(1));
    expect(repo.forceRetryCalls, equals([true]));

    await tester.pump(const Duration(seconds: 3));
    expect(repo.syncCalls, greaterThanOrEqualTo(3));
    expect(
      repo.forceRetryCalls.skip(1).every((value) => value == false),
      isTrue,
    );
  });
}

class _FakeScoreRepository implements ScoreRepository {
  int syncCalls = 0;
  final List<bool> forceRetryCalls = [];

  @override
  Future<List<CategoryScore>> getAllHighScores() async => [];

  @override
  Future<int> getBestScore({
    required String categoryKey,
    required String difficulty,
  }) async => 0;

  @override
  Future<ScoreSaveResult> saveScore({
    required String categoryKey,
    required String difficulty,
    required int score,
    required int totalQuestions,
  }) async =>
      ScoreSaveResult(bestScore: 0, synced: false, queuedForSync: false);

  @override
  Future<int> syncPendingScores({bool forceRetry = false}) async {
    syncCalls++;
    forceRetryCalls.add(forceRetry);
    return 0;
  }
}

class _FakeUser implements User {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
