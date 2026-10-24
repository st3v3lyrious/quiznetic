// Browser regression entrypoint. Uses local emulators only; never production.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:quiznetic_flutter/services/analytics_consent.dart';
import 'package:quiznetic_flutter/config/brand_config.dart';
import 'package:quiznetic_flutter/main.dart' show QuizNetic;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'demo-api-key',
      appId: '1:123456789:web:demo',
      messagingSenderId: '123456789',
      projectId: 'demo-quiznetic',
      authDomain: 'demo-quiznetic.firebaseapp.com',
    ),
  );
  await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
  FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
  await AnalyticsConsent.instance.initialize();
  await BrandConfig.initVersion();
  runApp(const QuizNetic());
}
