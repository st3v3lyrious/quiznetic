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
  - [ ] `ENABLE_ADS=false` and `ENABLE_IAP=false` unless section 3 is fully green
  - [ ] `ENABLE_REWARDED_HINTS=false` and `ENABLE_PAID_HINTS=false` unless hint flow QA is complete

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

If revenue is required for launch, treat this entire section as `NO-GO` blocking.

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
- [ ] Platform permissions/prompts are reviewed (for example ATT on iOS if needed).

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
