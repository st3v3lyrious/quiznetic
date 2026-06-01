# MVP LAUNCH TEST CHECKLIST

Use this checklist on the release-candidate commit you plan to ship.

## 1) Release Candidate Inputs

- [ ] RC commit SHA is pinned: `________________`
- [ ] CI `Release Preflight` is green on this SHA.
- [ ] Local parity check passed: `RUN_FIRESTORE_RULES=1 ./tools/release_preflight.sh`.
- [ ] Launch-safe flags are confirmed:
  - [ ] `ENABLE_BACKEND_SUBMIT_SCORE=false`
  - [ ] `ENABLE_APPLE_SIGN_IN=false` (until provider setup is complete)
  - [ ] `ENABLE_CRASH_REPORTING=true`
  - [ ] `ENABLE_ANALYTICS=true`
  - [ ] **MVP SCOPE**: Ads and IAP removed; no monetization flags in this build

## 2) Manual Core Flow Smoke (Must Pass)

- [ ] Cold start -> splash -> entry choice.
- [ ] Guest flow: entry -> start quiz -> finish -> result screen shown.
- [ ] Guest score save works and guest score appears on leaderboard/profile.
- [ ] Account flow: sign in (Email/Google) -> start quiz -> finish -> result screen shown.
- [ ] Account score save works and account score appears on leaderboard/profile.
- [ ] Guest to account upgrade flow succeeds and keeps progress continuity.
- [ ] Connectivity resilience:
  - [ ] Save score while offline queues locally.
  - [ ] Reconnect sync pushes pending score successfully.
- [ ] Settings/legal links load correctly.
- [ ] Sign out returns to entry choice.

## 3) Monetization Priority Gate (Ads + IAP)

⚠️ **REMOVED FROM MVP SCOPE**: Ads and in-app purchases have been removed from the MVP launch to focus on core gameplay stability. This entire section is `SKIPPED` for this release.

**Post-MVP**: When monetization is re-enabled in future releases, restore this checklist section and follow `docs/MONETIZATION_SETUP.md` for safe activation.

---

### (Archived for reference: Monetization QA will be restored in post-MVP releases)

### Monetization QA Execution Matrix (Run in Order)

Use the build-define recipes in `docs/MONETIZATION_SETUP.md` and execute runs in
this order.

| Run ID | Device Target | Focus | Must Be Green Before Next Run |
| --- | --- | --- | --- |
| MZ-RUN-1 | Android emulator (debug) | Ads smoke with test IDs (home/result banner + interstitial fallback behavior). | Ads surface renders, app remains usable on ad failure/offline. |
| MZ-RUN-2 | iOS simulator (debug) | Ads smoke parity on iOS with test IDs. | Same as `MZ-RUN-1` on iOS. |
| MZ-RUN-3 | Android physical device (internal/sandbox account) | Full monetization flow: ads + remove-ads purchase + restore + hint flow. | All `MZ-ADS-*`, `MZ-IAP-*`, and `MZ-HINT-*` scenarios pass. |
| MZ-RUN-4 | iOS physical device (sandbox/TestFlight) | Full monetization flow parity on iOS. | Same pass criteria as `MZ-RUN-3` on iOS. |
| MZ-RUN-5 | Release-candidate config check | Final safety check for launch flags and rollback defaults. | Section 1 flags and Section 3 decision align with launch mode. |

### Scenario Matrix (Record Evidence Per Row)

