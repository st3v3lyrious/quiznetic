/*
 DOC: Widget
 Title: Legal Consent Notice
 Purpose: Renders consent copy with links to terms and privacy documents.
*/
import 'package:flutter/material.dart';
import 'package:quiznetic_flutter/screens/legal_document_screen.dart';

class LegalConsentNotice extends StatelessWidget {
  static const termsLinkKey = Key('legal-terms-link');
  static const privacyLinkKey = Key('legal-privacy-link');
  static const copyKey = Key('legal-consent-copy');

  final EdgeInsetsGeometry? padding;
  final MainAxisAlignment mainAxisAlignment;

  const LegalConsentNotice({
    super.key,
    this.padding,
    this.mainAxisAlignment = MainAxisAlignment.center,
  });

  /// Maps row-style alignment to wrap alignment for responsive text wrapping.
  WrapAlignment _toWrapAlignment(MainAxisAlignment value) {
    switch (value) {
      case MainAxisAlignment.start:
        return WrapAlignment.start;
      case MainAxisAlignment.end:
        return WrapAlignment.end;
      case MainAxisAlignment.spaceBetween:
        return WrapAlignment.spaceBetween;
      case MainAxisAlignment.spaceAround:
        return WrapAlignment.spaceAround;
      case MainAxisAlignment.spaceEvenly:
        return WrapAlignment.spaceEvenly;
      case MainAxisAlignment.center:
        return WrapAlignment.center;
    }
  }

  /// Pushes the Terms screen.
  void _openTerms(BuildContext context) {
    Navigator.of(context).pushNamed(
      LegalDocumentScreen.routeName,
      arguments: LegalDocumentScreen.termsArgs,
    );
  }

  /// Pushes the Privacy screen.
  void _openPrivacy(BuildContext context) {
    Navigator.of(context).pushNamed(
      LegalDocumentScreen.routeName,
      arguments: LegalDocumentScreen.privacyArgs,
    );
  }

  /// Builds legal consent copy and deep links.
  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor);

    final content = Column(
      children: [
        Text(
          'By continuing, you agree to our',
          key: copyKey,
          textAlign: TextAlign.center,
          style: textStyle,
        ),
        Wrap(
          alignment: _toWrapAlignment(mainAxisAlignment),
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          children: [
            TextButton(
              key: termsLinkKey,
              onPressed: () => _openTerms(context),
              child: const Text('Terms of Service'),
            ),
            Text('and', style: textStyle),
            TextButton(
              key: privacyLinkKey,
              onPressed: () => _openPrivacy(context),
              child: const Text('Privacy Policy'),
            ),
          ],
        ),
      ],
    );

    if (padding == null) {
      return content;
    }

    return Padding(padding: padding!, child: content);
  }
}
