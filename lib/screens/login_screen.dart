/*
 DOC: Screen
 Title: Login Screen
 Purpose: Handles sign-in providers and guest sign-in entry.
*/
import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_apple/firebase_ui_oauth_apple.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:quiznetic_flutter/services/auth_service.dart';
import 'package:quiznetic_flutter/screens/home_screen.dart';

class LoginScreen extends StatelessWidget {
  static const routeName = '/login';
  const LoginScreen({super.key});

  /// Builds provider sign-in and guest-entry actions.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SignInScreen(
          // Providers
          providers: [
            EmailAuthProvider(),
            GoogleProvider(
              clientId: 'YOUR-CLIENT-ID.apps.googleusercontent.com',
            ),
            AppleProvider(),
          ],

          // Header
          headerBuilder: (context, constraints, shrinkOffset) {
            final theme = Theme.of(context);
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Image.asset('assets/images/logo.png'),
                  ),
                  Text(
                    'QuizNetic',
                    style: theme.textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Test your knowledge of world flags!',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },

          // Subtitle
          subtitleBuilder: (context, action) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: action == AuthAction.signIn
                  ? const Text('Welcome back! Please sign in to continue.')
                  : const Text(
                      'Welcome! Please create an account to continue.',
                    ),
            );
          },

          // Actions (auth state changes)
          actions: [
            AuthStateChangeAction<SignedIn>((context, state) {
              if (state.user != null)
                debugPrint('✅ ${state.user!.uid} signed in');
              Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
            }),
            // Additional auth state actions can be added as needed
          ],

          // Footer with guest sign-in
          footerBuilder: (context, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  onPressed: () async {
                    try {
                      final authService = AuthService();
                      final cred = await authService.signInAnonymously();
                      if (cred.user != null && context.mounted) {
                        Navigator.of(
                          context,
                        ).pushReplacementNamed(HomeScreen.routeName);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  child: const Text('Continue as Guest'),
                ),
                const SizedBox(height: 12),
              ],
            );
          },

          // Styles
          styles: const {
            EmailFormStyle(signInButtonVariant: ButtonVariant.filled),
          },
        ),
      ),
    );
  }
}
