# Mobile BFF-lite

> Source of truth: DD v5 sheets **BFF-lite Endpoints**, **Finance Scope** + `docs/BFF_LITE.md`, `instruction/The-feature-should-be-apply-bff-lite.txt`. Read [common.md](common.md) first.
> **Audience:** 🟦 Flutter · 🟩 Backend · 🟨 QA · 🟪 Designer

---

## 1. Overview

BFF-lite (Backend-for-Frontend) provides **aggregation endpoints** for dashboard-heavy mobile screens, so Flutter makes **one call** instead of many. It is deliberately capped at **5–6 endpoints**; normal CRUD stays in the domain APIs. Cross-domain coupling lives **only** here (the `bff`/`mobile` modules), keeping domain services clean. Users are resolved by email (from the JWT); every section **degrades independently** (nulls/empties for new users).

**Status:** ✅ `/mobile/home`, `/mobile/profile-summary`, `/mobile/finance-dashboard`, `/mobile/productivity-dashboard`. ⬜ `/mobile/events/{id}`, `/mobile/notifications` (stubs).

---

## 2. Endpoints (DD v5 — exactly 6, cap 5–6)

| Method | Endpoint | Purpose | Status |
|---|---|---|---|
| GET | `/mobile/home` | Home Super Dashboard aggregation | ✅ |
| GET | `/mobile/profile-summary` | Profile summary aggregation | ✅ |
| GET | `/mobile/finance-dashboard` | Finance dashboard aggregation | ✅ |
| GET | `/mobile/productivity-dashboard` | Productivity dashboard aggregation | ✅ |
| GET | `/mobile/events/{id}` | Event detail optimized for mobile | ⬜ stub |
| GET | `/mobile/notifications` | Notification center aggregation | ⬜ stub |

All require `Authorization: Bearer` and honour `Accept-Language`.

---

## 3. Payloads (implemented) 🟦🟩

### `GET /mobile/home` — Super Dashboard
Cards (each nullable/empty-degradable):
- **HomeUser** — userId, fullName, avatarUrl, level, totalXp.
- **TodayProgress** — habits checked-in / total, tasks completed / total.
- **ChallengePreview** — next open daily challenge (id, title, description, xpReward, deadline) or null.
- **FinanceSnapshot** — budget total/spent/remaining/status + aggregate saving target/current. *(Known follow-up: spend reads the stored budget counter; should use live spend.)*
- **UpcomingEvent** — next RSVP'd event (id, title, dateTime, location, cover) or null.
- **RecommendedCommunities** — up to 5 public communities the user hasn't joined.
- **MotivationCard** — rotating bilingual motivation (by day-of-year) or null.
- **FeedPreview** — 3 recent public posts (author, text, image, likes, createdAt).

### `GET /mobile/finance-dashboard`
- **MonthOverview** — month/year, spent (live from expenses), budget total/remaining/status (nullable).
- **topCategories** — biggest spend categories this month (≤5).
- **SavingProgress** — total target/saved, progress %, active goals.
- **recentExpenses** — latest 5.
- **WalletSummary** — balance + currency, or null.
- **financialTip** — rotating tip (English-only for now).
- **quickActions** — action keys (ADD_EXPENSE, SET_BUDGET, NEW_SAVING_GOAL, TOP_UP_WALLET).

### `GET /mobile/productivity-dashboard`
- **HabitsToday** — total, checked-in count, per-habit list with `checkedInToday`.
- **TasksSummary** — total / completed / dueToday / overdue.
- **goals** — top 5 with progress + status (read from synced goal columns).
- **FocusSummary** — today sessions/minutes + all-time XP.
- **MotivationCard** — a rotating motivation, or null.

### `GET /mobile/profile-summary`
Aggregated identity + counts (profile, XP/level, saved counts, portfolio count).

---

## 4. Screen mapping 🟦🟪

| Screen | BFF endpoint |
|---|---|
| Home | `/mobile/home` |
| Finance tab landing | `/mobile/finance-dashboard` |
| Productivity/Lifestyle landing | `/mobile/productivity-dashboard` |
| Profile header | `/mobile/profile-summary` |
| Event detail (mobile) | `/mobile/events/{id}` ⬜ |
| Notification center | `/mobile/notifications` ⬜ |

---

## 5. Functional requirements 🟩

1. Resolve the current user by email from the JWT; **404** (`User not found`) if unknown.
2. Read across domain repositories **directly** in the BFF module (not by calling domain services), because domain services are current-user scoped and BFF is by-email.
3. **Degrade independently** — a missing budget/wallet/goal/challenge yields a null card, never an error; new users get a well-formed empty body.
4. Read-only aggregation (no writes). Keep to ≤ 6 endpoints (product rule).
5. Bilingual content (motivation, tips) selected by `Accept-Language`/`preferred_language`.

---

## 6. Database references 🟩

BFF reads (no tables of its own) across: `users`, `habits`/`habit_check_ins`, `tasks`, `goals`, `focus_sessions`, `motivation_contents`, `budgets`, `expenses`, `saving_goals`, `demo_wallets`, `communities`, `posts`, `events`/`event_rsvps`, `daily_challenges`, `notifications`. See each domain doc for exact schemas.

---

## 7. Business rules 🟩🟨

- **≤ 6 BFF endpoints** — no new ones without cutting an old one.
- No business writes in BFF; it composes existing read models.
- Every card degrades to null/empty; the response shape is stable regardless of data.
- Goal progress read from the **synced** goal columns to avoid per-goal N+1.

---

## 8. Localization 🟦🟩

- Bilingual cards (motivation, tips) localized server-side; user content passed through as written.

## 9. Permissions 🟩

- Bearer required. Returns only the caller's aggregated data.

## 10. Future scope

- Implement `/mobile/events/{id}` and `/mobile/notifications`.
- Fix the Home FinanceSnapshot to use live spend (matches finance-dashboard).
- Optional caching/ETag for dashboard payloads.
