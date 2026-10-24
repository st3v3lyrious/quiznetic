# M32 C1 — Web Analytics consent

Related to [M32 / GitHub #159](https://github.com/st3v3lyrious/quiznetic/issues/159).
The issue and Notion M32 contain separate C1–C6 and V1–V4 checklists from the
Analytics/legal audit. This change implements C1 only. Broader legal copy,
deletions, leaderboard names, event deduplication, GA4 reports and production
verification remain open.

## Behavior

- `web/analytics_consent.js` runs before Flutter. FlutterFire skips automatic
  Analytics injection. There is no Analytics SDK import, measurement event or
  screen view until an explicit opt-in; rejected events are not buffered.
- Accept and Refuse are equally styled. A persistent public control is available
  on every route, including entry/login/recovery/legal pages, without an account.
- The browser choice (version 1) expires after 180 days for either answer.
  Missing, corrupt or expired storage requires a new choice. SDK failures keep
  measurement off. The compile-time `ENABLE_ANALYTICS=false` remains a kill switch.
- Grant imports the Firebase Analytics SDK matching Firebase Core's SDK version.
  Consent for advertising remains denied; Google signals and ad personalization
  are disabled. Native app Analytics behavior is unchanged.
- Withdrawal stops application events immediately, sets GA's disable flag before
  denying consent, disables collection, removes accessible first-party GA cookies
  at root/parent-domain scope, persists refusal and reloads to remove SDK listeners.
  The panel warns that reloading may end an active quiz; saved scores remain.
  Already dispatched requests/data are not retroactively erased.
- The bundled privacy text and its Markdown counterpart describe this preference.
  They are not a complete legal review (C2/C4 remain open).

## Validation and reproduction

Run `flutter test --no-pub`, `flutter analyze --no-pub` and
`tools/check_unit_coverage.sh` with Flutter on PATH.

For browser checks, start the Auth/Firestore demo emulators and build the
`integration_test/web_navigation_app.dart` entrypoint as described in
[the navigation review](../m32/README.md). For this check use
`--dart-define=ENABLE_ANALYTICS=true --dart-define=ENABLE_CRASH_REPORTING=false`.
Serve `build/web` on 127.0.0.1:7357, then:

```sh
cd playwright
CONSENT_EMULATORS=true npx playwright test tests/analytics-consent.spec.ts --workers=1
```

`FIREBASE_SDK_CACHE` optionally serves verified SDK files through Playwright as
in the navigation harness. UI checks run the real Flutter emulator build at
1280×900, 390×844 and 768×1024. They assert no Analytics/gtag/GA requests or cookies
before choice and after refusal/reload, then reopen public preferences/privacy.

The separate browser bridge fixture deliberately stubs the Analytics module and
Firebase Core config to test loading order, ad defaults, GA-cookie removal and
cancellation of an in-flight grant. Controller tests cover acceptance/restoration,
withdrawal, expiry, failures, disabled builds and event suppression. These do not
claim that GA4 has received events. Production cookies/network, GA4 receipt and
native Safari still require separate checks before C1/M32 closure.

## Captures

Real Chromium captures from the demo emulator build (the red emulator warning is
test-only). No production credentials or writes.

| State | Desktop | Mobile | Tablet |
| --- | --- | --- | --- |
| Before choice | [Capture](desktop-before-choice.png) | [Capture](mobile-before-choice.png) | [Capture](tablet-before-choice.png) |
| Public privacy and preferences | [Capture](desktop-privacy-preferences.png) | [Capture](mobile-privacy-preferences.png) | [Capture](tablet-privacy-preferences.png) |

Recorded local validation: 256 Flutter tests; 119 unit tests, 65.05% coverage
(minimum 25%); clean static analysis and repository review; 5 Chromium browser
scenarios passing. Acceptance/restoration/withdrawal in the real Flutter UI use a
controlled Analytics module (Core/Auth remain real); this proves integration and
cookie cleanup without claiming GA4 delivery. Six real viewport captures included. Normal and emulator release Web builds pass;
the pre-existing SocialIcons font warning remains.
