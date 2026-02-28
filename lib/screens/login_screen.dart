/*
 DOC: Screen
 Title: Login Screen
 Purpose: Handles provider-based sign-in and account creation.
*/
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_apple/firebase_ui_oauth_apple.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:quiznetic_flutter/config/app_config.dart';
import 'package:quiznetic_flutter/config/brand_config.dart';
import 'package:quiznetic_flutter/services/analytics_service.dart';
import 'package:quiznetic_flutter/services/auth_service.dart';
import 'package:quiznetic_flutter/services/score_repository.dart';
import 'package:quiznetic_flutter/services/user_checker.dart';
import 'package:quiznetic_flutter/screens/home_screen.dart';
import 'package:quiznetic_flutter/utils/auth_ui_helper.dart';
import 'package:quiznetic_flutter/widgets/legal_consent_notice.dart';

class LoginScreen extends StatelessWidget {
  static const routeName = '/login';
  static const logoAssetPath = 'assets/images/logo-no-background.png';
  final String? googleOAuthClientId;

  const LoginScreen({super.key, this.googleOAuthClientId});

  /// Returns true when Google provider config is available.
  @visibleForTesting
  static bool isGoogleProviderEnabled(String clientId) {
    return AuthUiHelper.isGoogleProviderEnabled(clientId);
  }

  /// Returns true when Apple provider is available in current build/platform.
  @visibleForTesting
  static bool isAppleProviderEnabled({
    bool? appleSignInEnabled,
    bool isWeb = kIsWeb,
    TargetPlatform? platform,
  }) {
    return AuthUiHelper.isAppleProviderEnabled(
      appleSignInEnabled: appleSignInEnabled,
      isWeb: isWeb,
      platform: platform,
    );
  }

  /// Returns true when we should show an "Apple unavailable" notice.
  ///
  /// On Android we intentionally hide this notice to avoid irrelevant UX copy.
  @visibleForTesting
  static bool shouldShowAppleUnavailableMessage({
    required bool appleProviderEnabled,
    bool isWeb = kIsWeb,
    TargetPlatform? platform,
  }) {
    return AuthUiHelper.shouldShowAppleUnavailableMessage(
      appleProviderEnabled: appleProviderEnabled,
      isWeb: isWeb,
      platform: platform,
    );
  }

  /// Builds provider list, conditionally including Google based on config.
  @visibleForTesting
  static List<AuthProvider> buildProviders({
    required String googleClientId,
    bool? includeAppleProvider,
  }) {
    final appleEnabled = includeAppleProvider ?? isAppleProviderEnabled();
    return [
      EmailAuthProvider(),
      if (isGoogleProviderEnabled(googleClientId))
        GoogleProvider(clientId: googleClientId.trim()),
      if (appleEnabled) AppleProvider(scopes: const <String>{'email', 'name'}),
    ];
  }

  /// Maps Firebase Auth failures to user-safe sign-in messages.
  @visibleForTesting
  static String authFailureMessage(Exception exception) {
    return AuthUiHelper.authFailureMessage(exception);
  }

  /// Normalized reason used for analytics segmentation.
  @visibleForTesting
  static String authFailureReason(Exception exception) {
    return AuthUiHelper.authFailureReason(exception);
  }

  @visibleForTesting
  static Widget buildHeader({
    required BuildContext context,
    required BoxConstraints constraints,
  }) {
    final theme = Theme.of(context);
    final verticalPadding = constraints.maxHeight < 140 ? 12.0 : 20.0;
    final rawLogoHeight = constraints.maxHeight - 96;
    final logoHeight = rawLogoHeight.clamp(0.0, 180.0).toDouble();
    final showLogo = logoHeight >= 72;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, verticalPadding, 20, verticalPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLogo)
            SizedBox(
              height: logoHeight,
              child: Image.asset(
                logoAssetPath,
                fit: BoxFit.contain,
                semanticLabel: BrandConfig.logoSemanticLabel,
              ),
            ),
          if (showLogo) const SizedBox(height: 8),
          Text(
            'Quiznetic',
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Test your knowledge of world flags!',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Builds provider sign-in and account-creation actions.
  @override
  Widget build(BuildContext context) {
    final resolvedGoogleClientId =
        googleOAuthClientId ?? AppConfig.googleOAuthClientId;
    final googleConfigured = isGoogleProviderEnabled(resolvedGoogleClientId);
    final appleConfigured = isAppleProviderEnabled();

    return Scaffold(
      body: SafeArea(
        child: SignInScreen(
          // Providers
          providers: buildProviders(
            googleClientId: resolvedGoogleClientId,
            includeAppleProvider: appleConfigured,
          ),

          // Header
          headerBuilder: (context, constraints, shrinkOffset) {
            return buildHeader(context: context, constraints: constraints);
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
                  if (shouldShowAppleUnavailableMessage(
                    appleProviderEnabled: appleConfigured,
                  ))
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Apple sign-in is currently unavailable.',
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
              unawaited(
                AnalyticsService.instance.logEvent(
                  'auth_signed_in',
                  parameters: {
                    'flow': 'login',
                    'provider_count': user.providerData.length,
                    'is_anonymous': user.isAnonymous,
                  },
                ),
              );

              final created = await UserChecker.ensureUserDocument(user: user);
              if (!created) {
                unawaited(
                  AnalyticsService.instance.logEvent(
                    'auth_profile_bootstrap_failed',
                    parameters: {'flow': 'login'},
                  ),
                );
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
                  unawaited(
                    AnalyticsService.instance.logEvent(
                      'auth_cleanup_failed',
                      parameters: {'flow': 'login'},
                    ),
                  );
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
                unawaited(
                  AnalyticsService.instance.logEvent(
                    'auth_post_signin_sync_failed',
                    parameters: {
                      'flow': 'login',
                      'error_type': e.runtimeType.toString(),
                    },
                  ),
                );
              }

              if (context.mounted) {
                Navigator.of(
                  context,
                ).pushReplacementNamed(HomeScreen.routeName);
              }
            }),
            AuthStateChangeAction<AuthFailed>((context, state) {
              final exception = state.exception;
              final errorCode = exception is fba.FirebaseAuthException
                  ? exception.code
                  : exception.runtimeType.toString();
              unawaited(
                AnalyticsService.instance.logEvent(
                  'auth_signin_failed',
                  parameters: {
                    'flow': 'login',
                    'error_code': errorCode,
                    'failure_reason': authFailureReason(exception),
                  },
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(authFailureMessage(exception))),
              );
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
