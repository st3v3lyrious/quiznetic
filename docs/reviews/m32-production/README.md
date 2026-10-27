# M32 production account checks and login destination correction

Related to GitHub #159. Checks performed October 27, 2026. C4 and GA4 account
access remain with the owner. No player data, billing configuration, Functions
deployment or existing public pseudonym was changed.

## Confirmed on the public deployment

Deployment `dpl_2LsXykFf9wXGZBNPSHajTZ56E9Tq`, source `e2b9fb2`, was tested at
https://quiznetic.eirenya.com with Chromium 156 / Playwright 1.64.1. One synthetic
guest was created specifically for this validation and upgraded through the UI.

- A complete Flags quiz saved 2/15 and one attempt.
- Email/password registration kept the guest UID, score and attempt. The account
  session survived refresh.
- A complete Capitals quiz saved 3/15 and published the same score under `Player`.
- Refreshing results displayed session recovery and left exactly two attempts.
- The Google button opened `accounts.google.com`. No Google credentials were
  supplied, so this does **not** establish a completed Google sign-in.
- No JavaScript page errors were observed in those account/quiz steps.

[Recorded observations](live-story-report.json). The temporary runtime expired
before its full artifact export; the report preserves the executed log results,
not a browser trace. Automated input initially failed to update Flutter form
state; keyboard entry resolved it without an application change.

## Defect reproduced and corrected locally

Open `/#/leaderboard?category=capital&difficulty=expert` while signed out, choose
sign-in, refresh the login screen, and sign in. The public build loses
`difficulty=expert` and displays Capitals / Easy.

Flutter Web decodes the complete reported route URI before writing browser
history. An ampersand inside the nested `next` destination therefore becomes an
outer query separator. `AppRouteParser.restoreRouteInformation` now protects
that nested value at the browser reporting boundary. Internal destination
validation remains in `AppLocation`; no external redirect is introduced.

The regression test follows Flutter Web's actual URI serialization and checks
both `/login` and `/entry`. It confirms that both destination filters survive a
refresh. The corrected release build has **not** been deployed by this QA work.

## Corrected build browser matrix

The local release build used the existing public Firebase/Google configuration
and real `quiznetic-30734` Auth/Firestore. These are local-build checks, separate
from the public deployment observations above.

| Browser | Desktop 1280×900 | Mobile viewport 390×844 | Tablet viewport 768×1024 |
| --- | --- | --- | --- |
| Chromium 145 | Passed | Passed | Passed |
| Firefox 146 | Passed | Passed | Passed |
| Linux WebKit 26 | Inconclusive / failed clean-console gate | Not run | Not run |
| Native Safari macOS/iOS | Not available | Not available | Not available |

Each passing scenario checks email sign-in with a refreshed destination link,
leaderboard filter refresh, browser back/forward, profile and settings refresh,
difficulty refresh, invalid quiz/result link recovery, document horizontal
overflow, and permanent-account sign-out. Browser viewport simulation is not a
physical mobile-device test. No page errors occurred in the six passing cases.

WebKit reached seven navigation checks but emitted Firestore WebChannel
access-control errors with Playwright HTTPS forwarding. A native-transport
follow-up timed out after login. The environment/application boundary remains
unresolved; neither run proves a production Safari regression or a passing
Safari result. Testing stopped at that boundary.

The managed environment's configured proxy and CA trust remained enabled.
Chromium/Firefox used Playwright HTTPS forwarding to work with the proxy;
WebKit's native transport was also tried. Firefox required an explicit `en-US`
locale to avoid a headless startup language-tag error. No TLS verification was
disabled. [Sanitized machine report](matrix-report.json).

Actual captures of the corrected build, containing no account identifiers:

- [Desktop](desktop-difficulty.png)
- [Mobile viewport](mobile-difficulty.png)
- [Tablet viewport](tablet-difficulty.png)

## Reproduction

Install the repository's Playwright package and the selected browser binaries.
The [operator-only script](live-account-navigation.cjs) accepts a private JSON
manifest via `QA_ACCOUNT_FILE`, with `project`, `uid`, `email`, `password` and
`createdByThisValidation: true`. It accepts only the synthetic address pattern
`m32-web-qa-<UUID>@example.test` and the explicit Quiznetic project. Create and
verify that dedicated test account first; never supply a player account.

```sh
NODE_PATH="$PWD/playwright/node_modules" \
QA_ACCOUNT_FILE=/private/controlled-account.json \
QA_OUTPUT_DIR=test-results/m32-production \
QA_ENGINES=chromium,firefox \
PLAYWRIGHT_BASE_URL=http://127.0.0.1:7361 \
node docs/reviews/m32-production/live-account-navigation.cjs
```

Use the public URL only when explicitly verifying its deployed build. Optional
`QA_<ENGINE>_EXECUTABLE` variables select installed browsers. In this managed
environment, `QA_ROUTE_HTTPS=true` uses verified Playwright HTTPS forwarding;
`PLAYWRIGHT_DISABLE_FORCED_CHROMIUM_PROXIED_LOOPBACK=1` allows the local server
while preserving the proxy for remote requests. Neither option disables TLS
verification. Keep manifests, sessions, raw failure captures and credentials
outside Git. Only sanitized reports belong in this directory.

Validation: 138 widget tests, including the new browser-serialization regression;
122 unit tests; unit coverage 27.18% (required 25%); static analysis and repository
review clean; release Web build succeeds. No Firestore rules changed in this PR.

## Test-data cleanup and remaining release checks

The synthetic Auth user, profile, recursive private data and all its leaderboard
entries were deleted with C3 after these tests. Absence was verified. Its minimal
deletion marker must remain until October 27, 2026, 18:58:47 UTC (19:58:47 Paris).
An authorized local cleanup process is scheduled for ten seconds after that time;
it rechecks the exact private manifest, marker timestamps and absence of Auth/data
before removal. The private operator result is
`/workspace/quiznetic-web-qa/marker-cleanup-result.json`; until it reports
`complete`, final marker removal is pending. No player data was deleted.

Before closing M32:

1. Merge/publish the navigation correction after required CI and verify the same
   Capitals / Expert login-refresh scenario on the public build.
2. Complete native Safari macOS/iOS: Email and controlled Google login, both quiz
   categories, score persistence, refresh/back/forward, consent and sign-out.
3. Review C4 owner facts and GA4 receipt/configuration with the owner's access.
   These tests did not establish GA4 dashboard delivery.
4. Confirm the delayed test-marker cleanup result. C3's earlier validation stays
   complete; this marker belongs to the subsequent Web QA account.
5. Run the small beta-feedback protocol below. No invitations were sent.

## Small beta-feedback protocol (M28)

When the owner is ready, ask a small initial group to try the public URL on their
usual device. Request one Flags quiz, one Capitals quiz, and an optional account
upgrade. Collect browser/device, task attempted, expected vs actual behavior,
reproduction steps and whether the issue blocks play. Screenshots should omit
email, credentials and other personal data. Track actionable defects separately
from suggestions, fix blocking defects, then record the release decision in #159.
