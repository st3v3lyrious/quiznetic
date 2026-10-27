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
not published. The owner approved 24-month account inactivity, 12-month detailed
attempt history and 12-month closed-support retention, and an all-ages educational
audience. Operational rollout remains tracked below; C4 is not closed.

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
| Retention | Periods approved; [monthly Spark procedure](DATA_RETENTION.md), #173. First inventory and safe partial attempt purge still required. No player deletion authorized. |
| Providers/transfers | Verify actual Firebase database location, GA4 settings, Vercel log retention and applicable provider contractual/transfer arrangements. Do not invent exact locations or safeguards. |
| Rights/contact | Support email confirmed; France review and proposed policy identify Steve Alomassor and CNIL, explain rights, the one-month response clock and C3 deletion limits. Owner review/publication remain pending. |
| Children | All-ages audience confirmed. Web Analytics paused in #172/#171. [Minors journey proposal](MINORS_PROPOSAL.md), #174; local mode, parental verification and private profiles remain to implement. |

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

## Execution tracking

- #172 — Analytics pause, tests and deployed-build verification.
- #173 — Operational retention and safe partial purge, with no player deletions here.
- #174 — Child/parent journey and privacy by default.
- #175 — Remaining editor/hosting notices, contracts, transfers and provider retention.

The local execution environment became unavailable during implementation. Changes
are prepared through GitHub and validated by CI where available; no local/browser
pass, merge or publication is inferred from code preparation. C4 stays open.
