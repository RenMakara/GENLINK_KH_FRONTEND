# GenLink KH — Common / Cross-Cutting Reference

> Source of truth: **GenLinkKH_Master_Data_Dictionary_v5.xlsx** (DD v5) + `docs/API_STANDARDS.md`, `docs/DB_STANDARDS.md`, `docs/LANGUAGE_SUPPORT.md`.
> This file documents conventions shared by **all** domains. Read it first; every domain doc assumes it.

**Audience key:** 🟦 Flutter · 🟩 Backend · 🟨 QA · 🟪 Designer

---

## 1. Overview

GenLink KH is a **Khmer-first Gen Z digital ecosystem** — community, productivity (lifestyle), finance, entertainment/gamification, profile, and notifications — for Cambodian students, young professionals, creators, freelancers, and entrepreneurs (university optional).

- **Tagline:** Connect. Grow. Thrive. / ភ្ជាប់ • រីកចម្រើន • រស់រវើក
- **Architecture:** Modular monolith backend, **one PostgreSQL database**. Domain ERDs are documentation only; the `users` table is shared and created once.
- **Stack:** Spring Boot 3 / Java 21 / PostgreSQL 16 / Liquibase; Flutter mobile client.
- **Home is a Super Dashboard** (command center), not a social feed. Navigation: Home, Community, Create (FAB), Finance, Profile.

---

## 2. API conventions 🟩🟦🟨

- **Base URL:** `/api/v1`
- **Success envelope:**
  ```json
  { "success": true, "message": "", "data": {}, "timestamp": "" }
  ```
- **Error envelope:**
  ```json
  { "success": false, "errorCode": "" }
  ```
- **Rules (API_STANDARDS):** REST, pagination on lists, DTO in/out (never expose entities), bean validation, Swagger/OpenAPI, always wrap in `ApiResponse<T>`.
- **Pagination wrapper** (`PageResponse<T>` inside `ApiResponse`):
  ```json
  { "content": [], "page": 0, "size": 20, "totalElements": 0, "totalPages": 0, "hasNext": false }
  ```
  Query params: `?page=`, `?size=`, `?sort=`.
