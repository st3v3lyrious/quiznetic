import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:quiznetic_flutter/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app launch integration smoke test', (tester) async {
    app.main();
    await tester.pumpAndSettle();
  }, skip: true);
}
