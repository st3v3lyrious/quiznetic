import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/services/analytics_service.dart';
import 'package:quiznetic_flutter/services/score_service.dart';

class _User extends Fake implements User {}

class _Auth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => _User();
}

class _Db extends Fake implements FirebaseFirestore {}

class _Result<T> extends Fake implements HttpsCallableResult<T> {
  _Result(this.data);
  @override
  final T data;
}

class _Callable extends Fake implements HttpsCallable {
  _Callable(this.status);
  final String status;
  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) async =>
      _Result<T>({'status': status} as T);
}

class _Functions extends Fake implements FirebaseFunctions {
  _Functions(this.status);
  final String status;
  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) =>
      _Callable(status);
}

void main() {
  for (final item in {
    'accepted': 'score_submit_success',
    'duplicate': 'score_submit_duplicate',
    'flagged': 'score_submit_flagged',
  }.entries) {
    test(
      'callable ${item.key} reports ${item.value} without counting another accepted attempt',
      () async {
        final events = <String>[];
        final analytics = AnalyticsService(
          isWeb: false,
          enabled: true,
          crashReportingEnabled: false,
          logEvent: ({required name, parameters}) async => events.add(name),
        );
        final service = ScoreService(
          auth: _Auth(),
          firestore: _Db(),
          functions: _Functions(item.key),
          enableBackendSubmitScore: true,
          analyticsService: analytics,
        );
        await service.saveScore(
          categoryKey: 'flag',
          difficulty: 'easy',
          score: 12,
          attemptId: 'same-attempt',
          totalQuestions: 15,
        );
        expect(events, [item.value]);
      },
    );
  }
}
