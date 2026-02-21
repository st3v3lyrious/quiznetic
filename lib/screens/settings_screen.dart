/*
 DOC: Screen
 Title: Settings Screen
 Purpose: Provides account/session controls, legal links, and app preferences.
*/
import 'package:flutter/material.dart';
import 'package:quiznetic_flutter/config/brand_config.dart';
import 'package:quiznetic_flutter/screens/about_screen.dart';
import 'package:quiznetic_flutter/screens/entry_choice_screen.dart';
import 'package:quiznetic_flutter/screens/legal_document_screen.dart';
import 'package:quiznetic_flutter/services/accessibility_preferences.dart';
import 'package:quiznetic_flutter/services/auth_service.dart';
import 'package:quiznetic_flutter/services/entitlement_service.dart';
import 'package:quiznetic_flutter/services/iap_service.dart';

class SettingsScreen extends StatefulWidget {
  static const routeName = '/settings';

  final AuthService? authService;
  final IapService? iapService;
  final EntitlementService? entitlementService;

  const SettingsScreen({
    super.key,
    this.authService,
    this.iapService,
    this.entitlementService,
  });

  /// Creates state for settings controls and sign-out flow.
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = true;
  bool _hapticsEnabled = true;
  bool _showFlagDescriptions = false;
  bool _isSigningOut = false;
  bool _isLoadingRemoveAdsOffer = false;
  bool _isPurchasingRemoveAds = false;
  bool _isRestoringPurchases = false;
  RemoveAdsOffer? _removeAdsOffer;
  String? _monetizationStatusMessage;

  late final IapService _iapService;
  late final EntitlementService _entitlementService;

  /// Loads persisted accessibility preferences.
  @override
  void initState() {
    super.initState();
    _iapService = widget.iapService ?? IapService.instance;
    _entitlementService =
        widget.entitlementService ?? EntitlementService.instance;
    _loadAccessibilityPreferences();
    _loadMonetizationState();
  }

  Future<void> _loadAccessibilityPreferences() async {
    try {
      final enabled =
          await AccessibilityPreferences.showFlagDescriptionsEnabled();
      if (!mounted) return;
      setState(() {
        _showFlagDescriptions = enabled;
      });
    } catch (e, stackTrace) {
      debugPrint('Settings accessibility preference load failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _setShowFlagDescriptions(bool enabled) async {
    setState(() {
      _showFlagDescriptions = enabled;
    });
    try {
      await AccessibilityPreferences.setShowFlagDescriptionsEnabled(enabled);
    } catch (e, stackTrace) {
      debugPrint('Settings accessibility preference save failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _showFlagDescriptions = !enabled;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save accessibility preference.'),
        ),
      );
    }
  }

