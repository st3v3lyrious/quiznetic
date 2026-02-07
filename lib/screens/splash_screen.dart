/*
 DOC: Screen
 Title: Splash Screen
 Purpose: Shows startup branding and routes users based on auth state.
*/
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:quiznetic_flutter/screens/home_screen.dart';
import 'package:quiznetic_flutter/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  static const routeName = '/splash';
  final Duration startupDelay;
  final User? Function()? currentUserProvider;

  const SplashScreen({
    super.key,
    this.startupDelay = const Duration(seconds: 2),
    this.currentUserProvider,
  });

  /// Creates state for the splash screen.
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  /// Starts the startup auth check and navigation flow.
  @override
  void initState() {
    super.initState();
    _checkUserAndNavigate();
  }

  /// Routes to home for signed-in users, otherwise to login.
  Future<void> _checkUserAndNavigate() async {
    await Future.delayed(widget.startupDelay);
    // Only check Firebase Authentication. Do NOT create or read Firestore
    // documents here — creation is handled in the login/signup flows.
    final currentUser = widget.currentUserProvider != null
        ? widget.currentUserProvider!.call()
        : FirebaseAuth.instance.currentUser;
    if (!mounted) return;
    if (currentUser != null) {
      Navigator.pushReplacementNamed(
        context,
        HomeScreen.routeName,
        arguments: (),
      );
    } else {
      Navigator.pushReplacementNamed(context, LoginScreen.routeName);
    }
  }

  /// Builds the splash logo view.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset('assets/images/logo-no-background.png', height: 150),
      ),
    );
  }
}
