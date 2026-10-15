/*
 DOC: Widget
 Title: Auth Guard
 Purpose: Guards widget trees based on authentication state.
*/
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quiznetic_flutter/screens/entry_choice_screen.dart';
import 'package:quiznetic_flutter/screens/upgrade_account_screen.dart';

/// A widget that enforces authentication state:
/// - If user is not signed in -> show entry choice screen
/// - If user is anonymous -> optionally show upgrade prompt
/// - If user is fully authenticated -> show child
class AuthGuard extends StatefulWidget {
  final Widget child;
  final bool allowAnonymous;
  final Widget Function(BuildContext, User?)? builder;
  final Stream<User?>? authStateChanges;

  const AuthGuard({
    super.key,
    required this.child,
    this.allowAnonymous = true,
    this.builder,
    this.authStateChanges,
  });

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  late Stream<User?> _stream;

  @override
  void initState() {
    super.initState();
    _stream =
        widget.authStateChanges ?? FirebaseAuth.instance.authStateChanges();
  }

  @override
  void didUpdateWidget(AuthGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authStateChanges != widget.authStateChanges) {
      _stream =
          widget.authStateChanges ?? FirebaseAuth.instance.authStateChanges();
    }
  }

  /// Builds output based on current auth state and guard rules.
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _stream,
      builder: (context, snapshot) {
        // Show custom UI if builder is provided
        final localBuilder = widget.builder;
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

        // Not signed in -> first-entry choice screen
        if (user == null) {
          return EntryChoiceScreen(
            returnTo: ModalRoute.of(context)?.settings.name,
          );
        }

        // Anonymous but not allowed -> upgrade prompt
        if (user.isAnonymous && !widget.allowAnonymous) {
          return const UpgradeAccountScreen();
        }

        // All good -> show the protected content
        return widget.child;
      },
    );
  }
}
