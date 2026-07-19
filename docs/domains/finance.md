# Finance Domain

> Source of truth: DD v5 sheets **Finance**, **Finance Scope** + `backend/docs/FINANCE_PLAN.md`, `FINANCE_LITERACY_PLAN.md`. Read [common.md](common.md) first.
> **Audience:** 🟦 Flutter · 🟩 Backend · 🟨 QA · 🟪 Designer
> ⚠️ **Payment features are SIMULATION ONLY.** No real banking, no real KHQR transfer.

---

## 1. Overview

Finance promotes literacy and responsible money management: **expense tracker**, **budget planner**, **saving goals**, **financial literacy** (bilingual lessons + quizzes with XP + a simulated learning-budget reward), and a **demo wallet / KHQR payment simulation**. It powers Home's Finance Snapshot and the `/mobile/finance-dashboard` BFF.

**Status:** ✅ All 6 phases implemented (Expense, Budget, Saving Goals, Demo Wallet, Financial Literacy, Finance BFF).

---

## 2. Features (DD v5 Final Feature Scope / Finance Scope)

- **Finance Dashboard:** Monthly Summary, Budget Remaining, Saving Progress, Learning XP, Recent Transactions, Quick Actions.
- **Expense Tracker:** Add/Edit/Delete Expense, Categories, Daily Tracking, History, Monthly Summary, Spending Chart.
- **Budget Planner:** Monthly Budget, Category Budget, Spending Progress, Budget Alert, Budget Status.
- **Saving Goals:** Create/Edit/Delete Goal, Target Amount, Target Date, Deposit Saving, Saving History, Progress Bar, Goal Status.
- **Financial Literacy:** Articles, Khmer Tips, Short Lessons, Quiz Learning, XP Reward.
- **Demo Wallet / KHQR Simulation:** Demo Wallet, Scan KHQR Simulation, Mock Payment, Event Payment Simulation, Transaction History, Payment Success. *(Simulation only.)*

---

## 3. User stories

- I can **log expenses** by category and see a **monthly summary** and spending chart.
- I can set a **monthly budget** (and per-category budgets) and get **SAFE/WARNING/LIMIT_REACHED** alerts.
- I can create a **saving goal**, **deposit** toward it, watch a **progress bar**, and it **auto-completes** at target.
- I can read **bilingual financial lessons**, take a **quiz**, earn **XP** on passing, and unlock a **learning-budget** credit to my demo wallet.
- I can **top up** my demo wallet, **scan a mock KHQR / pay** (simulated), and see **transaction history** — and use it to pay for paid events.

---

## 4. Functional requirements 🟩

