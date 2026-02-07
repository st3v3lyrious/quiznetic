import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/services/user_checker.dart';

void main() {
  group('UserChecker.buildUserDocumentData', () {
    const nowToken = 'now-token';

    test('includes createdAt and guest displayName for new anonymous user', () {
      final data = UserChecker.buildUserDocumentData(
        user: _FakeUser(
          uid: 'abcd1234',
          isAnonymous: true,
          displayName: null,
          email: null,
        ),
        existingDocument: false,
        nowToken: nowToken,
      );

      expect(data['isAnonymous'], isTrue);
      expect(data['lastSeen'], equals(nowToken));
      expect(data['createdAt'], equals(nowToken));
      expect(data['displayName'], equals('Guest abcd'));
      expect(data.containsKey('email'), isFalse);
    });

    test('prefers explicit displayName and email', () {
      final data = UserChecker.buildUserDocumentData(
        user: _FakeUser(
          uid: 'uid-1',
          isAnonymous: false,
          displayName: '  Steve  ',
          email: '  steve@example.com ',
        ),
        existingDocument: true,
        nowToken: nowToken,
      );

      expect(data['isAnonymous'], isFalse);
      expect(data['lastSeen'], equals(nowToken));
      expect(data.containsKey('createdAt'), isFalse);
      expect(data['displayName'], equals('Steve'));
      expect(data['email'], equals('steve@example.com'));
    });

    test('does not set guest displayName for existing anonymous user', () {
      final data = UserChecker.buildUserDocumentData(
        user: _FakeUser(
          uid: 'abcd1234',
          isAnonymous: true,
          displayName: null,
          email: null,
        ),
        existingDocument: true,
        nowToken: nowToken,
      );

      expect(data.containsKey('displayName'), isFalse);
    });
  });
}

class _FakeUser implements User {
  _FakeUser({
    required this.uid,
    required this.isAnonymous,
    required this.displayName,
    required this.email,
  });

  @override
  final String uid;

  @override
  final bool isAnonymous;

  @override
  final String? displayName;

  @override
  final String? email;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
