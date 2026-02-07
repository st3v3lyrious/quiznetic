import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/services/auth_service.dart';

void main() {
  group('AuthService', () {
    test('reports signed-out state when current user is null', () {
      final service = AuthService(
        currentUserProvider: () => null,
        authStateChangesProvider: () => const Stream<User?>.empty(),
        anonymousSignInProvider: () async => _FakeUserCredential(user: null),
        signOutProvider: () async {},
      );

      expect(service.isSignedIn, isFalse);
      expect(service.isAnonymous, isTrue);
    });

    test('reports signed-in non-anonymous state', () {
      final service = AuthService(
        currentUserProvider: () => _FakeUser(uid: 'u1', isAnonymous: false),
        authStateChangesProvider: () => const Stream<User?>.empty(),
        anonymousSignInProvider: () async => _FakeUserCredential(user: null),
        signOutProvider: () async {},
      );

      expect(service.isSignedIn, isTrue);
      expect(service.isAnonymous, isFalse);
    });

    test('delegates authStateChanges stream', () async {
      final service = AuthService(
        currentUserProvider: () => null,
        authStateChangesProvider: () => Stream<User?>.value(null),
        anonymousSignInProvider: () async => _FakeUserCredential(user: null),
        signOutProvider: () async {},
      );

      expect(await service.authStateChanges.first, isNull);
    });

    test('signInAnonymously ensures user document when user exists', () async {
      var ensureCalled = false;
      final fakeUser = _FakeUser(uid: 'guest1', isAnonymous: true);
      final credential = _FakeUserCredential(user: fakeUser);
      final service = AuthService(
        currentUserProvider: () => null,
        authStateChangesProvider: () => const Stream<User?>.empty(),
        anonymousSignInProvider: () async => credential,
        signOutProvider: () async {},
        ensureUserDocumentProvider: ({required user}) async {
          ensureCalled = true;
          return true;
        },
      );

      final result = await service.signInAnonymously();
      expect(result, same(credential));
      expect(ensureCalled, isTrue);
    });

    test('signInAnonymously throws when profile creation fails', () async {
      final fakeUser = _FakeUser(uid: 'guest1', isAnonymous: true);
      final service = AuthService(
        currentUserProvider: () => null,
        authStateChangesProvider: () => const Stream<User?>.empty(),
        anonymousSignInProvider: () async =>
            _FakeUserCredential(user: fakeUser),
        signOutProvider: () async {},
        ensureUserDocumentProvider: ({required user}) async => false,
      );

      await expectLater(service.signInAnonymously(), throwsException);
    });

    test('linkAnonymousWithCredential throws when not signed in', () async {
      final service = AuthService(
        currentUserProvider: () => null,
        authStateChangesProvider: () => const Stream<User?>.empty(),
        anonymousSignInProvider: () async => _FakeUserCredential(user: null),
        signOutProvider: () async {},
      );

      final credential = EmailAuthProvider.credential(
        email: 'a@b.com',
        password: 'secret',
      );

      await expectLater(
        service.linkAnonymousWithCredential(credential),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Not signed in'),
          ),
        ),
      );
    });

    test(
      'linkAnonymousWithCredential throws when current user is not anonymous',
      () async {
        final service = AuthService(
          currentUserProvider: () => _FakeUser(uid: 'u1', isAnonymous: false),
          authStateChangesProvider: () => const Stream<User?>.empty(),
          anonymousSignInProvider: () async => _FakeUserCredential(user: null),
          signOutProvider: () async {},
        );

        final credential = EmailAuthProvider.credential(
          email: 'a@b.com',
          password: 'secret',
        );

        await expectLater(
          service.linkAnonymousWithCredential(credential),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('User is not anonymous'),
            ),
          ),
        );
      },
    );

    test('linkAnonymousWithCredential delegates to link provider', () async {
      final user = _FakeUser(uid: 'u2', isAnonymous: true);
      final expectedCredential = _FakeUserCredential(user: user);
      final service = AuthService(
        currentUserProvider: () => user,
        authStateChangesProvider: () => const Stream<User?>.empty(),
        anonymousSignInProvider: () async => _FakeUserCredential(user: null),
        signOutProvider: () async {},
        linkWithCredentialProvider: (linkedUser, credential) async {
          expect(linkedUser.uid, equals('u2'));
          return expectedCredential;
        },
      );

      final credential = EmailAuthProvider.credential(
        email: 'a@b.com',
        password: 'secret',
      );
      final result = await service.linkAnonymousWithCredential(credential);
      expect(result, same(expectedCredential));
    });
  });
}

class _FakeUser implements User {
  _FakeUser({required this.uid, required this.isAnonymous});

  @override
  final String uid;

  @override
  final bool isAnonymous;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUserCredential implements UserCredential {
  _FakeUserCredential({required this.user});

  @override
  final User? user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
