# Auth: Matrix ↔ Supabase Sync

Jaeno uses Matrix as its primary auth system. Supabase is kept in sync via a custom OIDC provider backed by a Supabase Edge Function (`matrix_oidc`). The Matrix account is always the source of truth — Supabase mirrors it.

---

## Components

| File | Role |
|------|------|
| `lib/main.dart` | Initializes and wires the sync service |
| `lib/utils/matrix_supabase_auth.dart` | Core sync service (`MatrixSupabaseAuthService`) |
| `lib/pages/login/login.dart` | Triggers sync after password login |
| `lib/pages/register/register.dart` | Triggers sync after registration |
| `lib/config/routes.dart` | Holds a static ref (`AppRoutes.matrixAuth`) so pages receive the service |
| Supabase Edge Function `matrix_oidc` | Verifies Matrix token and mints OIDC id_token |

---

## Startup (`main.dart`)

```dart
final matrixAuth = MatrixSupabaseAuthService(
  matrixClients: clients,
  supabase: supabaseResult.client,
);
matrixAuth.init();
AppRoutes.matrixAuth = matrixAuth;
```

`MatrixSupabaseAuthService.init()` does two things:

1. **Session restore** — if the Matrix client already has a session (restored from device storage on cold start), calls `_loginToSupabase()` immediately. Supabase sessions are not persisted independently, so they must be re-established every time the app launches.
2. **Logout listener** — subscribes to `client.onLoginStateChanged.stream`. When Matrix fires `LoginState.loggedOut`, calls `supabase.auth.signOut()` automatically. No explicit logout call is needed in the UI.

---

## Login Flow

```
User submits username + password
  → client.login(LoginType.mLoginPassword, identifier, password)   [Matrix]
  → matrixAuth.onMatrixLogin(client)                               [Supabase sync]
  → context.go('/backup')
```

Entry point: `lib/pages/login/login.dart` → `LoginController.login()`.

---

## Registration Flow

Registration uses Matrix **UIA (User Interactive Authentication)** with email verification. It is two steps.

**Step 1 — `sendVerificationEmail()` (`register.dart:58`)**

```
client.register(username, password)
  → intentionally throws MatrixException (401) to obtain a UIA session ID
  → _uiaSession = e.session

client.requestTokenToRegisterEmail(clientSecret, email, sendAttempt)
  → Matrix homeserver sends a verification email
  → _sid = tokenResponse.sid

UI transitions to the "check your email" screen
```

**Step 2 — `completeRegistration()` (`register.dart:177`)**

```
client.register(
  username, password,
  auth: AuthenticationThreePidCreds(
    type: AuthenticationTypes.emailIdentity,
    session: _uiaSession,
    threepidCreds: ThreepidCreds(sid: _sid, clientSecret: ...),
  ),
)
  → matrixAuth.onMatrixLogin(client)   [Supabase sync]
  → context.go('/backup')
```

There is also a **no-auth fallback**: if the server accepts registration without any UIA challenge (dummy flow), `onMatrixLogin` is called immediately and the two-step flow is skipped.

---

## The Sync (`MatrixSupabaseAuthService`)

`onMatrixLogin(client)` and `init()` both funnel into `_loginToSupabase(client)`:

```
_loginToSupabase(client)
  → guard: skip if Supabase session already valid
  → matrixToken = client.accessToken
  → idToken = _exchangeMatrixToken(matrixToken)   [calls edge function]
  → supabase.auth.signInWithIdToken(
      provider: OAuthProvider('custom:matrix'),
      idToken: idToken,
    )
```

`_exchangeMatrixToken` invokes the edge function:

```dart
supabase.functions.invoke(
  'matrix_oidc/token',
  headers: {'Authorization': 'Bearer $matrixAccessToken'},
)
// returns { id_token: "<JWT>", access_token: "<JWT>", token_type: "Bearer", expires_in: 3600 }
```

Supabase creates or updates a user with `sub` equal to the Matrix user ID (e.g. `@alice:chat.jaeno.ai`).

---

## Edge Function (`matrix_oidc`)

Acts as a minimal OIDC provider. Supabase is pointed at it as a custom OIDC issuer.

### Endpoints

**`GET /.well-known/openid-configuration`**

OIDC discovery document. Supabase reads this on startup to find the JWKS URI and verify the issuer.

```json
{
  "issuer": "https://<project>.supabase.co/functions/v1/matrix_oidc",
  "jwks_uri": ".../.well-known/jwks.json",
  "id_token_signing_alg_values_supported": ["RS256"]
}
```

**`GET /.well-known/jwks.json`**

Returns the RSA public key. Supabase fetches this to verify id_token signatures.

```json
{ "keys": [{ "kty": "RSA", "use": "sig", "alg": "RS256", "kid": "matrix-oidc-1", ... }] }
```

**`POST /token`** — the endpoint the Flutter app calls

```
Request:  Authorization: Bearer <matrix_access_token>

Edge function:
  GET https://chat.jaeno.ai/_matrix/client/v3/account/whoami
    Authorization: Bearer <matrix_access_token>
  → resolves { user_id: "@alice:chat.jaeno.ai" }

  Mints JWT (RS256, signed with OIDC_PRIVATE_KEY_JWK env var):
    { sub: "@alice:chat.jaeno.ai", iss: "<edge_fn_url>", aud: "task-management agent", exp: +1h }

Response: { id_token: "<JWT>", access_token: "<JWT>", token_type: "Bearer", expires_in: 3600 }
```

### Environment variables required

| Variable | Value |
|----------|-------|
| `MATRIX_HOMESERVER` | `https://chat.jaeno.ai` |
| `OIDC_PRIVATE_KEY_JWK` | JSON string of the RSA private key in JWK format |

The corresponding public key is hardcoded in the edge function as `publicKeyJWK` and served from the JWKS endpoint.

---

## Logout

Handled automatically by the logout listener set up in `init()`:

```
Matrix fires LoginState.loggedOut
  → MatrixSupabaseAuthService listener
  → supabase.auth.signOut()
```

---

## What is NOT synced

- Registration does **not** pre-create a Supabase user. Supabase creates the user lazily on the first `signInWithIdToken` call after Matrix registration completes.
- There is no Supabase-side signup step. Matrix account creation is the only registration path.
- Supabase sessions are **not** persisted to device storage independently — they are always re-derived from the Matrix session on cold start.
