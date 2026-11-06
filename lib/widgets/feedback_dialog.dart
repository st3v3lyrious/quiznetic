import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quiznetic_flutter/config/brand_config.dart';

/// Lets players prepare a report without collecting account or device data.
class FeedbackDialog extends StatefulWidget {
  const FeedbackDialog({super.key});

  static String get template =>
      'To: ${BrandConfig.supportEmail}\n'
      'Subject: Quiznetic beta feedback\n\n'
      'App version: ${BrandConfig.appVersionLabel}\n'
      'Browser and device (optional):\n'
      'What I tried:\n'
      'What I expected:\n'
      'What happened:\n'
      'Steps to reproduce:\n\n'
      'Remove names, email addresses, passwords and tokens from screenshots.';

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  bool _copying = false;
  String? _status;

  Future<void> _copy() async {
    setState(() => _copying = true);
    try {
      await Clipboard.setData(ClipboardData(text: FeedbackDialog.template));
      if (!mounted) return;
      setState(
        () => _status = 'Template copied. Paste it into your email app.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _status = 'Copy unavailable. You can write to the address above.',
      );
    } finally {
      if (mounted) setState(() => _copying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report a problem'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tell us what you tried, what you expected and what happened.',
            ),
            const SizedBox(height: 12),
            const SelectableText(BrandConfig.supportEmail),
            const SizedBox(height: 12),
            const Text(
              'Hide personal information in screenshots. Nothing is sent automatically.',
            ),
            if (_status != null) ...[
              const SizedBox(height: 12),
              Semantics(liveRegion: true, child: Text(_status!)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: _copying ? null : _copy,
          child: const Text('Copy feedback template'),
        ),
      ],
    );
  }
}
