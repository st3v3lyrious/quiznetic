# M32 C2 — Web privacy policy review

Related to [GitHub #159](https://github.com/st3v3lyrious/quiznetic/issues/159).
The displayed policy in `assets/legal/privacy_policy.txt` and the repository
reference in `docs/legal/PRIVACY_POLICY.md` have identical content, with only
Markdown heading syntax differing. The revision date is October 24, 2026.

## Changes

- Explain hosting and technical request data at Vercel, Firebase Authentication,
  Firestore and optional Google Analytics for Firebase (GA4).
- Explain measurement data and purpose, first-party `_ga` / `_ga_*` cookies,
  local functional storage and browser-local consent preferences.
- Separate essential service requests from optional measurement. Refusing
  Analytics does not disable hosting, Auth, Firestore or library delivery.
- Explain acceptance/refusal restoration, 180-day choice expiry, withdrawal and
  the difference between consent-choice duration and cookie/data retention.
- Identify the ad-free Web MVP without advertising or in-app purchases.

This is the C2 content revision. C4 remains open for the real controller/editor
identity, complete legal bases/rights, verified retention periods and provider
regions/transfers. C3 deletion operations, C5 leaderboard pseudonyms, C6 event
counting, GA4 dashboard checks and production verification remain separate.
No provider settings, application code, account data or deployment are changed.

## Verification

The existing legal-document, legal-notice and Settings widget tests check document
loading and navigation. Content parity is checked by converting Markdown headings
back to their plain-text equivalents and comparing the complete strings.

Browser QA uses the emulator-only Web build and real Chromium viewports:
1280×900, 390×844 and 768×1024. At each size, check privacy access from entry,
login and Settings, refresh of the privacy route, and scrolling from the updated
document header to the final ad-free section. Screenshots below are actual
viewport captures. The red Firebase emulator warning is test-only.

To reproduce the environment, follow the emulator build/server instructions in
[the navigation review](../m32/README.md) with the merged consent bootstrap.
Refuse Analytics, open Privacy Policy from the entry page, reload, then scroll
through the document. Repeat from login and from Settings in a demo guest session.

## Captures

| Position | Desktop | Mobile | Tablet |
| --- | --- | --- | --- |
| Document start | [Capture](desktop-privacy-top.png) | [Capture](mobile-privacy-top.png) | [Capture](tablet-privacy-top.png) |
| Document end | [Capture](desktop-privacy-bottom.png) | [Capture](mobile-privacy-bottom.png) | [Capture](tablet-privacy-bottom.png) |

C2 remains open until review, merge and deployed-build validation. These local
checks do not verify production cookies/requests, GA4 delivery or native Safari.

Recorded results: 11 existing Flutter widget tests passed; the emulator Web release
build passed (existing SocialIcons font warning unchanged); three Chromium QA
scenarios passed, each checking the entry/login/Settings privacy links, refreshed
route, delivered revised asset and document scrolling. Six captures were visually
inspected for readable wrapping and reachability of the final section. Repository
review and whitespace checks passed. No application-code or test-suite changes.