| ID | Scope | Device Requirement | Expected Result | Evidence | Status |
| --- | --- | --- | --- | --- | --- |
| MZ-ADS-01 | Home banner loads when ads enabled and no `remove_ads` entitlement. | Simulator or physical (both platforms). | Banner displays without blocking gameplay; `ad_impression` observed. | Screenshot + analytics/log note | [ ] |
| MZ-ADS-02 | Result ad strategy works (interstitial-first when enabled, banner fallback on failure). | Simulator + physical (both platforms). | Interstitial shows when available; on failure app continues and result banner path works. | Screen recording + fallback note | [ ] |
| MZ-ADS-03 | Ads suppressed after `remove_ads` entitlement is granted. | Physical required (both platforms). | No banner/interstitial shown after successful remove-ads purchase and app restart. | Before/after screenshots | [ ] |
| MZ-IAP-01 | Remove Ads purchase success path. | Physical required (both platforms). | Purchase completes, entitlement saved, UI updates without restart requirement. | Store sandbox receipt + UI screenshot | [ ] |
| MZ-IAP-02 | Purchase cancel/failure path is safe. | Physical required (both platforms). | User gets clear non-technical message; app remains usable; no false entitlement. | Screenshot + note | [ ] |
| MZ-IAP-03 | Restore purchases re-applies entitlement. | Physical required (both platforms). | Restore succeeds and `remove_ads` entitlement is restored after reinstall/sign-out+sign-in. | Restore logs + UI screenshot | [ ] |
| MZ-HINT-01 | Rewarded hint grant path (remove 2 wrong answers). | Physical preferred (both), simulator acceptable for smoke. | Rewarded completion grants hint and removes exactly two wrong answers. | Quiz capture + event note | [ ] |
| MZ-HINT-02 | Rewarded hint session cap enforcement. | Simulator or physical (both platforms). | Free hint count decreases to zero at configured cap (`REWARDED_HINTS_PER_SESSION`). | Screenshot of hint counter transitions | [ ] |
| MZ-HINT-03 | Paid hint fallback after free cap. | Physical required (both platforms). | Paid hint purchase flow starts only after free cap exhausted; successful purchase grants one hint. | Purchase + quiz capture | [ ] |
| MZ-HINT-04 | Rewarded unavailable fallback behavior. | Simulator or physical (both platforms). | If rewarded ad is unavailable, flow falls back to paid path when enabled; otherwise user-safe unavailable state is shown. | Screenshot + config note | [ ] |
| MZ-AN-01 | Monetization analytics baseline. | At least one platform physical. | Revenue events are emitted (`ad_impression`, `ad_click`, `iap_started`, `iap_success`, `iap_restore`). | Analytics debug output/query screenshot | [ ] |
| MZ-COMP-01 | Compliance baseline verification. | Documentation + store console check. | Privacy policy/store metadata include ads + IAP disclosures; ATT decision documented for current scope. | Links/screenshots | [ ] |

### Ads Readiness

- [ ] Ad network account is approved and payment profile is configured.
- [ ] Test ad unit IDs are used in non-release builds.
- [ ] Production ad unit IDs are wired for release builds only.
- [ ] At least one ad placement is implemented and visible in QA.
- [ ] App remains usable when ad load fails or network is offline.
- [ ] Frequency cap / pacing behavior is defined and tested.

### IAP Readiness

- [ ] Products are created in Play Console/App Store Connect.
- [ ] Product IDs in code match store configuration exactly.
- [ ] Sandbox purchase succeeds end-to-end for each product.
- [ ] Purchase cancel/failure path is user-safe and recoverable.
- [ ] Restore purchases works and re-applies entitlement.
- [ ] Entitlement state persists across app restart and sign-in changes.
- [ ] Receipt/transaction verification strategy is defined:
  - [ ] Backend validation implemented, or
  - [ ] Temporary client-side approach accepted with explicit risk.

### Monetization Analytics and Compliance

- [ ] Revenue events are tracked (`ad_impression`, `ad_click`, `iap_started`, `iap_success`, `iap_restore`).
- [ ] Dashboard/queries exist to review monetization conversion and failures.
- [ ] Privacy policy copy includes ads/IAP data handling.
- [ ] Store listing metadata includes pricing/IAP disclosures.
- [ ] Platform permissions/prompts are reviewed (ATT runtime prompt required only if using IDFA, personalized ads, or advanced attribution).
- [ ] Scenario matrix above is fully green on both Android and iOS physical-device runs (`MZ-RUN-3` and `MZ-RUN-4`).

## 4) Launch Decision

- [ ] `GO` Public MVP with revenue enabled.
  - Conditions: Sections 1, 2, and 3 are fully green.
- [ ] `GO` Limited soft launch (no monetization).
  - Conditions: Sections 1 and 2 are green, Section 3 has open items.
  - Action: keep monetization as top priority before full public rollout.
- [ ] `NO-GO`.
  - Conditions: Any blocker in Sections 1 or 2.

## 5) Signoff

- Product owner: `________________` Date: `____________`
- Engineering owner: `________________` Date: `____________`
- QA owner: `________________` Date: `____________`

## 6) 72-Hour Post-Launch Watch

- [ ] Crash-free startup/core-loop remains stable.
- [ ] Auth failure rate is within normal baseline.
- [ ] Score save and leaderboard load error rates are within baseline.
- [ ] Monetization funnel health is reviewed at least twice daily (if enabled).
