# Auth & System Domain (System/Auth)

> Source of truth: DD v5 sheet **System & Auth** + `docs/AUTH_FLOW.md`. Read [common.md](common.md) first.
> **Audience:** 🟦 Flutter · 🟩 Backend · 🟨 QA · 🟪 Designer

---

## 1. Overview

Auth owns identity, credentials, sessions, and the shared **`users`** table that every other domain references. It covers account lifecycle (register → OTP → active → login), JWT access/refresh tokens, social login, OTP flows, and profile/interest setup. Security is owned by the Backend & Security Lead.

**Status:** ✅ Implemented (register, OTP, login, refresh, forgot/reset, Google login, token versioning/revocation, account-status enforcement). Biometric login is a **client-side** concern.

---

## 2. Features (DD v5 Final Feature Scope)

Splash · Onboarding · Register · Login · OTP Verification · Forgot Password · Google Login · Biometric Login · Refresh Token · Profile Setup · Interest Selection.

---

## 3. User stories

- As a new user, I can **register** with full name, username, email, password and receive an **OTP** to verify my email.
- As a user, I can **log in** with email + password and receive an access token + refresh token.
- As a user, I can **sign in with Google** without a password.
- As a user who forgot my password, I can request a reset OTP and set a new password.
- As a user, my session **auto-refreshes** so I stay logged in without re-entering credentials.
- As a user, I can **log out** (revoke tokens) and be logged out on all devices if my account is compromised.
- As a new user, I complete **profile setup** and **interest selection** before landing on Home.
- As an admin, banned/deleted accounts cannot authenticate.

---

## 4. Functional requirements 🟩

1. **Register** creates a `users` row with `account_status = PENDING`, `email_verified = false`, BCrypt `password_hash`. Sends a `REGISTER` OTP (hashed).
2. **Verify OTP** validates the hash + expiry + `attempt_count` (rate-limited); on success sets `email_verified = true`, `account_status = ACTIVE`.
3. **Login** requires `account_status = ACTIVE`; returns access + refresh tokens. Wrong-credential responses must not reveal whether the email exists (**no email enumeration**).
4. **Refresh** validates the hashed refresh token (not expired/revoked) → new access token.
5. **Forgot/Reset password** uses a `FORGOT_PASSWORD` OTP; reset re-hashes the password and revokes existing sessions.
6. **Change password** (authenticated) is rate-limited.
7. **Google login** upserts a `social_accounts` row (`provider = GOOGLE`) and links/creates the user.
8. **Token revocation** via `users.token_version` (`tv` JWT claim). Incrementing it invalidates all outstanding access tokens.
9. OTP raw values and refresh raw tokens are **never stored** — only hashes.

---

## 5. Screen requirements 🟦🟪

| Screen | Contents / notes |
|---|---|
| Splash | Branding; routes to Onboarding or Home based on session |
| Onboarding | Value props; Khmer-first; entry to Register/Login |
| Register | full_name, username, email, password; validation inline |
| OTP Verification | 6-digit input, resend timer, `attempt_count` feedback |
| Login | email + password; Google button; "Forgot password" |
| Forgot / Reset Password | email → OTP → new password |
| Profile Setup | avatar, bio, work_status, university (optional), location, preferred_language |
| Interest Selection | multi-select from seeded interests (see [profile-settings.md](profile-settings.md)) |

Biometric login (🟦 client-only): unlock stored refresh token via device biometrics.

---

## 6. API requirements 🟩🟦

Base: `/api/v1/auth` (public unless noted). Envelope per [common.md](common.md).

| Method | Endpoint | Purpose | Auth |
|---|---|---|---|
| POST | `/auth/register` | Create pending account, send REGISTER OTP | public |
| POST | `/auth/verify-otp` | Verify email OTP → ACTIVE | public |
| POST | `/auth/resend-otp` | Resend verification OTP (RESEND_VERIFICATION) | public |
| POST | `/auth/login` | Email+password → access + refresh | public |
| POST | `/auth/google` | Google ID-token login | public |
| POST | `/auth/refresh-token` | Rotate access token | public (refresh token) |
| POST | `/auth/forgot-password` | Send FORGOT_PASSWORD OTP | public |
| POST | `/auth/reset-password` | OTP + new password | public |
| POST | `/auth/change-password` | Change while logged in (rate-limited) | Bearer |
| POST | `/auth/logout` | Revoke refresh token / bump token_version | Bearer |
| GET | `/auth/me` | Current user profile | Bearer |

