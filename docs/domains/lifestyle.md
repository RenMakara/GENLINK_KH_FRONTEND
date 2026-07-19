# Lifestyle / Productivity Domain

> Source of truth: DD v5 sheet **Productivity** + `backend/docs/PRODUCTIVITY_PLAN.md`. Read [common.md](common.md) first.
> **Audience:** 🟦 Flutter · 🟩 Backend · 🟨 QA · 🟪 Designer
> *"Lifestyle" is the product pillar name for the Productivity domain (habits, tasks, focus, goals, motivation).*

---

## 1. Overview

Lifestyle/Productivity helps users build discipline: **habit tracking with streaks**, a **to-do list**, a **Pomodoro/focus timer** that earns XP, **goals with milestones**, and **daily motivation** (bilingual, saveable). It powers Home's Today-Progress and Daily-Motivation cards and the Productivity dashboard BFF.

**Status:** ✅ All implemented (Habits + check-ins, Tasks, Goals + milestones, Focus sessions, Motivation save/unsave, and the `/mobile/productivity-dashboard` BFF).

---

## 2. Features (DD v5 Final Feature Scope)

- **Habit Tracker:** Create Habit, Daily Check-in, Streak, Progress Ring, Weekly Analytics, Reminder.
- **To-Do Management:** Create Task, Priority, Due Date, Complete Task, Categories, Smart Reminder.
- **Focus & Study:** Pomodoro Timer, Study Session Timer, Focus Statistics, Ambient Sound, Study Challenge.
- **Goal Management:** Personal/Career/Financial/Skill Goals, Deadline, Progress Tracking, Milestones, Goal Sharing.
- **Daily Motivation:** Daily Quote, Productivity Tip, Khmer Self-Growth Content, Save Motivation.

---

## 3. User stories

- I can create a **habit** and **check in** daily; I see my **streak** and completion rate.
- I can add **tasks** with priority, category, and due date, and mark them complete; I can filter today/overdue.
- I can run a **focus session** (Pomodoro) and earn XP based on duration.
- I can set **goals** with **milestones** and watch progress fill as I complete them.
- I can read **daily motivation** (Khmer or English) and **save** the ones I like.

---

## 4. Functional requirements 🟩

