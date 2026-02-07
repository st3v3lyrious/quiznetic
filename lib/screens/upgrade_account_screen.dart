/*
 DOC: Screen
 Title: Upgrade Account Screen
 Purpose: Lets anonymous users upgrade to a linked account.
*/
import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

/// Screen that allows anonymous users to upgrade to a full account
class UpgradeAccountScreen extends StatelessWidget {
  static const routeName = '/upgrade';
  const UpgradeAccountScreen({super.key});

  /// Builds the sign-in UI used to upgrade an anonymous account.
  @override
  Widget build(BuildContext context) {
    // Offer the firebase_ui_auth sign-in screen to upgrade anonymous users.
    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade Account')),
      body: SignInScreen(
        providers: [EmailAuthProvider()],
        actions: [
          AuthStateChangeAction<SignedIn>((context, state) {
            Navigator.of(context).pop(); // close upgrade screen
          }),
        ],
        footerBuilder: (context, _) => TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Maybe Later'),
        ),
      ),
    );
  }
}
