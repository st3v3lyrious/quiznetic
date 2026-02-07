/*
 DOC: Screen
 Title: Upgrade Account Screen
 Purpose: Lets anonymous users link a permanent provider account while preserving guest identity.
*/
import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_apple/firebase_ui_oauth_apple.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:quiznetic_flutter/config/app_config.dart';
import 'package:quiznetic_flutter/services/score_repository.dart';
import 'package:quiznetic_flutter/services/user_checker.dart';

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

  /// Builds provider list for anonymous-account upgrade.
  @visibleForTesting
  static List<AuthProvider> buildProviders({required String googleClientId}) {
    return [
      EmailAuthProvider(),
      if (isGoogleProviderEnabled(googleClientId))
        GoogleProvider(clientId: googleClientId.trim()),
      AppleProvider(),
    ];
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

    setState(() {
      _isProcessingUpgrade = true;
    });

    try {
      if (!UpgradeAccountScreen.preservesGuestIdentity(
        initialAnonymousUid: _initialAnonymousUid,
        user: user,
      )) {
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
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
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

    // Offer the firebase_ui_auth sign-in screen to upgrade anonymous users.
    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade Account')),
      body: SignInScreen(
        providers: UpgradeAccountScreen.buildProviders(
          googleClientId: resolvedGoogleClientId,
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
        ],
        footerBuilder: (context, _) => TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Maybe Later'),
        ),
      ),
    );
  }
}
