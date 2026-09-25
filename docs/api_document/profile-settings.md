# Flutter — Profile & Settings (your screens)

> Read [README.md](README.md) first. Payloads = unwrapped `data`. Owned by the doc author. User content is shown as written; theme/language drive the app shell.

## Screens → endpoints

| Screen | Endpoint(s) |
|---|---|
| Profile header | `GET /mobile/profile-summary` ([mobile-bff.md](mobile-bff.md)) |
| My / public profile | `GET /auth/me`, `GET /users/{id}/profile` |
| Edit profile | `PUT /users/me/profile` |
| Interests | `GET /interests`, `GET/PUT /users/me/interests` |
| Social links | `GET/POST/PUT/DELETE /users/me/social-links` |
| Portfolio | `GET/POST/PUT/DELETE /users/me/portfolio` |
| Settings | `GET/PUT /users/me/settings` |
| Saved | `GET /users/me/saved` |

---

## Edit profile

`PUT /users/me/profile`
```json
{ "fullName":"Sok Dara","bio":"Flutter dev","avatarUrl":"https://…","workStatus":"YOUNG_PROFESSIONAL",
  "universityName":null,"location":"Phnom Penh","dateOfBirth":"2002-05-01","gender":"MALE" }
```
Returns the updated `UserResponse` (see [auth.md](auth.md)). `workStatus` ∈ STUDENT/FRESH_GRADUATE/YOUNG_PROFESSIONAL/CREATOR/FREELANCER/ENTREPRENEUR/OTHER.

---

## Settings

`GET /users/me/settings` → `PUT` with the same shape (upsert; one row per user):
```json
{ "language":"KHMER","theme":"SYSTEM_DEFAULT","notificationEnabled":true,
  "privacyProfile":"PUBLIC","allowMessages":true,"allowFollowRequest":true,"biometricEnabled":false }
```
```dart
class UserSettings {
  final String language, theme, privacyProfile;
  final bool notificationEnabled, allowMessages, allowFollowRequest, biometricEnabled;
  UserSettings.fromJson(Map j): language=j['language'], theme=j['theme'],
    privacyProfile=j['privacyProfile'], notificationEnabled=j['notificationEnabled'],
    allowMessages=j['allowMessages'], allowFollowRequest=j['allowFollowRequest'],
    biometricEnabled=j['biometricEnabled'];
}
```
- `theme`: LIGHT / DARK / SYSTEM_DEFAULT → drive `ThemeMode`.
- `language`: KHMER / ENGLISH → set app locale **and** `Accept-Language`; keep it in sync with `user.preferredLanguage`.
- `biometricEnabled` gates the on-device biometric unlock of the stored refresh token.

---

## Interests, social links, portfolio

- **Interests:** `GET /interests` → catalog (id, name — bilingual, localized); `GET /users/me/interests` → mine; `PUT /users/me/interests` → `{ "interestIds":["…","…"] }`.
- **Social links:** CRUD `/users/me/social-links` → `{ "platform":"GITHUB","url":"https://…" }`.
- **Portfolio:** CRUD `/users/me/portfolio` → `{ "title":"…","description":"…","link":"https://…","imageUrl":"https://…" }`. Returns items with `portfolioId`, timestamps; soft-deleted on DELETE.

```dart
class PortfolioItem {
  final String portfolioId, title; final String? description, link, imageUrl;
  PortfolioItem.fromJson(Map j): portfolioId=j['portfolioId'], title=j['title'],
    description=j['description'], link=j['link'], imageUrl=j['imageUrl'];
}
```

---

## Public profile & privacy

`GET /users/{id}/profile` returns the target's public profile filtered by their `privacyProfile`. Respect `allowMessages` / `allowFollowRequest` before showing message/follow actions.

## Saved

`GET /users/me/saved` aggregates the user's saved **posts / opportunities / motivations** for the Saved screen (reuse the models from [community.md](community.md) and [lifestyle.md](lifestyle.md)).

---

## Rules
- All edits are **owner-only**; another user's id is read-only (subject to privacy).
- Changing settings language mirrors to the user profile's `preferredLanguage`.
- Bio/portfolio/social content is user content — display as written.