- **Auth header:** `Authorization: Bearer <accessToken>` on every protected endpoint.
- **Localization header:** `Accept-Language: km | en` (falls back to the user's `preferred_language`, then default KHMER).

### Error-code contract 🟦🟨
Backend returns a **stable `errorCode`**; Flutter maps it to a Khmer/English message. Never surface raw backend strings to users. Common codes seen across domains:

| errorCode | Meaning |
|---|---|
| `VALIDATION_ERROR` | Request failed validation |
| `NOT_FOUND` / domain `*_NOT_FOUND` | Resource missing or not owned (owner-scoped reads return not-found, never forbidden) |
| `UNAUTHORIZED` / `FORBIDDEN` | Missing/invalid token, or insufficient role |
| `BUDGET_ALREADY_EXISTS`, `DEMO_WALLET_NOT_FOUND`, `DEMO_WALLET_INSUFFICIENT_BALANCE`, `GOAL_CANCELLED`, `NO_QUIZ`, `NO_QUESTIONS`, `NOT_IMPLEMENTED` | Domain-specific (see each domain doc) |

---

## 3. Data model conventions 🟩🟨

From DD v5 **Developer Notes**:

- **UUID primary keys** on every table.
- **Audit fields** on main entities: `created_at`, `updated_at`, and `deleted_at` where applicable.
- **Soft delete** via `deleted_at` for recoverable/moderated content; queries filter `deleted_at IS NULL`.
- **Cached count fields** (`like_count`, `comment_count`, `attendee_count`, etc.) must be maintained **transactionally** (atomic `SET count = count ± 1`), or computed on read — never left to drift.
- **Unique constraints** prevent duplicate likes, saves, votes, RSVPs, memberships, badges, saved motivations.
- **Owner-scoped access:** a resource that isn't the caller's reads as **not-found**, not forbidden.
- **`users` is never duplicated** — every domain references `users.user_id`.

### Shared `users` table (owned by Auth, referenced everywhere)
See [auth.md](auth.md) for the full definition. Fields most other domains touch: `user_id`, `full_name`, `username`, `avatar_url`, `total_xp`, `level`, `preferred_language`, `account_status`.

---

## 4. Gamification / XP reward pipeline 🟩

XP is granted through **one central pipeline** (`RewardService.award(user, sourceType, sourceId, xp)`) so every feature stays consistent:

1. `users.total_xp += xp`
2. `users.level = 1 + total_xp / 100` (100 XP per level — tunable)
3. Append an `xp_history` row (`source_type`, `source_id`, `xp_amount`)
4. Evaluate **badge unlocks** (milestone thresholds → `user_badges`)

XP `source_type` values in use: `EVENT_RSVP`, `QUIZ`, `FOCUS_SESSION`, `FINANCE_LESSON`, `HABIT`, `TASK`. Leaderboards and badges read `xp_history` by `source_type`. See [entertainment.md](entertainment.md).

---

## 5. Localization 🟦🟩🟪

| Layer | Approach |
|---|---|
| **UI text** | Flutter localization (`en.json` / `km.json`). Backend does **not** store common UI labels. |
| **System content** | Bilingual columns `title_en/title_km`, `content_en/content_km` (lessons, motivations, quizzes, challenges, badges, notification templates). Backend selects by `Accept-Language`/`preferred_language`; falls back EN when KM is null. |
| **User content** | Stored **as written** + a `language` enum field. Never auto-translated (posts, comments, chats, bio, event descriptions, portfolio). |
| **Backend errors** | Error code only; Flutter maps to KM/EN. |
| **Email/OTP** | Templates per user language (`otp-register-en/km`, `forgot-password-en/km`). |
| **Push** | Notification templates selected by `users.preferred_language`. |
| **Default** | **KHMER**; English allowed. |

---

## 6. Enums (DD v5 — authoritative list) 🟩🟨

| Enum | Values |
|---|---|
| `account_status` | PENDING, ACTIVE, BANNED, DELETED |
| `work_status` | STUDENT, FRESH_GRADUATE, YOUNG_PROFESSIONAL, CREATOR, FREELANCER, ENTREPRENEUR, OTHER |
| `provider` | GOOGLE, FACEBOOK, LINKEDIN |
| `otp_purpose` | REGISTER, FORGOT_PASSWORD, RESEND_VERIFICATION |
| `language` | KHMER, ENGLISH |
| `theme` | LIGHT, DARK, SYSTEM_DEFAULT |
| `post_type` | TEXT, IMAGE, POLL, ANNOUNCEMENT |
| `visibility` | PUBLIC, FRIENDS, COMMUNITY |
| `message_type` | TEXT, IMAGE, VOICE, SYSTEM |
| `chat_type` | PRIVATE, GROUP |
| `member_status` | ACTIVE, LEFT, REMOVED |
| `event_status` | DRAFT, PUBLISHED, CANCELLED, COMPLETED |
| `rsvp_status` | JOINED, INTERESTED, CANCELLED, ATTENDED |
| `budget_status` | SAFE, WARNING, LIMIT_REACHED |
| `saving_goal_status` | IN_PROGRESS, COMPLETED, CANCELLED |
| `transaction_type` | MOCK_KHQR_PAYMENT, EVENT_PAYMENT, DEPOSIT (+ `REWARD` added for literacy learning-budget credit) |
| `transaction_status` | SUCCESS, FAILED, PENDING |
| `quiz_difficulty` | EASY, MEDIUM, HARD |
| `challenge_type` | HABIT, TASK, FINANCE, QUIZ, EVENT, COMMUNITY, FOCUS |
| `challenge_status` | NOT_STARTED, IN_PROGRESS, COMPLETED, CLAIMED |
| `leaderboard_category` | PRODUCTIVITY, COMMUNITY_ENGAGEMENT, FINANCIAL_LEARNING, QUIZ_PERFORMANCE, OVERALL_XP |
| `leaderboard_period` | WEEKLY, MONTHLY, FRIENDS (+ `ALL_TIME` added in implementation) |

---

## 7. Permissions 🟩🟨

- All feature endpoints require a valid JWT (except auth entry points: register, login, verify-otp, forgot/reset password, refresh).
- **Token revocation:** JWT carries a `tv` (token-version) claim; incrementing `users.token_version` invalidates old access tokens. Banned/disabled users (`account_status != ACTIVE`) are rejected by the JWT filter.
- **Role:** `ADMIN` (via `@PreAuthorize("hasRole('ADMIN')")`) for moderation/admin-only endpoints; returns **403**, not 500.
- **Ownership:** users may only mutate their own resources; another user's id reads as not-found.

## 8. Security (JWT secret) 🟩
The JWT signing secret comes from `app.jwt.secret` (env var / secrets manager — never committed). If unset: under a **dev/local/test** profile an ephemeral key is auto-generated (with a WARN, tokens don't survive restart); in any other profile startup **fails fast**. HS256 requires ≥ 32 chars. See [auth.md](auth.md).

---

## 9. For Designers 🟪

- **Theme:** LIGHT / DARK / SYSTEM_DEFAULT (`user_settings.theme`). See `docs/DESIGN_SYSTEM.md` / `instruction/Design-Theme-System.txt`.
- **Khmer-first:** design for Khmer text length and font; English is secondary.
- **Dashboard-first, social-second** — Home surfaces cards from every domain (see [mobile-bff.md](mobile-bff.md)).
- Empty states matter: most list/dashboard endpoints degrade to nulls/empties for new users.

---

## 10. Future scope (cross-cutting)

- Real payment/banking + real KHQR transfer (currently **simulation only**).
- Translation tables / AI translation for languages beyond KM/EN.
- Push delivery infrastructure + device-token registration (see [notifications.md](notifications.md)).
- WebSocket real-time layer (chat, multiplayer quiz) — deferred.
