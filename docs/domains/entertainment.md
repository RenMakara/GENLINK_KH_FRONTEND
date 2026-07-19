# Entertainment / Gamification Domain

> Source of truth: DD v5 sheet **Entertainment** + `backend/docs/ENTERTAINMENT_PLAN.md`. Read [common.md](common.md) first.
> **Audience:** 🟦 Flutter · 🟩 Backend · 🟨 QA · 🟪 Designer

---

## 1. Overview

Entertainment is the gamification engine: **quiz competitions**, **daily/weekly challenges**, the **XP + level + badge reward system**, **leaderboards**, and **short (reel) content**. It ties every other domain together through the central **reward pipeline** (see [common.md](common.md) §4) — earning XP anywhere updates level and can unlock badges.

**Status legend:** ✅ implemented · ⏸ deferred.
- ✅ Quiz (single-player), Daily Challenges (join/complete/claim), Reward pipeline (XP → level → badge check), Badges (auto-unlock on milestones), Leaderboard (period × category), Short Content (feed + like/save/share + create).
- ⏸ **Multiplayer quiz** (find opponent / match — needs real-time), **Friends ranking**, **short-content media upload**.

---

## 2. Features (DD v5 Final Feature Scope)

- **Quiz Competition:** Quiz Categories, Quiz Play, Score Tracking, Quiz Result, Leaderboard. *(Multiplayer ⏸.)*
- **Daily Challenge:** Daily/Weekly Challenge, XP Reward, Claim Reward.
- **Reward System:** XP System, Badges, Achievements, User Level, XP History.
- **Leaderboard:** Weekly/Monthly/Friends Ranking ⏸(friends), Category Ranking.
- **Short Content:** Educational/Motivation/Finance/Career/Self-Growth Shorts, Like/Save/Share.

---

## 3. User stories

- I can pick a **quiz category**, **play**, **submit**, see my **score**, and **earn XP** (once per quiz, scaled by score).
- I can **join a daily/weekly challenge**, complete it, and **claim** an XP reward.
- Earning XP anywhere **levels me up** and can **unlock badges** (Quiz Champion, Productivity Hero, etc.).
- I can view **leaderboards** by category (Overall/Productivity/Community/Finance/Quiz) and period (weekly/monthly/all-time) and see **my rank**.
- I can scroll a **short-content feed**, and **like/save/share** shorts.

---

## 4. Functional requirements 🟩

1. **Quiz:** list (filter category/difficulty) with question count; detail = questions + options with the **`is_correct` flag withheld**; **submit** grades against correct options, writes `quiz_attempts` + `quiz_attempt_answers`, returns score + per-question correctness. XP = `round(xpReward × correct/total)`, awarded **once per quiz** (replays log an attempt, pay 0). History endpoint.
2. **Daily challenges:** list active (deadline in future) with the user's status; **join** (creates `user_challenges` IN_PROGRESS), **complete** (COMPLETED), **claim** (awards XP once via the pipeline, sets CLAIMED). Progress is user/client-driven (no cross-domain auto-tracking).
3. **Reward pipeline:** `award(user, source, sourceId, xp)` → `total_xp += xp`, `level = 1 + total_xp/100`, append `xp_history`, evaluate badges.
4. **Badges:** catalog with an `earned` flag + "my badges"; **auto-unlock** on milestones keyed by a badge `code`, evaluated from `xp_history` counts + total XP; idempotent (`UNIQUE(user_id,badge_id)`).
5. **Leaderboard:** computed on read. `category` ∈ {OVERALL_XP, PRODUCTIVITY, COMMUNITY_ENGAGEMENT, FINANCIAL_LEARNING, QUIZ_PERFORMANCE} (mapped to `xp_history.source_type`); `period` ∈ {WEEKLY, MONTHLY, ALL_TIME}; returns top 20 + the caller's rank/points. **FRIENDS** → `NOT_IMPLEMENTED`.
6. **Short content:** feed (paginated, `?category`) + detail with **liked/saved** flags; **create** (metadata only, no upload; creator = current user); idempotent **like/unlike, save/unsave** (per-user join tables, atomic counters); **share** increments a counter; "my saved" list.

---

## 5. Screen requirements 🟦🟪

| Screen | Contents |
|---|---|
| Quiz Home | categories (Technology, General Knowledge, Finance, Business, English, Entertainment) |
| Quiz Play | question, options, timer; submit |
| Quiz Result | score, correct/total, XP earned, review with explanations |
| Challenge Dashboard | daily & weekly challenges, status, **claim** button |
| Rewards | XP total, **level**, XP history, **badges** (earned/locked) |
| Leaderboard | ranking type (weekly/monthly/all-time) × category; **my rank** row |
| Short Content Feed | vertical reels by category; **like/save/share**, open creator |

---

## 6. API requirements 🟩🟦

