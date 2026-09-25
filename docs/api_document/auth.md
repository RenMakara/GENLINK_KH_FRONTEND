# Flutter — Auth (your screens)

> Read [README.md](README.md) first. Payloads = unwrapped `data`. Base: `/api/v1/auth`. Public unless noted. Owned by the doc author.

## Screens → endpoints

| Screen | Endpoint |
|---|---|
| Register | `POST /auth/register` |
| OTP verify | `POST /auth/verify-otp` (alias `/verify-email`), `POST /auth/resend-otp` |
| Login | `POST /auth/login`, `POST /auth/google` |
| Forgot / reset | `POST /auth/forgot-password`, `POST /auth/reset-password` |
| (silent) token refresh | `POST /auth/refresh-token` (alias `/refresh`) |
| Change password | `POST /auth/change-password` (Bearer) |
| Logout | `POST /auth/logout` (Bearer) |
| Bootstrap / me | `GET /auth/me` (Bearer) |

---

## Requests

```jsonc
// POST /auth/register
{ "fullName":"Sok Dara","username":"sokdara","email":"sok@example.com","password":"P@ssw0rd123" }
// POST /auth/verify-otp
{ "email":"sok@example.com","otp":"123456" }
// POST /auth/login
{ "email":"sok@example.com","password":"P@ssw0rd123" }
// POST /auth/google
{ "idToken":"<google id token>" }
// POST /auth/refresh-token
{ "refreshToken":"<stored refresh token>" }
// POST /auth/forgot-password
{ "email":"sok@example.com" }
// POST /auth/reset-password
{ "email":"sok@example.com","otp":"123456","newPassword":"N3wP@ss123" }
// POST /auth/change-password  (Bearer)
{ "currentPassword":"…","newPassword":"…" }
```

## Auth response (`login`, `google`, `refresh-token`)

```json
{ "accessToken":"eyJ…","refreshToken":"…","tokenType":"Bearer",
  "user": { "userId":"…","fullName":"Sok Dara","username":"sokdara","email":"…","phoneNumber":null,
    "avatarUrl":null,"bio":null,"universityName":null,"workStatus":"STUDENT","location":null,
    "emailVerified":true,"accountStatus":"ACTIVE","totalXp":0,"level":1,"preferredLanguage":"KHMER",
    "role":"USER","active":true } }
```
`register`/`verify-otp`/`forgot`/`reset` return a message/status (no tokens). `GET /auth/me` returns the `user` object above.

```dart
class UserResponse {
  final String userId, fullName, username, email, workStatus, accountStatus, preferredLanguage, role;
  final String? phoneNumber, avatarUrl, bio, universityName, location;
  final bool emailVerified, active; final int totalXp, level;
  UserResponse.fromJson(Map j): userId=j['userId'], fullName=j['fullName'], username=j['username'],
    email=j['email'], workStatus=j['workStatus'], accountStatus=j['accountStatus'],
    preferredLanguage=j['preferredLanguage'], role=j['role'], phoneNumber=j['phoneNumber'],
    avatarUrl=j['avatarUrl'], bio=j['bio'], universityName=j['universityName'], location=j['location'],
    emailVerified=j['emailVerified'], active=j['active'], totalXp=j['totalXp'], level=j['level'];
}
class AuthResponse {
  final String accessToken, refreshToken, tokenType; final UserResponse user;
  AuthResponse.fromJson(Map j): accessToken=j['accessToken'], refreshToken=j['refreshToken'],
    tokenType=j['tokenType'], user=UserResponse.fromJson(j['user']);
}
```

---

## Flow & rules 🟦

1. **Register → OTP → login.** After register, route to OTP; on `verify-otp` success the account becomes `ACTIVE`; then login.
2. Store `accessToken` + `refreshToken` in `flutter_secure_storage`. Attach `Bearer accessToken` everywhere (README §3).
3. On `401`, call `/auth/refresh-token` once, retry; on failure, clear tokens → login.
4. **Account status:** only `accountStatus == ACTIVE` (and `active == true`) can use the app; BANNED/DELETED/PENDING are rejected — route accordingly.
5. Login/forgot are **anti-enumeration** — show a generic "check your email / invalid credentials" message; don't infer whether the email exists.
6. Google login: obtain the Google `idToken` on device, POST it; same `AuthResponse`.

**Enums:** `workStatus` (STUDENT/…/OTHER), `accountStatus` (PENDING/ACTIVE/BANNED/DELETED), `preferredLanguage` (KHMER/ENGLISH), `role` (USER/ADMIN).
**errorCodes:** `VALIDATION_ERROR`, `UNAUTHORIZED`, invalid/expired OTP, rate-limit on OTP/change-password.

---

## Localization
Set `Accept-Language` from `user.preferredLanguage`. OTP/reset emails are sent in the user's language by the backend.
