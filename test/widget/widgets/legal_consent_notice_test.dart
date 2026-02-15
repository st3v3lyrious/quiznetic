import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/screens/legal_document_screen.dart';
import 'package:quiznetic_flutter/widgets/legal_consent_notice.dart';

void main() {
  testWidgets('renders consent copy and both links', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: LegalConsentNotice())),
    );

    expect(find.byKey(LegalConsentNotice.copyKey), findsOneWidget);
    expect(find.byKey(LegalConsentNotice.termsLinkKey), findsOneWidget);
    expect(find.byKey(LegalConsentNotice.privacyLinkKey), findsOneWidget);
  });

  testWidgets('terms link opens legal document route', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/': (_) => const Scaffold(body: LegalConsentNotice()),
          LegalDocumentScreen.routeName: (_) => const LegalDocumentScreen(),
        },
      ),
    );

    await tester.tap(find.byKey(LegalConsentNotice.termsLinkKey));
    await tester.pumpAndSettle();

    expect(find.text(LegalDocumentScreen.termsTitle), findsOneWidget);
  });
}
