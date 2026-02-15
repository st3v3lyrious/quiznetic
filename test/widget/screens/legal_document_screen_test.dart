import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/screens/legal_document_screen.dart';

void main() {
  testWidgets('shows missing-data state when args are absent', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LegalDocumentScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Missing legal document data.'), findsOneWidget);
  });

  testWidgets('loads and shows terms document', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/': (_) => const _RootProbe(),
          LegalDocumentScreen.routeName: (_) => const LegalDocumentScreen(),
        },
      ),
    );

    final context = tester.element(find.byType(_RootProbe));
    Navigator.of(context).pushNamed(
      LegalDocumentScreen.routeName,
      arguments: LegalDocumentScreen.termsArgs,
    );

    await tester.pumpAndSettle();

    expect(find.text(LegalDocumentScreen.termsTitle), findsOneWidget);
    expect(find.textContaining('Quiznetic Terms of Service'), findsOneWidget);
  });
}

class _RootProbe extends StatelessWidget {
  const _RootProbe();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SizedBox.shrink());
  }
}
