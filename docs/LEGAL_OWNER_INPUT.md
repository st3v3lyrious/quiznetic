# M32 C4 — Information the owner must validate

This internal brief is not a published legal notice and does not assert legal
compliance. No placeholders below are inserted into the public policy.

## Owner facts confirmed — October 27, 2026

The owner explicitly confirmed **Steve Alomassor**, an individual resident in
France, as the project/data controller, and confirmed use of
**quizneticapp@gmail.com** for deletion requests. Quiznetic is a personal product,
not a separate legal entity. No legal name was inferred from GitHub and no postal
address or company registration was invented.

The [France review and implementation inventory](FRANCE_PRIVACY_REVIEW.md)
documents official sources, the actual data flows, proposed legal bases and the
support deletion workflow. Updated public-copy assets are prepared for review,
not published. Retention choices, children, applicable editor/hosting notices,
provider terms/transfers and actual GA4 settings remain open; C4 is not closed.

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
| Legal editor/controller | Name, individual status, France and support email confirmed above. Verify remaining applicable editor/hosting and postal/contact notices; do not invent a registration or address. |
| Markets/jurisdiction | Where the editor is established and the intended audience; applicable jurisdiction and any mandatory consumer provisions. |
| Purposes/legal bases | Validate the basis for account/gameplay operations, security/abuse controls and optional Analytics, including how rights apply in the relevant jurisdiction. |
| Retention | Define account inactivity/deletion policy, score/attempt retention and support/security-record retention. Distinguish the 180-day browser consent choice from GA4, cookie and provider-log retention. |
| Providers/transfers | Verify actual Firebase database location, GA4 settings, Vercel log retention and applicable provider contractual/transfer arrangements. Do not invent exact locations or safeguards. |
| Rights/contact | Support email confirmed; France review and proposed policy identify Steve Alomassor and CNIL, explain rights, the one-month response clock and C3 deletion limits. Owner review/publication remain pending. |
| Children | Validate audience/age conditions and any required guardian process for the intended markets. |

Once these facts are available, update the displayed legal assets and their
Markdown references together, revise the relevant Terms/notice, and have the
owner validate the resulting text before closing C4.

## Access needed to finish the remaining technical checks

- Firebase: C3 operator access, deployed-rule comparison and controlled deletion
  were validated. Reviewing legacy public-name fallback remains a separate task.
  No credentials should be sent in chat. Configure access through the environment
  or perform the documented admin steps in the owner's trusted environment.
- GA4: access to the real property to confirm event receipt in DebugView/reports,
  verify retention and test-traffic exclusion, and document parameters. Request
  attempts observed in a browser are not proof of GA4 dashboard receipt.
- Native Safari: the owner waived this as a launch gate on October 27, 2026.
  It remains untested; Linux WebKit is not recorded as a passing native test.
- M28: initial feedback from actual users remains a product-validation step.
