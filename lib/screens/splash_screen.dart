import 'dart:async';
import 'package:flutter/material.dart';
import 'package:quiznetic_flutter/screens/home_screen.dart';
import 'package:quiznetic_flutter/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  static const routeName = '/splash';
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserAndNavigate();
  }

  Future<void> _checkUserAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));
    // Only check Firebase Authentication. Do NOT create or read Firestore
    // documents here — creation is handled in the login/signup flows.
    final currentUser = FirebaseAuth.instance.currentUser;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset('assets/images/logo-no-background.png', height: 150),
      ),
    );
  }
}
