import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/config/brand_config.dart';
import 'package:quiznetic_flutter/widgets/feedback_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('copies only a report template after an explicit action', (
    tester,
  ) async {
    final copies = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copies.add((call.arguments as Map)['text'] as String);
          }
          return null;
        });
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: FeedbackDialog())),
    );
    expect(copies, isEmpty);
    expect(find.text(BrandConfig.supportEmail), findsOneWidget);
    await tester.tap(find.text('Copy feedback template'));
    await tester.pumpAndSettle();
    expect(copies, [FeedbackDialog.template]);
    expect(copies.single, contains('What I expected:'));
    expect(
      find.text('Template copied. Paste it into your email app.'),
      findsOneWidget,
    );
  });

  testWidgets('clipboard failure keeps the contact and a useful fallback', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            throw PlatformException(code: 'denied');
          }
          return null;
        });
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: FeedbackDialog())),
    );
    await tester.tap(find.text('Copy feedback template'));
    await tester.pumpAndSettle();
    expect(
      find.text('Copy unavailable. You can write to the address above.'),
      findsOneWidget,
    );
    expect(find.text(BrandConfig.supportEmail), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
