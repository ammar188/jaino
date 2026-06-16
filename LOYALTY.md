# Loyalty System

Jaeno has a points-based loyalty system that rewards users for signing up and for referring friends. This document covers the database schema, the Flutter service, and every place in the app where loyalty logic runs.

---

## Points summary

| Event | Reason token | Points awarded |
|---|---|---|
| New user signs up | `signup_bonus` | +50 to the new user |
| Referral redeemed — referrer side | `referral_given` | +100 to the person who shared the code |
| Referral redeemed — new user side | `referral_received` | +100 to the new user |

---

## Database

### Migrations

| File | Purpose |
|---|---|
| `supabase/migrations/20240101000000_loyalty_system.sql` | Core tables, RLS, original points function |
| `supabase/migrations/20240102000000_loyalty_transactions.sql` | Transaction history table and updated function |

### Tables

**`user_points`**
Tracks each user's running point balance. One row per user.

```
user_id   UUID  PK → auth.users
points    INT   current balance (never goes negative via app logic)
```

**`referral_codes`**
Maps each user to their unique, shareable code. Created lazily on first access.

```
user_id   UUID  PK → auth.users
code      TEXT  UNIQUE  8-character uppercase alphanumeric (e.g. "ABC12345")
```

**`referral_uses`**
Records who referred whom. `referred_id` is the primary key, so each new user can only be referred once.

```
referred_id   UUID  PK → auth.users
referrer_id   UUID  → auth.users
```

**`loyalty_transactions`**
Append-only ledger of every point award. Used to power the in-app history screen.

```
id          UUID         PK  default gen_random_uuid()
user_id     UUID         → auth.users
amount      INT          points awarded in this event
reason      TEXT         one of: signup_bonus | referral_given | referral_received
created_at  TIMESTAMPTZ  default now()
```

A partial unique index (`WHERE reason = 'signup_bonus'`) on `(user_id)` ensures the signup bonus can only be logged once per user, making the award idempotent on retry.

### Row-Level Security

| Table | Policy | Rule |
|---|---|---|
| `user_points` | read | own row only (`auth.uid() = user_id`) |
| `user_points` | insert | own row only |
| `referral_codes` | read | any authenticated user (needed to validate a code during signup) |
| `referral_codes` | insert | own row only |
| `referral_uses` | read | rows where you are referrer or referred |
| `referral_uses` | insert | `referred_id` must be `auth.uid()` (new user records their own referral) |
| `loyalty_transactions` | read | own rows only |
| `loyalty_transactions` | insert | none — all writes go through the SECURITY DEFINER function |

### SQL function

`award_loyalty_points(p_user_id UUID, p_amount INTEGER, p_reason TEXT)` — `SECURITY DEFINER` function that atomically upserts the running balance **and** appends a history row in one call. `ON CONFLICT DO NOTHING` on the insert lets the partial unique index silently skip a duplicate signup bonus.

```sql
INSERT INTO user_points (user_id, points) VALUES (p_user_id, p_amount)
ON CONFLICT (user_id) DO UPDATE SET points = user_points.points + EXCLUDED.points;

INSERT INTO loyalty_transactions (user_id, amount, reason) VALUES (p_user_id, p_amount, p_reason)
ON CONFLICT DO NOTHING;
```

This replaces the original `add_loyalty_points(UUID, INTEGER)` function, which is dropped in the second migration.

---

## Flutter service

`lib/utils/loyalty_service.dart` — `LoyaltyService`

Constructed with a `SupabaseClient`. Initialized once in `main()` and stored at `AppRoutes.loyalty` for access across the app.

### Models

```dart
class LoyaltyTransaction {
  final String id;
  final int amount;
  final String reason;   // 'signup_bonus' | 'referral_given' | 'referral_received'
  final DateTime createdAt;
}
```

### Public API

```dart
// Call once after a new user's Supabase session is established.
Future<void> onNewUserRegistered(String userId, {String? referralCode})

// Read the user's current point balance (returns 0 on error).
Future<int> getPoints(String userId)

// Return the user's referral code, creating one if it doesn't exist yet.
Future<String?> getReferralCode(String userId)

// Return the user's transaction history, newest first (returns [] on error).
Future<List<LoyaltyTransaction>> getTransactions(String userId)
```

### `onNewUserRegistered` internals

1. Call `_awardPoints(userId, 50, 'signup_bonus')` → RPC `award_loyalty_points`. The partial unique index makes this safe to call twice.
2. Create a referral code for the new user if one doesn't exist (`_ensureReferralCode`).
3. If a `referralCode` was provided, call `_applyReferralCode`:
   - Look up the referrer by code.
   - Guard: reject self-referral.
   - Insert into `referral_uses` (unique constraint on `referred_id` prevents duplicates — catches the `23505` error and exits cleanly).
   - Call `_awardPoints` for both referrer (`referral_given`) and new user (`referral_received`) in parallel.

All point awards go through `_awardPoints`, which calls the `award_loyalty_points` RPC and logs at `[Loyalty]` level.