1. **Expenses:** CRUD, owner-scoped; list filter by `?category` and `?month&year` (date-range, not EXTRACT); `GET /summary` returns total + per-category breakdown (null → `UNCATEGORIZED`, empty month → 0).
2. **Budgets:** one per user per `(month,year)` (**UNIQUE**, clear `BUDGET_ALREADY_EXISTS` error); optional per-category allocations. **spent/remaining/status computed live from expenses on read** (`sumForMonth`, `sumByCategory`) — not the cached counter. Status: SAFE / WARNING (≥80%) / LIMIT_REACHED (≥100%).
3. **Saving goals:** CRUD; **deposit** appends `saving_deposits` and grows `current_amount` in one transaction, auto-completing at target; deposit history; response carries remaining + progress %. Deposits are append-only (counter can't drift); a CANCELLED goal rejects deposits.
4. **Financial literacy:** dashboard (6 topics + progress), lessons by topic, bilingual detail, "finish learning", quiz with the correct answer withheld, submit grades + records an attempt (`finance_quiz_attempts`). Reward on first pass **≥ 60%** (retakes allowed), once: `xpReward` → XP pipeline (`FINANCE_LESSON`) **and** a simulated **$1 learning-budget credit** to the demo wallet (`transaction_type = REWARD`). Guarded by `lesson_progress.rewarded`.
5. **Demo wallet:** get-or-create (USD); top-up (`DEPOSIT`); mock KHQR pay (`MOCK_KHQR_PAYMENT`); paginated transaction history. Every balance move writes a `demo_transactions` row and logs **SIMULATED**; insufficient balance throws before any write. Consumed by Community paid RSVP (`EVENT_PAYMENT`).

---

## 5. Screen requirements 🟦🟪

| Screen | Contents |
|---|---|
| Finance Dashboard | monthly spent, budget remaining, saving progress, learning XP, recent transactions, quick actions |
| Expense List / Add | category, amount, date, payment method; history + **spending chart** |
| Budget | total + per-category budgets; **progress bars**; SAFE/WARNING/LIMIT badge |
| Saving Goals | goal cards with **progress bar**; deposit; saving history |
| Financial Literacy | topic dashboard, lesson (article/**Khmer tip**/video), quiz, score → XP + reward |
| Demo Wallet | balance, top-up, **scan KHQR (mock)**, pay, transaction history, **payment success** |

---

## 6. API requirements 🟩🟦

Base `/api/v1/finance`. (DD Finance Scope uses `/finance/saving-goals` and `/finance/demo-wallet`; implementation uses `/finance/savings` and `/finance/wallet` — noted below.)

| Method | Endpoint | Purpose |
|---|---|---|
| CRUD | `/finance/expenses` (+ `/{id}`) | Expense tracker; `?category&month&year` |
| GET | `/finance/expenses/summary?month=&year=` | Total + per-category |
| CRUD | `/finance/budgets` (+ `/{id}`, `/current`) | Budget planner (live spend) |
| CRUD | `/finance/savings` (+ `/{id}`) | Saving goals |
| POST/GET | `/finance/savings/{id}/deposits` | Deposit + history |
| GET | `/finance/literacy/dashboard`, `/lessons?topic=`, `/lessons/{id}` | Lessons |
| POST | `/finance/literacy/lessons/{id}/complete` | Finish learning |
| GET/POST | `/finance/literacy/lessons/{id}/quiz` · `/quiz/submit` | Quiz + grade + reward |
| GET | `/finance/wallet` | Get-or-create wallet |
| POST | `/finance/wallet/top-up` · `/pay` | Top-up (DEPOSIT) · mock KHQR pay |
| GET | `/finance/wallet/transactions` | History (paginated) |
| GET | `/mobile/finance-dashboard` | Aggregated dashboard (BFF) |

**Domain errors:** `BUDGET_ALREADY_EXISTS`, `GOAL_CANCELLED`, `DEMO_WALLET_INSUFFICIENT_BALANCE`, `NO_QUIZ`.

---

## 7. Database references (DD v5 — exact) 🟩🟨

- **`expenses`**: expense_id PK; user_id FK; title varchar(120); amount decimal(12,2); category; description; expense_date (date); payment_method; audit+deleted_at.
- **`budgets`**: budget_id PK; user_id FK; month; year; total_budget; spent_amount; remaining_amount; status budget_status (SAFE/WARNING/LIMIT_REACHED); **UNIQUE(user_id,month,year)**.
- **`budget_categories`**: budget_category_id PK; budget_id FK; category; allocated_amount; spent_amount; remaining_amount; **UNIQUE(budget_id,category)**.
- **`saving_goals`**: saving_goal_id PK; user_id FK; title; target_amount; current_amount; target_date; status saving_goal_status (IN_PROGRESS/COMPLETED/CANCELLED); audit+deleted_at.
- **`saving_deposits`**: deposit_id PK; saving_goal_id FK; amount; note; deposit_date.
- **`financial_lessons`**: lesson_id PK; **title_en/km, content_en/km** (bilingual); topic; content_type (Article/Tip/Video/Quiz); estimated_time; xp_reward; audit+deleted_at.
- **`lesson_progress`**: lesson_progress_id PK; lesson_id FK; user_id FK; completed; completed_at; **UNIQUE(user_id,lesson_id)**. *(Implementation extends with best_score, quiz_passed, rewarded.)*
- **`demo_wallets`**: wallet_id PK; user_id FK; balance decimal(12,2); currency varchar(3); **UNIQUE(user_id)**.
- **`demo_transactions`**: transaction_id PK; wallet_id FK; transaction_type (MOCK_KHQR_PAYMENT/EVENT_PAYMENT/DEPOSIT/+REWARD); amount; description; status (SUCCESS/FAILED/PENDING); created_at — *simulation only*.

> **Implementation additions:** `financial_quiz_questions` (bilingual Q + 4 options + correct_answer + explanation), `finance_quiz_attempts` (attempt history). Migrations 0020/0021.

---

## 8. Business rules 🟩🟨

- **Budget spend computed on read** from expenses (drift-proof); one budget per month/year.
- Saving deposits are append-only and transactional; goal auto-completes at target.
- Quiz XP + learning-budget reward granted **once** on first pass ≥ 60%; retakes log an attempt but pay nothing.
- Every wallet balance move records a `demo_transactions` row and is labelled **SIMULATED**; insufficient balance fails before any write (no FAILED row).
- All amounts `decimal(12,2)`; **BigDecimal** on the backend.
- **Never imply real money movement** in copy or logs.

---

## 9. Notifications 🟨

- **Finance Reminder** — budget nearing/over limit, saving-goal deadline, daily expense reminder — category `FINANCE`.
- Payment success is an in-app confirmation (simulation).

---

## 10. Localization 🟦🟩

- **Lessons/tips** bilingual (`_en/_km`), Khmer-first; selected by language, EN fallback. Seeded lessons English-only pending Khmer authoring.
- Expense titles/notes are user content (as written).
- The finance dashboard "tip" is English-only for now (needs a bilingual seed).

---

## 11. Permissions 🟩

- All owner-scoped. Lessons/quizzes are read-only system content; attempts and progress are per-user.
- Demo wallet is per-user (`UNIQUE(user_id)`).

---

## 12. Future scope

- Real KHQR / bank integration (replacing the simulation) — a deliberate, separate effort.
- Recurring expenses/budgets, spending analytics, export.
- Bilingual finance-tip seed table; quiz-attempt review history UI.
