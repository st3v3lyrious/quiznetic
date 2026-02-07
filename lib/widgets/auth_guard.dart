import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quiznetic_flutter/screens/login_screen.dart';
import 'package:quiznetic_flutter/screens/upgrade_account_screen.dart';

/// A widget that enforces authentication state:
/// - If user is not signed in -> show login screen
/// - If user is anonymous -> optionally show upgrade prompt
/// - If user is fully authenticated -> show child
class AuthGuard extends StatelessWidget {
  final Widget child;
  final bool allowAnonymous;
  final Widget Function(BuildContext, User?)? builder;

  const AuthGuard({
    super.key,
    required this.child,
    this.allowAnonymous = true,
    this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show custom UI if builder is provided
        final localBuilder = builder;
        if (localBuilder != null) {
          return localBuilder(context, snapshot.data);
        }

        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        // Not signed in -> login screen
        if (user == null) {
          return const LoginScreen();
        }

        // Anonymous but not allowed -> upgrade prompt
        if (user.isAnonymous && !allowAnonymous) {
          return const UpgradeAccountScreen();
        }

        // All good -> show the protected content
        return child;
      },
    );
  }
}
