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
import 'package:quiznetic_flutter/screens/login_screen.dart';
import 'package:quiznetic_flutter/services/analytics_service.dart';
import 'package:quiznetic_flutter/services/score_repository.dart';
import 'package:quiznetic_flutter/services/user_checker.dart';
import 'package:quiznetic_flutter/utils/app_logger.dart';
import 'package:quiznetic_flutter/utils/auth_ui_helper.dart';
import 'package:quiznetic_flutter/widgets/legal_consent_notice.dart';

/// Screen that allows anonymous users to upgrade to a full account
class UpgradeAccountScreen extends StatefulWidget {
  static const routeName = '/upgrade';
  final String? googleOAuthClientId;

  const UpgradeAccountScreen({super.key, this.googleOAuthClientId});

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
    return AuthUiHelper.authFailureMessage(exception);
  }

  /// Normalized reason used for analytics segmentation.
  @visibleForTesting
  static String authFailureReason(Exception exception) {
    return AuthUiHelper.authFailureReason(exception);
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
  bool _allowExistingAccountUidChange = false;
  bool _isResolvingExistingAccountCollision = false;

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
  Future<void> _finalizeUpgrade(
    fba.User? user, {
    bool allowUidChange = false,
  }) async {
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
      if (!allowUidChange &&
          !UpgradeAccountScreen.preservesGuestIdentity(
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
        AppLogger.d('⚠️ Deferred score sync after account upgrade failed: $e');
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
      AppLogger.d('UpgradeAccountScreen finalize failed: $e');
      AppLogger.stack(stackTrace);
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
          _allowExistingAccountUidChange = false;
        });
      }
    }
  }

  Future<void> _resolveExistingAccountCollision(
    fba.FirebaseAuthException exception,
  ) async {
    if (_isResolvingExistingAccountCollision) return;

    setState(() {
      _isResolvingExistingAccountCollision = true;
    });

    try {
      if (exception.code == 'credential-already-in-use' &&
          exception.credential != null) {
        try {
          if (mounted) {
            setState(() {
              _allowExistingAccountUidChange = true;
            });
          }
          final credential = await fba.FirebaseAuth.instance
              .signInWithCredential(exception.credential!);
          await _finalizeUpgrade(credential.user, allowUidChange: true);
          return;
        } catch (e, stackTrace) {
          AppLogger.d(
            'UpgradeAccountScreen existing-account auto sign-in failed: $e',
          );
          AppLogger.stack(stackTrace);
          if (mounted) {
            setState(() {
              _allowExistingAccountUidChange = false;
            });
          }
        }
      }

      final email = exception.email?.trim();
      if (!mounted) return;

      // Note: FirebaseAuth.fetchSignInMethodsForEmail was removed in
      // firebase_auth 5+ due to email-enumeration security concerns.
      // existingAccountRecoveryMessage falls back to a generic "different
      // sign-in method" message when signInMethods is empty, which is correct.
      final message = AuthUiHelper.existingAccountRecoveryMessage(email: email);

      final shouldOpenLogin =
          await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Use Existing Account'),
                content: Text(message),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Maybe Later'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Go to Sign In'),
                  ),
                ],
              );
            },
          ) ??
          false;
      if (!shouldOpenLogin || !mounted) return;

      try {
        final currentUser = fba.FirebaseAuth.instance.currentUser;
        if (currentUser != null && currentUser.isAnonymous) {
          await fba.FirebaseAuth.instance.signOut();
        }
      } catch (e, stackTrace) {
        AppLogger.d('UpgradeAccountScreen anonymous sign-out failed: $e');
        AppLogger.stack(stackTrace);
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingExistingAccountCollision = false;
        });
      }
    }
  }

  Future<void> _handleAuthFailure(Exception exception) async {
    final errorCode = exception is fba.FirebaseAuthException
        ? exception.code
        : exception.runtimeType.toString();
    unawaited(
      AnalyticsService.instance.logEvent(
        'auth_upgrade_failed',
        parameters: {
          'flow': 'upgrade',
          'error_code': errorCode,
          'failure_reason': UpgradeAccountScreen.authFailureReason(exception),
        },
      ),
    );

    if (AuthUiHelper.isExistingAccountCollision(exception) &&
        exception is fba.FirebaseAuthException) {
      await _resolveExistingAccountCollision(exception);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(UpgradeAccountScreen.authFailureMessage(exception)),
      ),
    );
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
              if (UpgradeAccountScreen.shouldShowAppleUnavailableMessage(
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
          );
        },
        actions: [
          AuthStateChangeAction<CredentialLinked>((context, state) {
            _finalizeUpgrade(
              state.user,
              allowUidChange: _allowExistingAccountUidChange,
            );
          }),
          AuthStateChangeAction<SignedIn>((context, state) {
            // Fallback for providers that emit SignedIn after successful link.
            _finalizeUpgrade(
              state.user,
              allowUidChange: _allowExistingAccountUidChange,
            );
          }),
          AuthStateChangeAction<AuthFailed>((context, state) async {
            await _handleAuthFailure(state.exception);
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