Base `/api/v1/entertainment`.

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/entertainment/quizzes?category=&difficulty=` · `/{id}` · `/history` | Quiz list/detail/history |
| POST | `/entertainment/quizzes/{id}/attempts` | Submit + grade + XP |
| GET | `/entertainment/challenges?scope=daily|weekly` · `/mine` | Challenges + my status |
| POST | `/entertainment/challenges/{id}/join` · `/complete` · `/claim` | Join → complete → claim |
| GET | `/entertainment/badges` · `/mine` | Catalog (earned flag) + my badges |
| GET | `/entertainment/leaderboards?category=&period=` | Top 20 + my rank |
| POST/GET | `/entertainment/short-content` · `?category=` · `/{id}` · `/saved` | Create + feed + detail + my saved |
| POST/DELETE | `/entertainment/short-content/{id}/like` · `/save` | Toggle like / save |
| POST | `/entertainment/short-content/{id}/share` | Share counter |

**Domain errors:** `NO_QUESTIONS` (empty quiz), `NOT_IMPLEMENTED` (friends leaderboard / multiplayer).

---

## 7. Database references (DD v5 — exact) 🟩🟨

- **`quizzes`**: quiz_id PK; **title_en/km**; category; difficulty quiz_difficulty (EASY/MEDIUM/HARD); xp_reward.
- **`quiz_questions`**: question_id PK; quiz_id FK; **question_text_en/km**; **explanation_en/km**.
- **`quiz_options`**: option_id PK; question_id FK; **option_text_en/km**; is_correct.
- **`quiz_attempts`**: attempt_id PK; quiz_id FK; user_id FK; score; correct_count; total_questions; xp_earned; completed_at.
- **`quiz_attempt_answers`**: answer_id PK; attempt_id FK; question_id FK; selected_option_id FK; is_correct; answered_at.
- **`daily_challenges`**: challenge_id PK; **title_en/km, description_en/km**; challenge_type (HABIT/TASK/FINANCE/QUIZ/EVENT/COMMUNITY/FOCUS); xp_reward; deadline.
- **`user_challenges`**: user_challenge_id PK; challenge_id FK; user_id FK; status challenge_status (NOT_STARTED/IN_PROGRESS/COMPLETED/CLAIMED); progress; completed_at; **UNIQUE(user_id,challenge_id)**.
- **`xp_history`**: xp_history_id PK; user_id FK; source_type; source_id; xp_amount; created_at.
- **`badges`**: badge_id PK; **name_en/km, description_en/km**; requirement; icon_url. *(Implementation adds `code` for the unlock rule.)*
- **`user_badges`**: user_badge_id PK; user_id FK; badge_id FK; unlocked_at; **UNIQUE(user_id,badge_id)**.
- **`leaderboards`**: leaderboard_id PK; user_id FK; category leaderboard_category; period leaderboard_period; rank; points; updated_at. *(Implementation computes on read; this table is unused/for cache.)*
- **`short_contents`**: short_content_id PK; **title_en/km, description_en/km**; category; video_url; thumbnail_url; creator_id FK; like_count; save_count; share_count; created_at.

> **Implementation additions:** `short_content_likes`, `short_content_saves` (UNIQUE(user,content)); `badges.code`; `leaderboard_period` gained `ALL_TIME`; `transaction_type` gained `REWARD` (finance). Seed badges: PRODUCTIVITY_HERO, COMMUNICATION_HELPER, FINANCIAL_STARTER, CONSISTENCY_MASTER, QUIZ_CHAMPION, EVENT_EXPLORER.

---

## 8. Business rules 🟩🟨

- **Quiz XP once per quiz**, scaled by score; correct answers never sent to the client until after submit.
- **Challenge XP once**, on **claim** (COMPLETED → CLAIMED).
- **Level** = `1 + total_xp/100`; recomputed on every award.
- **Badge auto-unlock** thresholds (implementation): Financial Starter (1 lesson), Quiz Champion (3 quizzes), Event Explorer (3 RSVPs), Consistency Master (7 check-ins), Productivity Hero (10 productivity actions), Communication Helper (≥300 XP proxy). Once-only.
- **Leaderboard** computed on read; window cutoff is a comparison (all-time = epoch) to avoid the `:date IS NULL` trap.
- Short-content like/save idempotent; counters atomic; share is fire-and-forget.

---

## 9. Notifications 🟨

- **Challenge Reminder** — new daily/weekly challenge, claim available — category `CHALLENGE`.
- Badge unlocked / level up → in-app + optional push.

---

## 10. Localization 🟦🟩

- Quizzes, questions, options, explanations, challenges, badges, shorts: **bilingual** (`_en/_km`), selected by language, EN fallback. Seeded content English-only pending Khmer.
- User-created short-content titles are user content (as written).

---

## 11. Permissions 🟩

- Authenticated for all. Quizzes/challenges/badges are read-only system content; attempts/claims/badges are per-user.
- Short-content create: any authenticated user is the creator (no upload pipeline).

---

## 12. Future scope

- **Multiplayer quiz** (real-time matchmaking / WebSocket).
- **Friends ranking** (needs the Community follow graph).
- Short-content **media upload/transcode**; achievements beyond badges; daily-vs-weekly challenge auto-progress from other domains.
