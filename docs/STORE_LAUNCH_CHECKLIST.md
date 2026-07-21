# Store Launch Checklist — Chores Star

The public release steps that need **you** (legal declarations, permission-gated
actions, and the final submit). Everything automatable is already done — see
"Already done" at the bottom.

> ⚠️ **This is a children's/family app.** The Data Safety, Content Rating,
> Target Audience (Play) and App Privacy / Age Rating (Apple) answers below are
> legal declarations under your name. They carry real weight (COPPA, UK-GDPR
> "age-appropriate design", Google Families policy). Answer accurately; consider
> a quick legal review before submitting.

**What the app actually collects** (use this to answer the questionnaires):
- **Name** — provided at sign-up; account functionality; linked to the user.
- **Email address** — from Google/Apple sign-in; account functionality; linked
  to the user. (Children who join by invite code have no email.)
- **Crash data** — Firebase Crashlytics; diagnostics; not linked to identity.
- **Product interaction / usage** — privacy-first analytics (`analyticsEvents`),
  pseudonymous, no PII.
- **No advertising, no third-party ad SDKs, no tracking across apps.**
- Privacy Policy: https://hoquem.github.io/hoque-family-chores/PRIVACY_POLICY.html

---

## Google Play (Play Console)

1. **Grant store-listing permission** (or do the listing manually) — Users &
   permissions → the deploy service account → add "Edit store listing". Then I
   can push the title/description/graphics via API. Otherwise do steps 2–3 by hand.
2. **Main store listing** — Grow → Store presence → Main store listing:
   - App name: **Chores Star**
   - Short + full description: from the Play description I wrote (in chat).
   - Graphics: upload `store_assets/play/play_icon_512.png`,
     `store_assets/play/feature_1024x500.jpg`, and the three
     `store_assets/play/screenshots/phone_*.png`.
3. **App content** (Policy → App content) — complete each:
   - **Privacy policy** — paste the URL above.
   - **Ads** — "No, my app does not contain ads."
   - **Data safety** — declare Name, Email (account management, linked),
     Crash + app-performance data (analytics, not linked). Data is encrypted in
     transit; users can request deletion (Profile → Delete Account).
   - **Content rating** — start the IARC questionnaire. It's a utility app with
     no objectionable content → expect "Everyone / PEGI 3".
   - **Target audience and content** — ⚠️ the important one. Choose the age
     groups you intend. Including under-13 opts you into the **Families policy**
     (extra requirements). Decide deliberately.
   - **App access** — reviewers need to sign in: either add Sign-in-with-Google
     test instructions, or note the hidden email/password login (long-press the
     "Login" title).
4. **Release to Production** — Production → Create new release → add the
   **build 44** App Store bundle (already uploaded to Internal; move/add it to
   Production) → review → roll out.

## Apple App Store (App Store Connect)

1. **Screenshots** — App Store → 1.0 → drag-drop the three
   `store_assets/appstore/screenshots_6.9/*.png` (6.9"/6.7" iPhone slot).
2. **App Privacy** (left nav → App Privacy) — declare: Email + Name (App
   Functionality, linked to identity), Crash Data (Crashlytics, not linked),
   Usage Data (analytics, not linked). No tracking.
3. **Age rating** — answer the questionnaire honestly → expect **4+**. Do **not**
   enrol in the Kids Category (unnecessary; triggers stricter review).
4. **Attach build** — select build **1.0.0+44** on version 1.0.
5. **Submit for Review** — the final step. App Store review is ~1–3 days.

---

## Already done (automated this session)
- App name unified to **Chores Star** (iOS/Android launchers, in-app, docs,
  App Store Connect listing name; Play listing title pending the permission above).
- **App Store description, keywords, promotional text** set via API (both locales).
- **Play + App Store graphics** generated (`store_assets/`): 512 icon,
  1024×500 feature graphic, phone screenshots (Play 2:1 + iOS 6.9").
- Build **1.0.0+44** live on both internal tracks + TestFlight VALID.
- Privacy Policy + Terms hosted and linked; export compliance handled.
