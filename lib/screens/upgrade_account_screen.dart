/*
 DOC: Screen
 Title: Upgrade Account Screen
 Purpose: Lets anonymous users link a permanent provider account while preserving guest identity.
*/
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_apple/firebase_ui_oauth_apple.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:quiznetic_flutter/config/app_config.dart';
import 'package:quiznetic_flutter/services/analytics_service.dart';
import 'package:quiznetic_flutter/services/score_repository.dart';
import 'package:quiznetic_flutter/services/user_checker.dart';
import 'package:quiznetic_flutter/widgets/legal_consent_notice.dart';

/// Screen that allows anonymous users to upgrade to a full account
class UpgradeAccountScreen extends StatefulWidget {
  static const routeName = '/upgrade';
  final String? googleOAuthClientId;

  const UpgradeAccountScreen({super.key, this.googleOAuthClientId});

  /// Returns true when Google provider config is available.
  @visibleForTesting
  static bool isGoogleProviderEnabled(String clientId) {
    return clientId.trim().isNotEmpty;
  }

  /// Returns true when Apple provider is available in current build/platform.
  @visibleForTesting
  static bool isAppleProviderEnabled({
    bool? appleSignInEnabled,
    bool isWeb = kIsWeb,
    TargetPlatform? platform,
  }) {
    if (!(appleSignInEnabled ?? AppConfig.enableAppleSignIn)) {
      return false;
    }
    if (isWeb) {
      return true;
    }

    final resolvedPlatform = platform ?? defaultTargetPlatform;
    return resolvedPlatform == TargetPlatform.android ||
        resolvedPlatform == TargetPlatform.iOS ||
        resolvedPlatform == TargetPlatform.macOS;
  }

  /// Builds provider list for anonymous-account upgrade.
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
    if (exception is fba.FirebaseAuthException) {
      switch (exception.code) {
        case 'operation-not-allowed':
          return 'This sign-in method is currently unavailable. Please try another option.';
        case 'web-context-cancelled':
          return 'Sign-in was cancelled. Please try again.';
        case 'web-context-already-presented':
          return 'Another sign-in prompt is already open.';
        case 'missing-or-invalid-nonce':
          return 'Apple sign-in validation failed. Please try again.';
        case 'network-request-failed':
          return 'Network error while signing in. Check your connection and try again.';
      }
    }
    return 'Sign-in failed. Please try again.';
  }

  /// Returns true when upgraded user keeps the same uid as guest identity.
  @visibleForTesting
  static bool preservesGuestIdentity({
    required String? initialAnonymousUid,
    required fba.User user,
  }) {
    if (initialAnonymousUid == null) return true;
    return user.uid == initialAnonymousUid;
  }

  /// Creates state for provider-link upgrade flow.
  @override
  State<UpgradeAccountScreen> createState() => _UpgradeAccountScreenState();
}

class _UpgradeAccountScreenState extends State<UpgradeAccountScreen> {
  String? _initialAnonymousUid;
  bool _isProcessingUpgrade = false;

  /// Captures initial anonymous uid for continuity checks.
  @override
  void initState() {
    super.initState();
    _initialAnonymousUid = _readCurrentAnonymousUid();
  }

  /// Reads current uid only when signed in as anonymous user.
  String? _readCurrentAnonymousUid() {
    try {
      final user = fba.FirebaseAuth.instance.currentUser;
      if (user == null || !user.isAnonymous) return null;
      return user.uid;
    } catch (_) {
      return null;
    }
  }

  /// Handles successful credential-link events and closes upgrade flow.
  Future<void> _finalizeUpgrade(fba.User? user) async {
    if (_isProcessingUpgrade || user == null) return;
    unawaited(
      AnalyticsService.instance.logEvent(
        'auth_upgrade_started',
        parameters: {'flow': 'upgrade'},
      ),
    );

    setState(() {
      _isProcessingUpgrade = true;
    });

    try {
      if (!UpgradeAccountScreen.preservesGuestIdentity(
        initialAnonymousUid: _initialAnonymousUid,
        user: user,
      )) {
        unawaited(
          AnalyticsService.instance.logEvent(
            'auth_upgrade_failed',
            parameters: {'flow': 'upgrade', 'reason': 'uid_mismatch'},
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Upgrade did not preserve guest progress. Please try again.',
              ),
            ),
          );
        }
        return;
      }

