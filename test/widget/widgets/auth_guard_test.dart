import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/widgets/auth_guard.dart';

void main() {
  testWidgets('shows loading indicator while waiting for auth state', (
    tester,
  ) async {
    final controller = StreamController<User?>();
    addTearDown(controller.close);

    await tester.pumpWidget(
      MaterialApp(
        home: AuthGuard(
          authStateChanges: controller.stream,
          child: const Text('protected'),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows protected child for signed-in non-anonymous user', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AuthGuard(
          authStateChanges: Stream<User?>.value(_FakeUser(isAnonymous: false)),
          child: const Text('protected'),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('protected'), findsOneWidget);
  });

  testWidgets('allows anonymous user when allowAnonymous is true', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AuthGuard(
          allowAnonymous: true,
          authStateChanges: Stream<User?>.value(_FakeUser(isAnonymous: true)),
          child: const Text('protected'),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('protected'), findsOneWidget);
  });

  testWidgets('uses custom builder when provided', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AuthGuard(
          authStateChanges: const Stream<User?>.empty(),
          child: const Text('protected'),
          builder: (context, user) => Text(user == null ? 'no-user' : 'user'),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('no-user'), findsOneWidget);
  });
}

class _FakeUser implements User {
  _FakeUser({required this.isAnonymous});

  @override
  final bool isAnonymous;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
