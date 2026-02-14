/*
 DOC: Screen
 Title: Entry Choice Screen
 Purpose: Lets unauthenticated users choose between guest mode or provider sign-in.
*/
import 'package:flutter/material.dart';
import 'package:quiznetic_flutter/config/brand_config.dart';
import 'package:quiznetic_flutter/screens/home_screen.dart';
import 'package:quiznetic_flutter/screens/login_screen.dart';
import 'package:quiznetic_flutter/services/auth_service.dart';
import 'package:quiznetic_flutter/widgets/legal_consent_notice.dart';

typedef ContinueAsGuestAction = Future<void> Function(BuildContext context);
typedef SignInChoiceAction = void Function(BuildContext context);

class EntryChoiceScreen extends StatelessWidget {
  static const routeName = '/entry';

  final ContinueAsGuestAction? continueAsGuest;
  final SignInChoiceAction? onSignInChoice;

  const EntryChoiceScreen({
    super.key,
    this.continueAsGuest,
    this.onSignInChoice,
  });

  /// Signs in anonymously and routes to home when successful.
  Future<void> _defaultContinueAsGuest(BuildContext context) async {
    final cred = await AuthService().signInAnonymously();
    if (cred.user != null && context.mounted) {
      Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
    }
  }

  /// Routes to provider sign-in choices.
  void _defaultSignInChoice(BuildContext context) {
    Navigator.of(context).pushNamed(LoginScreen.routeName);
  }

  /// Builds first-entry actions before provider-specific login.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Image.asset(
                        'assets/images/logo-no-background.png',
                        height: 120,
                        semanticLabel: BrandConfig.logoSemanticLabel,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Welcome to QuizNetic',
                        style: theme.textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Choose how you want to start.',
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      ElevatedButton(
                        onPressed: () async {
                          final handler =
                              continueAsGuest ?? _defaultContinueAsGuest;
                          try {
                            await handler(context);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                        child: const Text('Continue as Guest'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () {
                          final handler =
                              onSignInChoice ?? _defaultSignInChoice;
                          handler(context);
                        },
                        child: const Text('Sign In / Create Account'),
                      ),
                      const SizedBox(height: 12),
                      const LegalConsentNotice(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