  Future<void> _loadMonetizationState() async {
    if (!_iapService.isEnabled) return;

    setState(() {
      _isLoadingRemoveAdsOffer = true;
    });

    try {
      await _iapService.initialize();
      final offer = await _iapService.loadRemoveAdsOffer();
      if (!mounted) return;
      setState(() {
        _removeAdsOffer = offer;
        _monetizationStatusMessage = null;
      });
    } catch (e, stackTrace) {
      debugPrint('Settings monetization load failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _monetizationStatusMessage =
            'Monetization options are currently unavailable.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRemoveAdsOffer = false;
        });
      }
    }
  }

  Future<void> _buyRemoveAds() async {
    if (_isPurchasingRemoveAds) return;

    setState(() {
      _isPurchasingRemoveAds = true;
    });

    final result = await _iapService.buyRemoveAds();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));

    setState(() {
      _isPurchasingRemoveAds = false;
    });
  }

  Future<void> _restorePurchases() async {
    if (_isRestoringPurchases) return;

    setState(() {
      _isRestoringPurchases = true;
    });

    final result = await _iapService.restorePurchases();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));

    setState(() {
      _isRestoringPurchases = false;
    });
  }

  Widget _buildMonetizationSection(TextTheme textTheme) {
    if (!_iapService.isEnabled) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<bool>(
      valueListenable: _entitlementService.hasRemoveAdsListenable,
      builder: (context, hasRemoveAds, _) {
        final offer = _removeAdsOffer;
        final offerSubtitle = offer != null && offer.canPurchase
            ? '${offer.title ?? 'Remove Ads'} - ${offer.price ?? ''}'
            : 'Purchase currently unavailable';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text('Support Quiznetic', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    key: const Key('settings-remove-ads-status'),
                    leading: Icon(
                      hasRemoveAds
                          ? Icons.verified_outlined
                          : Icons.workspace_premium_outlined,
                    ),
                    title: const Text('Remove Ads (Lifetime)'),
                    subtitle: Text(
                      hasRemoveAds
                          ? 'Active on this device/account.'
                          : offerSubtitle,
                    ),
                  ),
                  if (_isLoadingRemoveAdsOffer)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  if (!hasRemoveAds && !_isLoadingRemoveAdsOffer)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          key: const Key('settings-buy-remove-ads-button'),
                          onPressed:
                              (_isPurchasingRemoveAds ||
                                  offer == null ||
                                  !offer.canPurchase)
                              ? null
                              : _buyRemoveAds,
                          child: Text(
                            _isPurchasingRemoveAds
                                ? 'Starting purchase...'
                                : 'Buy Remove Ads',
                          ),
                        ),
                      ),
                    ),
                  const Divider(height: 1),
                  ListTile(
                    key: const Key('settings-restore-purchases-button'),
                    enabled: !_isRestoringPurchases,
                    leading: _isRestoringPurchases
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.restore),
                    title: const Text('Restore Purchases'),
                    subtitle: const Text('Recover previous purchases'),
                    onTap: _restorePurchases,
                  ),
                  if (_monetizationStatusMessage != null) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _monetizationStatusMessage!,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Returns account status text from the current auth session.
  String _accountStatus(AuthService authService) {
    try {
      final user = authService.currentUser;
      if (user == null) return 'Not signed in';
      if (user.isAnonymous) return 'Guest session';
      if ((user.email ?? '').trim().isNotEmpty) return user.email!.trim();
      return 'Signed in account';
    } catch (_) {
      return 'Unknown session';
    }
  }

  /// Signs out current session and returns to entry choice.
  Future<void> _signOut(AuthService authService) async {
    if (_isSigningOut) return;

    setState(() {
      _isSigningOut = true;
    });

    try {
      await authService.signOut();
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(EntryChoiceScreen.routeName, (_) => false);
    } catch (e, stackTrace) {
      debugPrint('Settings sign-out failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign out failed. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
        });
      }
    }
  }

  /// Pushes the terms-of-service document screen.
  void _openTerms() {
    Navigator.of(context).pushNamed(
      LegalDocumentScreen.routeName,
      arguments: LegalDocumentScreen.termsArgs,
    );
  }

  /// Pushes the privacy-policy document screen.
  void _openPrivacy() {
    Navigator.of(context).pushNamed(
      LegalDocumentScreen.routeName,
      arguments: LegalDocumentScreen.privacyArgs,
    );
  }

  /// Builds settings sections for account, legal, and app preferences.
  @override
  Widget build(BuildContext context) {
    final authService = widget.authService ?? AuthService();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            Text('Account', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.account_circle_outlined),
                    title: const Text('Current session'),
                    subtitle: Text(_accountStatus(authService)),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    key: const Key('settings-sign-out-button'),
                    enabled: !_isSigningOut,
                    leading: _isSigningOut
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.logout),
                    title: const Text('Sign Out'),
                    subtitle: const Text('Return to entry mode selection'),
                    onTap: () => _signOut(authService),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Gameplay', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    key: const Key('settings-sound-toggle'),
                    title: const Text('Sound Effects'),
                    subtitle: const Text('Play feedback sounds during quizzes'),
                    value: _soundEnabled,
                    onChanged: (value) {
                      setState(() {
                        _soundEnabled = value;
                      });
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    key: const Key('settings-haptics-toggle'),
                    title: const Text('Haptics'),
                    subtitle: const Text(
                      'Use vibration feedback when available',
                    ),
                    value: _hapticsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _hapticsEnabled = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Accessibility', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: SwitchListTile.adaptive(
                key: const Key('settings-flag-description-toggle'),
                title: const Text('Show flag descriptions'),
                subtitle: const Text(
                  'Enable a non-color flag description button during flag quizzes',
                ),
                value: _showFlagDescriptions,
                onChanged: _setShowFlagDescriptions,
              ),
            ),
            _buildMonetizationSection(textTheme),
            const SizedBox(height: 20),
            Text('Legal', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    key: const Key('settings-terms-link'),
                    leading: const Icon(Icons.gavel_outlined),
                    title: const Text('Terms of Service'),
                    onTap: _openTerms,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    key: const Key('settings-privacy-link'),
                    leading: const Icon(Icons.policy_outlined),
                    title: const Text('Privacy Policy'),
                    onTap: _openPrivacy,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('App', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    key: const Key('settings-about-link'),
                    leading: const Icon(Icons.info_outline),
                    title: const Text('About'),
                    subtitle: const Text('Version, support, and app details'),
                    onTap: () {
                      Navigator.of(context).pushNamed(AboutScreen.routeName);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.new_releases_outlined),
                    title: const Text('App Version'),
                    subtitle: const Text(BrandConfig.appVersionLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
