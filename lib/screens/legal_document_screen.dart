/*
 DOC: Screen
 Title: Legal Document Screen
 Purpose: Displays local legal document text (terms or privacy policy).
*/
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class LegalDocumentScreenArgs {
  final String title;
  final String assetPath;

  const LegalDocumentScreenArgs({required this.title, required this.assetPath});
}

class LegalDocumentScreen extends StatelessWidget {
  static const routeName = '/legal/document';

  static const termsTitle = 'Terms of Service';
  static const privacyTitle = 'Privacy Policy';
  static const termsAssetPath = 'assets/legal/terms_of_service.txt';
  static const privacyAssetPath = 'assets/legal/privacy_policy.txt';

  const LegalDocumentScreen({super.key});

  /// Returns route args for the terms document.
  static const termsArgs = LegalDocumentScreenArgs(
    title: termsTitle,
    assetPath: termsAssetPath,
  );

  /// Returns route args for the privacy policy document.
  static const privacyArgs = LegalDocumentScreenArgs(
    title: privacyTitle,
    assetPath: privacyAssetPath,
  );

  /// Loads one legal document from local bundled assets.
  Future<String> _loadDocument(String path) {
    return rootBundle.loadString(path);
  }

  /// Builds legal document content with loading and error states.
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! LegalDocumentScreenArgs) {
      return Scaffold(
        appBar: AppBar(title: const Text('Legal')),
        body: const Center(child: Text('Missing legal document data.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(args.title)),
      body: FutureBuilder<String>(
        future: _loadDocument(args.assetPath),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('Could not load legal document. Please try again.'),
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                snapshot.data ?? '',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          );
        },
      ),
    );
  }
}
