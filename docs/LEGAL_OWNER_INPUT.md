# M32 C4 — Information the owner must validate

This internal brief is not a published legal notice and does not assert legal
compliance. No placeholders below are inserted into the public policy.

## Facts already documented

- Product: Quiznetic Web at quiznetic.eirenya.com, hosted on Vercel.
- Current published privacy/support contact: quizneticapp@gmail.com.
- Firebase Auth/Firestore support accounts and gameplay; optional GA4 measurement
  is controlled separately by browser consent. Advertising/IAP are disabled.
- C2 documents providers, browser storage and optional measurement. C3 documents
  the in-scope deletion procedure and data it cannot erase remotely.

## Owner decisions or verified configuration still needed

| Item | Information needed |
| --- | --- |
| Legal editor/controller | Real individual or legal entity name; legal status/registration where applicable; country and required postal/contact information. Do not infer this from a GitHub handle or EIRENYA branding. |
| Markets/jurisdiction | Where the editor is established and the intended audience; applicable jurisdiction and any mandatory consumer provisions. |
| Purposes/legal bases | Validate the basis for account/gameplay operations, security/abuse controls and optional Analytics, including how rights apply in the relevant jurisdiction. |
| Retention | Define account inactivity/deletion policy, score/attempt retention and support/security-record retention. Distinguish the 180-day browser consent choice from GA4, cookie and provider-log retention. |
| Providers/transfers | Verify actual Firebase database location, GA4 settings, Vercel log retention and applicable provider contractual/transfer arrangements. Do not invent exact locations or safeguards. |
| Rights/contact | Confirm the contact responsible for requests and the applicable access/rectification/erasure/objection/portability/restriction and complaint procedures. Identify the competent authority from the real establishment, not from the language of this chat. |
| Children | Validate audience/age conditions and any required guardian process for the intended markets. |

Once these facts are available, update the displayed legal assets and their
Markdown references together, revise the relevant Terms/notice, and have the
owner validate the resulting text before closing C4.

## Access needed to finish the remaining technical checks

- Firebase: an authorized operator/ADC identity to deploy and compare the C3
  rules, check operation readiness and review any legacy public-name fallback.
  No credentials should be sent in chat. Configure access through the environment
  or perform the documented admin steps in the owner's trusted environment.
- GA4: access to the real property to confirm event receipt in DebugView/reports,
  verify retention and test-traffic exclusion, and document parameters. Request
  attempts observed in a browser are not proof of GA4 dashboard receipt.
- Native Safari: a macOS/iOS device or a real-Safari testing service. Linux WebKit
  coverage is useful evidence but does not close the native-device matrix.
- M28: initial feedback from actual users remains a product-validation step.