**Notes:** login/refresh return `{ accessToken, refreshToken, expiresIn, user }`. Access tokens carry `sub` (email), `tv` (token version), issuer, expiry.

---

## 7. Database references (DD v5 — exact) 🟩🟨

### `users` (shared; created once)
| Field | Type | Req | Key | Default | Enum | Notes |
|---|---|---|---|---|---|---|
| user_id | uuid | Yes | PK | generated | | |
| full_name | varchar(120) | Yes | | | | |
| username | varchar(60) | Yes | | | | **UNIQUE** |
| email | varchar(180) | Yes | | | | **UNIQUE** |
| phone_number | varchar(30) | No | | | | **UNIQUE** |
| password_hash | text | No | | | | BCrypt; nullable for social-only |
| avatar_url | text | No | | | | |
| bio | text | No | | | | user content, as written |
| date_of_birth | date | No | | | | |
| gender | varchar(30) | No | | | | |
| university_name | varchar(180) | No | | | | optional |
| work_status | work_status | Yes | | STUDENT | STUDENT,FRESH_GRADUATE,YOUNG_PROFESSIONAL,CREATOR,FREELANCER,ENTREPRENEUR,OTHER | |
| location | varchar(120) | No | | | | |
| preferred_language | language | Yes | | KHMER | KHMER,ENGLISH | |
| email_verified | boolean | Yes | | false | | |
| account_status | account_status | Yes | | PENDING | PENDING,ACTIVE,BANNED,DELETED | |
| total_xp | integer | Yes | | 0 | | |
| level | integer | Yes | | 1 | | |
| created_at / updated_at / deleted_at | timestamp | | | now() | | audit + soft delete |

> Implementation adds `token_version` (integer) for JWT revocation.

### `refresh_tokens`
`refresh_token_id` (PK), `user_id` (FK users), `token_hash` (text, **INDEX**, hash only), `expires_at`, `revoked_at`, `device_info`, `ip_address`, `created_at`, `updated_at`.

### `social_accounts`
`social_account_id` (PK), `user_id` (FK users), `provider` (GOOGLE,FACEBOOK,LINKEDIN), `provider_user_id` (**UNIQUE(provider, provider_user_id)**), `provider_email`, `created_at`, `updated_at`.

### `otp_verifications`
`otp_id` (PK), `user_id` (FK users, nullable), `email` (**INDEX**), `otp_hash` (hash only), `purpose` (REGISTER,FORGOT_PASSWORD,RESEND_VERIFICATION), `expires_at`, `verified_at`, `attempt_count` (default 0), `created_at`, `updated_at`.

**Constraints:** `users.username/email/phone_number` UNIQUE; `refresh_tokens.token_hash` INDEX; `social_accounts` UNIQUE(provider, provider_user_id); `otp_verifications.email` INDEX.

---

## 8. Business rules 🟩🟨

- Account lifecycle: **PENDING → ACTIVE** (via OTP) → optionally BANNED/DELETED. Only ACTIVE can log in.
- OTP: store hash only; enforce expiry; increment `attempt_count`; rate-limit; single-use (`verified_at`).
- Refresh token: store hash only; support expiry + revoke; rotate on refresh.
- Password: BCrypt; min-strength validation; reset revokes existing sessions.
- **No email enumeration** on login/forgot-password (uniform responses).
- JWT filter rejects tokens whose `tv` ≠ current `users.token_version`, and any non-ACTIVE account.
- Passwords/OTPs/tokens never logged.

---

## 9. Notifications 🟨

- **Security Alert** (login from new device, password changed) → category `SECURITY` (see [notifications.md](notifications.md)).
- Email: OTP + password-reset emails, localized template by `preferred_language`.

---

## 10. Localization 🟦🟩

- OTP/reset emails: `otp-register-en/km`, `forgot-password-en/km` chosen by user language.
- Validation/auth failures return stable `errorCode`; Flutter maps to KM/EN.
- `preferred_language` captured at profile setup, default KHMER.

---

## 11. Permissions 🟩

- Public: register, verify-otp, resend-otp, login, google, refresh, forgot/reset password.
- Bearer: change-password, logout, me, and everything in other domains.
- BANNED/DELETED/PENDING accounts cannot obtain or use access tokens.

---

## 12. Future scope

- Facebook / LinkedIn providers (`provider` enum already reserves them).
- Biometric-bound refresh tokens; device/session management UI (uses `refresh_tokens.device_info`).
- MFA beyond email OTP; phone/SMS OTP (`phone_number` exists).
