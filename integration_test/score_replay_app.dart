// Emulator-only C5/C6 review harness; never build this entrypoint for production.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:quiznetic_flutter/services/analytics_service.dart';
import 'package:quiznetic_flutter/services/score_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'demo-api-key',
      appId: '1:123:web:demo',
      messagingSenderId: '123',
      projectId: 'demo-quiznetic',
      authDomain: 'demo-quiznetic.firebaseapp.com',
    ),
  );
  await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
  FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
  runApp(const MaterialApp(home: _Review()));
}

class _Review extends StatefulWidget {
  const _Review();
  @override
  State<_Review> createState() => _ReviewState();
}

class _ReviewState extends State<_Review> {
  String state = 'ready';
  Future<void> review() async {
    setState(() => state = 'running');
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email:
            'private-prefix-${DateTime.now().microsecondsSinceEpoch}@example.test',
        password: 'Demo-only-12345',
      );
      final events = <String>[];
      final service = ScoreService(
        enableBackendSubmitScore: false,
        analyticsService: AnalyticsService(
          isWeb: false,
          enabled: true,
          crashReportingEnabled: false,
          logEvent: ({required name, parameters}) async => events.add(name),
        ),
      );
      for (final attempt in [('first', 13), ('first', 15), ('second', 14)]) {
        await service.saveScore(
          categoryKey: 'flag',
          difficulty: 'easy',
          score: attempt.$2,
          totalQuestions: 15,
          attemptId: attempt.$1,
        );
      }
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final db = FirebaseFirestore.instance;
      final attempts = await db.collection('users/$uid/attempts').get();
      final entry = await db.doc('leaderboard/flag_easy/entries/$uid').get();
      if (attempts.size != 2 ||
          entry.data()?['score'] != 14 ||
          entry.data()?['displayName'] != 'Player' ||
          events.join(',') !=
              'score_submit_success,score_submit_duplicate,score_submit_success') {
        throw StateError('Unexpected persisted data or events: $events');
      }
      setState(
        () => state =
            'PASS: 2 attempts, 2 successes, 1 duplicate, neutral Player',
      );
    } catch (e) {
      setState(() => state = 'FAIL: $e');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('C5 / C6 demo verification')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: state == 'ready' ? review : null,
            child: const Text('Run verification'),
          ),
          Text(state),
        ],
      ),
    ),
  );
}
