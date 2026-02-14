/*
 DOC: Screen
 Title: Login Screen
 Purpose: Handles provider-based sign-in and account creation.
*/
import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_apple/firebase_ui_oauth_apple.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:quiznetic_flutter/config/app_config.dart';
import 'package:quiznetic_flutter/config/brand_config.dart';
import 'package:quiznetic_flutter/services/auth_service.dart';
import 'package:quiznetic_flutter/services/score_repository.dart';
import 'package:quiznetic_flutter/services/user_checker.dart';
import 'package:quiznetic_flutter/screens/home_screen.dart';
import 'package:quiznetic_flutter/widgets/legal_consent_notice.dart';

class LoginScreen extends StatelessWidget {
  static const routeName = '/login';
  static const logoAssetPath = 'assets/images/logo-no-background.png';
  final String? googleOAuthClientId;

  const LoginScreen({super.key, this.googleOAuthClientId});

  /// Returns true when Google provider config is available.
  @visibleForTesting
  static bool isGoogleProviderEnabled(String clientId) {
    return clientId.trim().isNotEmpty;
  }

  /// Builds provider list, conditionally including Google based on config.
  @visibleForTesting
  static List<AuthProvider> buildProviders({required String googleClientId}) {
    return [
      EmailAuthProvider(),
      if (isGoogleProviderEnabled(googleClientId))
        GoogleProvider(clientId: googleClientId.trim()),
      AppleProvider(),
    ];
  }

  /// Builds provider sign-in and account-creation actions.
  @override
  Widget build(BuildContext context) {
    final resolvedGoogleClientId =
        googleOAuthClientId ?? AppConfig.googleOAuthClientId;
    final googleConfigured = isGoogleProviderEnabled(resolvedGoogleClientId);

    return Scaffold(
      body: SafeArea(
        child: SignInScreen(
          // Providers
          providers: buildProviders(googleClientId: resolvedGoogleClientId),

          // Header
          headerBuilder: (context, constraints, shrinkOffset) {
            final theme = Theme.of(context);
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Image.asset(
                      logoAssetPath,
                      semanticLabel: BrandConfig.logoSemanticLabel,
                    ),
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
              child: Column(
                children: [
                  action == AuthAction.signIn
                      ? const Text('Welcome back! Please sign in to continue.')
                      : const Text(
                          'Welcome! Please create an account to continue.',
                        ),
                  if (!googleConfigured)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Google sign-in is currently unavailable.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            );
          },

          // Footer
          footerBuilder: (context, action) {
            return const LegalConsentNotice(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 20),
            );
          },

          // Actions (auth state changes)
          actions: [
            AuthStateChangeAction<SignedIn>((context, state) async {
              final user = state.user;
              if (user == null) return;

              debugPrint('✅ ${user.uid} signed in');

              final created = await UserChecker.ensureUserDocument(user: user);
              if (!created) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Could not create your user profile. Please try again.',
                      ),
                    ),
                  );
                }
                try {
                  await AuthService().signOut();
                } catch (_) {
                  // Keep user on login screen even if sign-out cleanup fails.
                }
                return;
              }

              // If scores were queued while offline, attempt a best-effort sync.
              try {
                await LocalFirstScoreRepository().syncPendingScores(
                  forceRetry: true,
                );
              } catch (e) {
                debugPrint(
                  '⚠️ Deferred score sync after provider sign-in failed: $e',
                );
              }

              if (context.mounted) {
                Navigator.of(
                  context,
                ).pushReplacementNamed(HomeScreen.routeName);
              }
            }),
            // Additional auth state actions can be added as needed
          ],

          // Styles
          styles: const {
            EmailFormStyle(signInButtonVariant: ButtonVariant.filled),
          },
        ),
      ),
    );
  }
}
