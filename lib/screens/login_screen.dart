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
import 'package:quiznetic_flutter/utils/app_logger.dart';
import 'package:quiznetic_flutter/utils/auth_ui_helper.dart';
import 'package:quiznetic_flutter/widgets/legal_consent_notice.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';
  static const logoAssetPath = 'assets/images/logo-no-background.png';
  static const _headerCompactHeightThreshold = 140.0;
  static const _headerDefaultVerticalPadding = 20.0;
  static const _headerCompactVerticalPadding = 12.0;
  static const _headerTextReservation = 96.0;
  static const _headerLogoSpacing = 8.0;
  static const _headerLogoMaxHeight = 180.0;
  static const _headerLogoMinVisibleHeight = 72.0;
  final String? googleOAuthClientId;

  const LoginScreen({super.key, this.googleOAuthClientId});

  @override
  State<LoginScreen> createState() => _LoginScreenState();

  @visibleForTesting
  static bool isGoogleProviderEnabled(String clientId) {
    return AuthUiHelper.isGoogleProviderEnabled(clientId);
  }

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

  @visibleForTesting
  static String authFailureMessage(Exception exception) {
    return AuthUiHelper.authFailureMessage(exception);
  }

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
    final verticalPadding =
        constraints.maxHeight < _headerCompactHeightThreshold
        ? _headerCompactVerticalPadding
        : _headerDefaultVerticalPadding;
    final rawLogoHeight =
        constraints.maxHeight - (verticalPadding * 2) - _headerTextReservation;
    final logoHeight = rawLogoHeight
        .clamp(0.0, _headerLogoMaxHeight)
        .toDouble();
    final showLogo = logoHeight >= _headerLogoMinVisibleHeight;

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
          if (showLogo) const SizedBox(height: _headerLogoSpacing),
          Text(
            BrandConfig.appName,
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            BrandConfig.tagline,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Shared post-authentication flow: saves user profile, syncs scores, navigates home.
  static Future<void> _completeSignIn(
    BuildContext context,
    fba.User user,
  ) async {
    AppLogger.d('✅ ${user.uid} signed in');
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

    try {
      await LocalFirstScoreRepository().syncPendingScores(forceRetry: true);
    } catch (e) {
      AppLogger.d('⚠️ Deferred score sync after sign-in failed: $e');
      unawaited(
        AnalyticsService.instance.logEvent(
          'auth_post_signin_sync_failed',
          parameters: {'flow': 'login', 'error_type': e.runtimeType.toString()},
        ),
      );
    }

    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
    }
  }

  static Future<String?> _showDisplayNameDialog(
    BuildContext context,
    String? email,
  ) {
    final emailPrefix = email?.split('@').first ?? '';
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DisplayNameDialog(initialValue: emailPrefix),
    );
  }

}

class _LoginScreenState extends State<LoginScreen> {
  bool _completing = false;

  Future<void> _guardedCompleteSignIn(fba.User user) async {
    if (_completing) return;
    _completing = true;
    try {
      await LoginScreen._completeSignIn(context, user);
    } finally {
      // Reset only if still mounted — if navigation succeeded the widget is gone.
      if (mounted) _completing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolvedGoogleClientId =
        widget.googleOAuthClientId ?? AppConfig.googleOAuthClientId;
    final googleConfigured = LoginScreen.isGoogleProviderEnabled(
      resolvedGoogleClientId,
    );
    final appleConfigured = LoginScreen.isAppleProviderEnabled();

    return Scaffold(
      body: SafeArea(
        child: SignInScreen(
          // Providers
          providers: LoginScreen.buildProviders(
            googleClientId: resolvedGoogleClientId,
            includeAppleProvider: appleConfigured,
          ),

          // Header
          headerBuilder: (context, constraints, _) {
            return LoginScreen.buildHeader(
              context: context,
              constraints: constraints,
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
                  if (LoginScreen.shouldShowAppleUnavailableMessage(
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
            // Fires only on email/password registration (not sign-in, not OAuth).
            // FirebaseUI also emits SignedIn after UserCreated — the guard in
            // _guardedCompleteSignIn ensures _completeSignIn runs only once.
            AuthStateChangeAction<UserCreated>((context, state) async {
              final user = state.credential.user;
              if (user == null) return;

              // Email/password accounts have no displayName from Firebase Auth.
              // Prompt once so the leaderboard shows a real name instead of an email prefix.
              if ((user.displayName?.trim() ?? '').isEmpty && context.mounted) {
                final name = await LoginScreen._showDisplayNameDialog(
                  context,
                  user.email,
                );
                if (name != null && name.isNotEmpty) {
                  try {
                    await user.updateDisplayName(name);
                    await user.reload();
                  } catch (e) {
                    AppLogger.d('⚠️ Failed to set display name: $e');
                  }
                }
              }

              // Re-fetch so ensureUserDocument picks up the updated displayName.
              final freshUser = fba.FirebaseAuth.instance.currentUser ?? user;
              if (!context.mounted) return;
              await _guardedCompleteSignIn(freshUser);
            }),
            // Fires on email/password sign-in and all OAuth sign-ins/sign-ups.
            // Google and Apple already supply displayName from their provider profile.
            AuthStateChangeAction<SignedIn>((context, state) async {
              final user = state.user;
              if (user == null) return;
              await _guardedCompleteSignIn(user);
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
                    'failure_reason': LoginScreen.authFailureReason(exception),
                  },
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(LoginScreen.authFailureMessage(exception)),
                ),
              );
            }),
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

class _DisplayNameDialog extends StatefulWidget {
  final String initialValue;

  const _DisplayNameDialog({required this.initialValue});

  @override
  State<_DisplayNameDialog> createState() => _DisplayNameDialogState();
}

class _DisplayNameDialogState extends State<_DisplayNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('What should we call you?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your name appears on the leaderboard.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Display name',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        FilledButton(onPressed: _submit, child: const Text('Continue')),
      ],
    );
  }

  void _submit() => Navigator.of(context).pop(_controller.text.trim());
}
