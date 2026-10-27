// Public, account-independent control for optional Web audience measurement.
import 'package:flutter/material.dart';

import '../services/analytics_consent.dart';

class AnalyticsConsentPanel extends StatefulWidget {
  const AnalyticsConsentPanel({
    super.key,
    required this.child,
    required this.onPrivacy,
    this.consent,
  });
  final Widget child;
  final VoidCallback onPrivacy;
  final AnalyticsConsent? consent;

  @override
  State<AnalyticsConsentPanel> createState() => _AnalyticsConsentPanelState();
}

class _AnalyticsConsentPanelState extends State<AnalyticsConsentPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final consent = widget.consent ?? AnalyticsConsent.instance;
    if (!consent.available) {
      return Column(
        children: [
          Expanded(child: widget.child),
          SafeArea(
            top: false,
            child: TextButton(
              onPressed: widget.onPrivacy,
              child: const Text('Analytics off · Privacy Policy'),
            ),
          ),
        ],
      );
    }
    return ListenableBuilder(
      listenable: consent,
      builder: (context, _) {
        final show = consent.ready && (consent.choice == null || _expanded);
        return Column(
          children: [
            Expanded(child: widget.child),
            Material(
              color: Theme.of(context).colorScheme.surface,
              elevation: 8,
              child: SafeArea(
                minimum: const EdgeInsets.only(bottom: 24),
                top: false,
                child: show
                    ? ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.sizeOf(context).height * .55,
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 720),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Optional analytics',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'With your permission, Google Analytics uses cookies to measure visits and quiz activity. Refusing does not affect gameplay. You can change your choice here at any time. Advertising features stay off.',
                                  ),
                                  if (consent.error != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        consent.error!,
                                        semanticsLabel: consent.error,
                                      ),
                                    ),
                                  if (consent.choice == true)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Text(
                                        'Refusing now reloads the page and may end an active quiz. Saved scores are kept.',
                                      ),
                                    ),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 4,
                                    children: [
                                      OutlinedButton(
                                        onPressed: consent.busy
                                            ? null
                                            : () async {
                                                await consent.choose(true);
                                                if (mounted &&
                                                    consent.choice != null) {
                                                  setState(
                                                    () => _expanded = false,
                                                  );
                                                }
                                              },
                                        child: const Text('Accept analytics'),
                                      ),
                                      OutlinedButton(
                                        onPressed: consent.busy
                                            ? null
                                            : () async {
                                                await consent.choose(false);
                                                if (mounted &&
                                                    consent.choice != null) {
                                                  setState(
                                                    () => _expanded = false,
                                                  );
                                                }
                                              },
                                        child: const Text('Refuse analytics'),
                                      ),
                                      TextButton(
                                        onPressed: widget.onPrivacy,
                                        child: const Text('Privacy Policy'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    : TextButton(
                        onPressed: consent.ready && !consent.busy
                            ? () => setState(() => _expanded = true)
                            : null,
                        child: Text(
                          'Analytics preferences${consent.choice == true ? ' · On' : ' · Off'}',
                        ),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}