---

## Initialization

`lib/main.dart`

```dart
final loyalty = LoyaltyService(supabase: supabaseResult.client);
AppRoutes.loyalty = loyalty;
```

`LoyaltyService` is created immediately after Supabase initializes, before the UI starts. It is stored as a static field on `AppRoutes` so any part of the app can reach it without threading it through the widget tree.

---

## Registration flow

`lib/pages/register/register.dart` — `RegisterController`

The register screen has a two-step flow:

1. **Form step** — user fills in email, username, password, and an optional referral code field (`referralCodeController`).
2. **Verify email step** — Matrix UIA sends a verification email; user clicks the link then taps "I have clicked the link".

Loyalty is triggered in two places, covering both code paths:

**Normal path (UIA email verification):**
```dart
// completeRegistration()
await widget.matrixAuth.onMatrixLogin(client);
final supabaseUserId = widget.matrixAuth.currentUser?.id;
if (supabaseUserId != null) {
  await widget.loyalty.onNewUserRegistered(
    supabaseUserId,
    referralCode: referralCodeController.text,
  );
}
```

**Rare path (server accepts registration without auth):**
Same call inside `sendVerificationEmail()`, guarded by the same null check.

The referral code field accepts any input; `LoyaltyService` trims and uppercases it before lookup, and silently no-ops if the code is unknown.

---

## Invite & referral UI

### Invite contact screen

`lib/pages/invitation_selection/`

Reachable from:
- Chat Details → "Invite" list item (`/rooms/:roomid/invite`)
- Chat Members → invite button
- Space View → invite button
- Automatically after creating a new group

At the top of this screen, if the user has a referral code, a `_ReferralBanner` card is shown with:
- The code displayed in a styled pill
- A **copy** button (copies to clipboard)
- A **share** button (opens the system share sheet via `share_plus` with the text: `"Join me on Jaeno! Use my referral code XXXXXXXX when signing up and we both get 100 bonus points."`)

The code is loaded in `initState` via:
```dart
final code = await AppRoutes.loyalty.getReferralCode(userId);
```

### Share invite link

`lib/utils/fluffy_share.dart` — `FluffyShare.shareInviteLink`

Used by the **"Share invite link"** button in the New Private Chat screen and the account menu. This function:

1. Fetches the user's own Matrix profile.
2. Fetches their referral code from `AppRoutes.loyalty`.
3. Builds the standard invite message, then appends the referral code if one is available:

```
[Name] invited you to Jaeno.
1. Download Jaeno app
2. Sign up or sign in
3. Open the invite link: https://matrix.to/#/...

Use referral code XXXXXXXX when signing up and we both get 100 bonus points!
```

If the code fetch fails (network error, not logged into Supabase), the message falls back to the standard text without the referral line.

---

## Loyalty points page

`lib/pages/loyalty/` — route `/rooms/settings/loyalty`

Reachable from **Settings → Loyalty Points**.

The page makes two parallel calls on load (`getPoints` + `getTransactions`) and renders:

- **Points card** — large balance display with a star icon, styled with the primary container colour.
- **Transaction list** — each row shows an icon, a human-readable label, the date, and the amount in green. Pull-to-refresh reloads both.

| Reason token | Icon | Label |
|---|---|---|
| `signup_bonus` | celebration | Welcome bonus |
| `referral_given` | person_add | Referral reward — you invited someone |
| `referral_received` | card_giftcard | Referral reward — you were invited |

An empty state is shown when no transactions exist yet. Errors surface a retry button.

---

## File index

| File | Role |
|---|---|
| `supabase/migrations/20240101000000_loyalty_system.sql` | Core tables (`user_points`, `referral_codes`, `referral_uses`), RLS |
| `supabase/migrations/20240102000000_loyalty_transactions.sql` | `loyalty_transactions` table, `award_loyalty_points` function |
| `lib/utils/loyalty_service.dart` | All loyalty business logic + `LoyaltyTransaction` model |
| `lib/main.dart` | Initializes `LoyaltyService`, stores it at `AppRoutes.loyalty` |
| `lib/pages/register/register.dart` | Calls `onNewUserRegistered` after signup |
| `lib/pages/register/register_view.dart` | Referral code input field on the form |
| `lib/pages/invitation_selection/invitation_selection.dart` | Loads referral code for the banner |
| `lib/pages/invitation_selection/invitation_selection_view.dart` | `_ReferralBanner` widget with copy/share |
| `lib/utils/fluffy_share.dart` | Appends referral code to the standard invite message |
| `lib/pages/loyalty/loyalty_page.dart` | Controller — loads points + transaction history |
| `lib/pages/loyalty/loyalty_page_view.dart` | Points card + transaction list UI |
| `lib/config/routes.dart` | Holds `AppRoutes.loyalty`; registers `/rooms/settings/loyalty` route |
| `lib/pages/settings/settings_view.dart` | "Loyalty Points" entry in the settings list |