      final ensured = await UserChecker.ensureUserDocument(user: user);
      if (!ensured) {
        unawaited(
          AnalyticsService.instance.logEvent(
            'auth_upgrade_failed',
            parameters: {'flow': 'upgrade', 'reason': 'profile_bootstrap'},
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not update your user profile. Please try again.',
              ),
            ),
          );
        }
        return;
      }

      try {
        await LocalFirstScoreRepository().syncPendingScores(forceRetry: true);
      } catch (e) {
        debugPrint('⚠️ Deferred score sync after account upgrade failed: $e');
        unawaited(
          AnalyticsService.instance.logEvent(
            'auth_upgrade_sync_failed',
            parameters: {
              'flow': 'upgrade',
              'error_type': e.runtimeType.toString(),
            },
          ),
        );
      }

      unawaited(
        AnalyticsService.instance.logEvent(
          'auth_upgrade_completed',
          parameters: {'flow': 'upgrade'},
        ),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e, stackTrace) {
      debugPrint('UpgradeAccountScreen finalize failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      unawaited(
        AnalyticsService.instance.logEvent(
          'auth_upgrade_failed',
          parameters: {
            'flow': 'upgrade',
            'reason': 'unexpected_error',
            'error_type': e.runtimeType.toString(),
          },
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingUpgrade = false;
        });
      }
    }
  }

  /// Builds the sign-in UI used to upgrade an anonymous account.
  @override
  Widget build(BuildContext context) {
    final resolvedGoogleClientId =
        widget.googleOAuthClientId ?? AppConfig.googleOAuthClientId;
    final googleConfigured = UpgradeAccountScreen.isGoogleProviderEnabled(
      resolvedGoogleClientId,
    );
    final appleConfigured = UpgradeAccountScreen.isAppleProviderEnabled();

    // Offer the firebase_ui_auth sign-in screen to upgrade anonymous users.
    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade Account')),
      body: SignInScreen(
        providers: UpgradeAccountScreen.buildProviders(
          googleClientId: resolvedGoogleClientId,
          includeAppleProvider: appleConfigured,
        ),
        subtitleBuilder: (context, action) {
          return Column(
            children: [
              const Text(
                'Link a permanent account to keep your guest progress.',
                textAlign: TextAlign.center,
              ),
              if (!googleConfigured)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Google sign-in is currently unavailable.',
                    textAlign: TextAlign.center,
                  ),
                ),
              if (!appleConfigured)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Apple sign-in is currently unavailable.',
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          );
        },
        actions: [
          AuthStateChangeAction<CredentialLinked>((context, state) {
            _finalizeUpgrade(state.user);
          }),
          AuthStateChangeAction<SignedIn>((context, state) {
            // Fallback for providers that emit SignedIn after successful link.
            _finalizeUpgrade(state.user);
          }),
          AuthStateChangeAction<AuthFailed>((context, state) {
            final exception = state.exception;
            final errorCode = exception is fba.FirebaseAuthException
                ? exception.code
                : exception.runtimeType.toString();
            unawaited(
              AnalyticsService.instance.logEvent(
                'auth_upgrade_failed',
                parameters: {'flow': 'upgrade', 'error_code': errorCode},
              ),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  UpgradeAccountScreen.authFailureMessage(exception),
                ),
              ),
            );
          }),
        ],
        footerBuilder: (context, _) => Column(
          children: [
            TextButton(
              onPressed: () {
                unawaited(
                  AnalyticsService.instance.logEvent(
                    'auth_upgrade_skipped',
                    parameters: {'flow': 'upgrade'},
                  ),
                );
                Navigator.of(context).pop();
              },
              child: const Text('Maybe Later'),
            ),
            const LegalConsentNotice(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            ),
          ],
        ),
      ),
    );
  }
}
