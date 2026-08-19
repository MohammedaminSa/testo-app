# Testo Privacy Policy

_Last updated: August 19, 2026_

This policy explains what Testo ("the App") collects, why it collects it, and
how you can control it. It applies to the mobile app published under the name
**Testo**.

## 1. What we collect

**Account information**

- Email address and display name (required to sign in).
- Optional avatar (if you set one).
- Your sign-in provider (email/password, Google, or Apple).

**Quiz activity**

- Quizzes you start and complete, including your answers and scores.
- Per-question topics you got wrong (used to show "Topics to review").
- Unfinished quizzes stored on your device so you can resume them.

**Device & analytics information** (only if analytics are enabled by the operator)

- Anonymous analytics events (sign-in, quiz started, quiz completed) via
  PostHog.
- Crash reports via Sentry to help us fix bugs.

## 2. Why we process it

- **To run the service**: sign you in, save your profile, and show your quiz
  history and progress.
- **To personalize content**: show quizzes, difficulty, and weak-area summaries.
- **To improve the product**: anonymized analytics and crash reporting.
- **To keep you secure**: email verification and account recovery.

## 3. Where data lives

Your data is stored in a Supabase-hosted PostgreSQL database. Attempts are
protected with row-level security so only you can read your own results.

Quiz content is served from the same database. When the app is not connected
to a backend (for example, running with no configuration), it uses bundled
demo quizzes that never leave your device.

## 4. Sharing

We do not sell your data. We share it only:

- with our hosting providers (Supabase, and analytics/crash providers when
  enabled) who process it on our behalf;
- where required by law.

## 5. Your rights

Depending on where you live (e.g. GDPR, CCPA), you can:

- access or export your data;
- correct or delete your account and data;
- withdraw consent to analytics at any time;
- object to or restrict processing.

To exercise any of these rights, contact us at the email below.

## 6. Data retention

Account data is kept while your account is active. Attempt and profile data
are deleted when you delete your account. Analytics events are retained only
as long as the analytics provider's retention policy allows.

## 7. Children

The App is not directed at children under 13 and we do not knowingly collect
their data.

## 8. Changes

We may update this policy. Material changes will be announced in the App or by
email before they take effect.

## 9. Contact

Questions or requests: **support@testo.app** (replace with the real address
before publishing).

---

_This is a template. Review it with your legal counsel before publishing and
replace all placeholders (`support@testo.app`) with your real details._