1. **Habits:** CRUD, owner-scoped, soft delete. **Check-in** is idempotent per `(habit,user,date)` (unique). **Streak** = consecutive completed days ending today (or yesterday if today isn't checked in yet); **completionRate** = completed days over the last 30 — both **computed on read** from `habit_check_ins`, never trusted from stored counters. First completion of the day awards +5 XP (`HABIT`).
2. **Tasks:** CRUD; `POST /{id}/complete?completed=` toggles; filters (category, priority, completed, scope=today/overdue/upcoming) applied in memory; `overdue` computed. First transition to completed awards +5 XP (`TASK`).
3. **Focus sessions:** start → complete (idempotent — XP paid once); XP = `min(30, minutes/5)` (`FOCUS_SESSION`); paginated history + stats (today + all-time sessions/minutes/xp).
4. **Goals & milestones:** goal CRUD; milestone add/complete/delete; `progress_percentage` and status (NOT_STARTED/IN_PROGRESS/COMPLETED) **computed from milestones** (done/total), auto-completing at 100%.
5. **Motivation:** bilingual list/detail (optional category); idempotent save/unsave with atomic `saved_count`; "my saved" list.

---

## 5. Screen requirements 🟦🟪

| Screen | Contents |
|---|---|
| Habits | list with **progress ring** + streak; daily check-in; weekly analytics |
| Habit Detail / Create | title, category, frequency, reminder_time |
| Tasks | list with priority/category, filters (today/overdue), complete checkbox |
| Focus Timer | mode (Pomodoro/Study/Deep Work), duration, **ambient sound**, start/complete; stats |
| Goals | list with progress bar; goal detail with **milestones** checklist |
| Motivation | daily quote/tip card, category browse, **save** button; My Saved |

---

## 6. API requirements 🟩🟦

Base `/api/v1/productivity`.

| Method | Endpoint | Purpose |
|---|---|---|
| GET/POST/PUT/DELETE | `/productivity/habits` (+ `/{id}`) | Habit CRUD |
| POST | `/productivity/habits/{id}/check-in` | Idempotent daily check-in (`{date?, completed?}`) |
| GET/POST/PUT/DELETE | `/productivity/tasks` (+ `/{id}`) | Task CRUD; `?category&priority&completed&scope` |
| POST | `/productivity/tasks/{id}/complete?completed=` | Complete/reopen |
| POST/GET/PUT/DELETE | `/productivity/goals` (+ `/{id}`) | Goal CRUD |
| POST | `/productivity/goals/{id}/milestones` | Add milestone |
| POST | `/productivity/goals/{id}/milestones/{mid}/complete?completed=` | Toggle milestone |
| DELETE | `/productivity/goals/{id}/milestones/{mid}` | Delete milestone |
| POST | `/productivity/focus-sessions/start` | Start session |
| POST | `/productivity/focus-sessions/{id}/complete` | Complete (awards XP once) |
| GET | `/productivity/focus-sessions` (paginated) · `/stats` | History + stats |
| GET | `/productivity/motivation?category=` · `/saved` · `/{id}` | Motivation list/detail |
| POST/DELETE | `/productivity/motivation/{id}/save` | Save / unsave |

Aggregated view: `GET /mobile/productivity-dashboard` (see [mobile-bff.md](mobile-bff.md)).

---

## 7. Database references (DD v5 — exact) 🟩🟨

- **`habits`**: habit_id PK; user_id FK; title varchar(150); category; frequency; reminder_time (time); streak_count; completion_rate decimal(5,2); audit+deleted_at.
- **`habit_check_ins`**: check_in_id PK; habit_id FK; user_id FK; check_in_date (date); completed (bool); **UNIQUE(habit_id,check_in_date)**.
- **`tasks`**: task_id PK; user_id FK; title varchar(180); description; priority varchar(20); category; due_date (timestamp); reminder_time (timestamp); completed; audit+deleted_at.
- **`focus_sessions`**: session_id PK; user_id FK; mode (Pomodoro/Study/Deep Work); duration_minutes; ambient_sound; completed; xp_earned; started_at; ended_at.
- **`goals`**: goal_id PK; user_id FK; title; description; goal_type (Personal/Career/Financial/Skill); deadline (date); progress_percentage decimal(5,2); status; audit+deleted_at.
- **`goal_milestones`**: milestone_id PK; goal_id FK; title; completed; completed_at.
- **`motivation_contents`**: motivation_id PK; **title_en/title_km/content_en/content_km** (bilingual); category; saved_count; audit+deleted_at.
- **`user_saved_motivations`**: saved_motivation_id PK; user_id FK; motivation_id FK; saved_at; **UNIQUE(user_id,motivation_id)**.

---

## 8. Business rules 🟩🟨

- Habit check-in idempotent per day; streak/rate computed on read (drift-proof).
- XP is granted through the central reward pipeline ([common.md](common.md) §4) → also updates level and checks badges.
- Focus XP capped (`min(30, minutes/5)`); a sub-5-minute session earns 0; completion is once-only.
- Task/habit XP awarded only on the transition **to** completed (no farming by toggling).
- Goal progress/status derived from milestones; stored columns kept in sync but response computes.
- Motivation `saved_count` changes only on a real save/unsave; unique prevents double-count.

---

## 9. Notifications 🟨

- **Productivity Reminder** — habit `reminder_time` / task `reminder_time` (client-scheduled or push) — category `PRODUCTIVITY`.
- **Study Challenge / streak milestones** may notify (challenge lives in [entertainment.md](entertainment.md)).

---

## 10. Localization 🟦🟩

- **Motivation content** is bilingual (`_en/_km`); selected by `Accept-Language`/`preferred_language`, EN fallback. Khmer self-growth content is a first-class requirement.
- Habit/task/goal titles are **user content** (as written).
- Seeded motivation is currently English-only pending Khmer authoring.

---

## 11. Permissions 🟩

- All owner-scoped. Motivation content is read-only for users (system-authored); saving is per-user.
- Goal Sharing (future) would expose a goal read-only to others.

---

## 12. Future scope

- Weekly analytics charts; smart reminders (server-scheduled push).
- Study challenges tied to Entertainment challenges; goal sharing; ambient-sound library.
