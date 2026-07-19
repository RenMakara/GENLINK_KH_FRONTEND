# Profile & Settings Domain

> Source of truth: DD v5 sheet **Profile & Settings** (+ profile fields on `users`). Read [common.md](common.md) first.
> **Audience:** 🟦 Flutter · 🟩 Backend · 🟨 QA · 🟪 Designer

---

## 1. Overview

Profile & Settings owns the public/professional identity (avatar, bio, interests, skills, work status, social links, **portfolio**) and per-user **settings** (language, theme, privacy, notification, biometric). Profile data lives partly on the shared `users` table (owned by Auth) and partly in profile tables.

**Status:** ✅ Implemented — interests, social links, portfolio, saved items, and settings. Public profile read + edit-own-profile.

---

## 2. Features (DD v5 Final Feature Scope)

Avatar · Bio · Interests · Skills · University (Optional) · Work Status · Social Links · Public Profile · Portfolio · Settings · Privacy · Security.

---

## 3. User stories

- I can edit my **profile** (avatar, bio, work status, university, location) and pick **interests**.
- I can add **social links** and **portfolio items** (title, description, link, image) to showcase my work.
- Others can view my **public profile** (respecting my privacy setting).
- I can change **settings**: language, theme (light/dark/system), notifications, privacy, allow-messages, allow-follow, biometric.
- I can view my **saved items** (saved posts, opportunities, motivations) in one place.

---

## 4. Functional requirements 🟩

1. **Profile read**: `GET /users/{id}/profile` returns public profile (avatar, bio, work_status, interests, skills, social links, portfolio) filtered by the owner's `privacy_profile`.
2. **Edit own profile**: `PUT /users/me/profile` updates `users` profile fields; owner-only.
3. **Interests**: select from a seeded catalog (`interests`); `user_interests` links (idempotent).
4. **Social links**: CRUD `user_social_links` (platform + url), owner-scoped.
5. **Portfolio**: CRUD `portfolio_items`, owner-scoped, soft delete.
6. **Settings**: one `user_settings` row per user (**UNIQUE(user_id)**); upsert semantics; language change also updates `users.preferred_language`.
7. **Saved screen**: aggregates saved posts / opportunities / motivations for the user.

---

## 5. Screen requirements 🟦🟪

| Screen | Contents |
|---|---|
| My Profile | avatar, name/username, bio, work status, university, location, interests, skills, social links, XP/level |
| Public Profile | same, filtered by privacy; follow/message actions |
| Edit Profile | editable profile fields + interest picker |
| Portfolio | list of portfolio items (image, title, link); add/edit/delete |
| Settings | language, **theme (light/dark/system)**, notifications, privacy, allow messages, allow follow, biometric |
| Saved | tabs for saved posts / opportunities / motivations |

---

## 6. API requirements 🟩🟦

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/users/{id}/profile` | Public profile |
| PUT | `/users/me/profile` | Edit own profile |
| GET/PUT | `/users/me/settings` | Read/update settings |
| GET | `/interests` · `/users/me/interests` | Interest catalog + mine |
| PUT | `/users/me/interests` | Set interests |
| CRUD | `/users/me/social-links` | Social links |
| CRUD | `/users/me/portfolio` | Portfolio items |
| GET | `/users/me/saved` | Saved posts/opportunities/motivations |
| GET | `/mobile/profile-summary` | Aggregated summary (BFF) |

---

## 7. Database references (DD v5 — exact) 🟩🟨

- **`portfolio_items`**: portfolio_id PK; user_id FK; title varchar(180); description; link; image_url; audit+deleted_at.
- **`user_settings`**: settings_id PK; user_id FK **UNIQUE(user_id)**; language (KHMER/ENGLISH); theme (LIGHT/DARK/SYSTEM_DEFAULT); notification_enabled; privacy_profile varchar(40); allow_messages; allow_follow_request; biometric_enabled; created_at; updated_at.
- **Profile fields on `users`** (owned by Auth, see [auth.md](auth.md)): avatar_url, bio, work_status, university_name, location, preferred_language, total_xp, level.

> **Implementation additions (ERD v5.1):** `interests`, `user_interests` (UNIQUE(user,interest)), `user_social_links`, and a saved-items model backing the Saved screen.

---

## 8. Business rules 🟩🟨

- One settings row per user; changing settings language mirrors to `users.preferred_language`.
- `privacy_profile` governs what the public profile exposes; `allow_messages` / `allow_follow_request` gate those actions.
- Portfolio and social links are owner-scoped; soft delete on portfolio.
- Interests idempotent (unique link).

---

## 9. Notifications 🟨

- Follow request (if `allow_follow_request`) → community/notification.
- Security-related settings changes (biometric, password) may raise a `SECURITY` alert.

---

## 10. Localization 🟦🟩

- Settings drive UI language (`user_settings.language` ↔ `users.preferred_language`); default KHMER.
- Bio/portfolio/social content is user content (as written).
- Theme labels & UI via Flutter localization.

---

## 11. Permissions 🟩

- Edit is owner-only. Public profile visibility is governed by `privacy_profile`.
- Viewing another profile is allowed subject to privacy; messaging/following subject to the target's settings.

---

## 12. Future scope

- Skills as a structured table (currently interests + free text); mentor flag; follower/following counts on profile; profile verification badges.
