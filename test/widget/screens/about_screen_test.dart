import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/config/brand_config.dart';
import 'package:quiznetic_flutter/screens/about_screen.dart';
import 'package:quiznetic_flutter/screens/legal_document_screen.dart';

void main() {
  test('exposes the expected route name', () {
    expect(AboutScreen.routeName, equals('/about'));
  });

  testWidgets('renders app metadata and support info', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AboutScreen()));
    await tester.pumpAndSettle();

    expect(find.text(BrandConfig.appName), findsOneWidget);
    expect(find.text(BrandConfig.tagline), findsOneWidget);
    expect(find.text(BrandConfig.appVersionLabel), findsOneWidget);
    expect(find.text(BrandConfig.supportEmail), findsOneWidget);
  });

  testWidgets('terms link opens terms document', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/': (_) => const AboutScreen(),
          LegalDocumentScreen.routeName: (_) => const LegalDocumentScreen(),
        },
      ),
    );

    await tester.tap(find.byKey(const Key('about-terms-link')));
    await tester.pumpAndSettle();

    expect(find.text(LegalDocumentScreen.termsTitle), findsOneWidget);
  });

  testWidgets('privacy link opens privacy document', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/': (_) => const AboutScreen(),
          LegalDocumentScreen.routeName: (_) => const LegalDocumentScreen(),
        },
      ),
    );

    await tester.tap(find.byKey(const Key('about-privacy-link')));
    await tester.pumpAndSettle();

    expect(find.text(LegalDocumentScreen.privacyTitle), findsOneWidget);
  });
}
