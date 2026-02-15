/*
 DOC: Screen
 Title: About Screen
 Purpose: Shows app summary, version metadata, support contact, and legal links.
*/
import 'package:flutter/material.dart';
import 'package:quiznetic_flutter/config/brand_config.dart';
import 'package:quiznetic_flutter/screens/legal_document_screen.dart';

class AboutScreen extends StatelessWidget {
  static const routeName = '/about';

  const AboutScreen({super.key});

  /// Pushes terms-of-service legal document.
  void _openTerms(BuildContext context) {
    Navigator.of(context).pushNamed(
      LegalDocumentScreen.routeName,
      arguments: LegalDocumentScreen.termsArgs,
    );
  }

  /// Pushes privacy-policy legal document.
  void _openPrivacy(BuildContext context) {
    Navigator.of(context).pushNamed(
      LegalDocumentScreen.routeName,
      arguments: LegalDocumentScreen.privacyArgs,
    );
  }

  /// Builds app metadata and legal/support links.
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          children: [
            Center(
              child: Image.asset(
                'assets/images/logo-no-background.png',
                height: 84,
                semanticLabel: BrandConfig.logoSemanticLabel,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              BrandConfig.appName,
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              BrandConfig.tagline,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Card(
              child: Column(
                children: const [
                  ListTile(
                    leading: Icon(Icons.new_releases_outlined),
                    title: Text('Version'),
                    subtitle: Text(BrandConfig.appVersionLabel),
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.email_outlined),
                    title: Text('Support'),
                    subtitle: Text(BrandConfig.supportEmail),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    key: const Key('about-terms-link'),
                    leading: const Icon(Icons.gavel_outlined),
                    title: const Text('Terms of Service'),
                    onTap: () => _openTerms(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    key: const Key('about-privacy-link'),
                    leading: const Icon(Icons.policy_outlined),
                    title: const Text('Privacy Policy'),
                    onTap: () => _openPrivacy(context),
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
