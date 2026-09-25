# Flutter — Finance

> Read [README.md](README.md) first (envelope, ApiClient, error handling). All payloads below are the **unwrapped `data`**. Base: `/api/v1/finance`. ⚠️ Wallet/payment is **simulation only** — label it in the UI.

## Screens → endpoints

| Screen | Endpoint(s) |
|---|---|
| Finance dashboard | `GET /mobile/finance-dashboard` (see [mobile-bff.md](mobile-bff.md)) |
| Expense list / add / edit | `GET/POST/PUT/DELETE /finance/expenses`, `GET /finance/expenses/summary` |
| Budget | `POST/GET/PUT /finance/budgets`, `GET /finance/budgets/current` |
| Saving goals | `GET/POST/PUT/DELETE /finance/savings`, `POST/GET /finance/savings/{id}/deposits` |
| Financial literacy | `GET /finance/literacy/dashboard`, `/lessons?topic=`, `/lessons/{id}`, quiz |
| Demo wallet | `GET /finance/wallet`, `POST /finance/wallet/top-up`, `/pay`, `GET /finance/wallet/transactions` |

---

## Expenses

**Create** `POST /finance/expenses`
```json
{ "title": "Coffee", "amount": 2.50, "category": "FOOD", "description": "iced latte",
  "expenseDate": "2026-07-19", "paymentMethod": "CASH" }
```
**List** `GET /finance/expenses?category=FOOD&month=7&year=2026&page=0&size=20` → `PageResponse<ExpenseResponse>`
**Summary** `GET /finance/expenses/summary?month=7&year=2026`
```json
{ "month": 7, "year": 2026, "total": 120.00,
  "categories": [ { "category": "FOOD", "amount": 60.00 }, { "category": "UNCATEGORIZED", "amount": 60.00 } ] }
```
```dart
class ExpenseResponse {
  final String expenseId, title, category;
  final double amount;
  final String? description, paymentMethod;
  final String expenseDate; // ISO date
  ExpenseResponse.fromJson(Map<String, dynamic> j)
    : expenseId = j['expenseId'], title = j['title'], category = j['category'] ?? '',
      amount = (j['amount'] as num).toDouble(), description = j['description'],
      paymentMethod = j['paymentMethod'], expenseDate = j['expenseDate'];
}
```
**errorCodes:** `VALIDATION_ERROR`, `NOT_FOUND`.

---

## Budgets

**Create** `POST /finance/budgets`
```json
{ "month": 7, "year": 2026, "totalBudget": 300.00,
  "categories": [ { "category": "FOOD", "allocatedAmount": 120.00 } ] }
```
**Current month** `GET /finance/budgets/current?month=7&year=2026` → `BudgetResponse` (with category breakdown)
```json
{ "budgetId": "…", "month": 7, "year": 2026, "totalBudget": 300.00,
  "spentAmount": 180.00, "remainingAmount": 120.00, "status": "WARNING",
  "categories": [ { "category": "FOOD", "allocatedAmount": 120.00, "spentAmount": 90.00, "remainingAmount": 30.00 } ] }
```
```dart
class CategoryBudget {
  final String category; final double allocatedAmount, spentAmount, remainingAmount;
  CategoryBudget.fromJson(Map j) : category = j['category'],
    allocatedAmount = (j['allocatedAmount'] as num).toDouble(),
    spentAmount = (j['spentAmount'] as num).toDouble(),
    remainingAmount = (j['remainingAmount'] as num).toDouble();
}
class BudgetResponse {
  final String budgetId, status; final int month, year;
  final double totalBudget, spentAmount, remainingAmount;
  final List<CategoryBudget> categories;
  BudgetResponse.fromJson(Map j) : budgetId = j['budgetId'], status = j['status'],
    month = j['month'], year = j['year'],
    totalBudget = (j['totalBudget'] as num).toDouble(),
    spentAmount = (j['spentAmount'] as num).toDouble(),
    remainingAmount = (j['remainingAmount'] as num).toDouble(),
    categories = (j['categories'] as List).map((e)=>CategoryBudget.fromJson(e)).toList();
}
```
`status` enum: `SAFE` / `WARNING` (≥80%) / `LIMIT_REACHED` (≥100%) — colour the progress bar accordingly.
**errorCodes:** `BUDGET_ALREADY_EXISTS` (one budget per month/year), `VALIDATION_ERROR`.

---

## Saving goals

**Create** `POST /finance/savings` → `{ "title": "New laptop", "targetAmount": 800.00, "targetDate": "2026-12-01" }`
**List** `GET /finance/savings?status=IN_PROGRESS&page=0&size=20` → `PageResponse<SavingGoalResponse>`
**Deposit** `POST /finance/savings/{id}/deposits` → `{ "amount": 50.00, "note": "allowance" }` (returns updated goal)
**History** `GET /finance/savings/{id}/deposits` → `List<SavingDepositResponse>`
```json
{ "savingGoalId":"…","title":"New laptop","targetAmount":800.00,"currentAmount":150.00,
  "remainingAmount":650.00,"progressPercent":18,"targetDate":"2026-12-01","status":"IN_PROGRESS" }
```
```dart
class SavingGoalResponse {
  final String savingGoalId, title, status; final String? targetDate;
  final double targetAmount, currentAmount, remainingAmount; final int progressPercent;
  SavingGoalResponse.fromJson(Map j) : savingGoalId=j['savingGoalId'], title=j['title'],
    status=j['status'], targetDate=j['targetDate'],
    targetAmount=(j['targetAmount'] as num).toDouble(),
    currentAmount=(j['currentAmount'] as num).toDouble(),
    remainingAmount=(j['remainingAmount'] as num).toDouble(),
    progressPercent=j['progressPercent'];
}
```
`status`: `IN_PROGRESS`/`COMPLETED`/`CANCELLED`. **errorCodes:** `GOAL_CANCELLED` (deposit into cancelled), `NOT_FOUND`.

---

## Demo wallet (simulation)

**Get/create** `GET /finance/wallet` → `WalletResponse`
**Top-up** `POST /finance/wallet/top-up` → `{ "amount": 100.00, "note": "demo top-up" }`
**Pay (mock KHQR)** `POST /finance/wallet/pay` → `{ "amount": 15.00, "merchant": "Brown Coffee", "note": "iced latte" }`
**History** `GET /finance/wallet/transactions?page=0&size=20` → `PageResponse<TransactionResponse>`
```json
{ "walletId":"…", "balanceUsd": 85.00, "balanceKhr": 0.00 }
```
```dart
class WalletResponse {
  final String walletId; final double balanceUsd, balanceKhr;
  WalletResponse.fromJson(Map j) : walletId=j['walletId'],
    balanceUsd=(j['balanceUsd'] as num).toDouble(), balanceKhr=(j['balanceKhr'] as num).toDouble();
}
class TransactionResponse {
  final String transactionId, transactionType, direction, currency, status, createdAt;
  final String? description, provider, providerRef; final double amount;
  TransactionResponse.fromJson(Map j) : transactionId=j['transactionId'],
    transactionType=j['transactionType'], direction=j['direction'], currency=j['currency'],
    status=j['status'], createdAt=j['createdAt'], description=j['description'],
    provider=j['provider'], providerRef=j['providerRef'], amount=(j['amount'] as num).toDouble();
}
```
`transactionType`: `DEPOSIT`/`KHQR_PAYMENT`/`EVENT_PAYMENT`/`REWARD`. Top-up/payment accept optional `currency` (default `USD`). **errorCodes:** `DEMO_WALLET_INSUFFICIENT_BALANCE`.

---

## Financial literacy

**Dashboard** `GET /finance/literacy/dashboard`
```json
{ "totalLessons": 6, "completedLessons": 2, "literacyXp": 40,
  "topics": [ { "topic": "SAVING_MONEY", "lessonCount": 1, "completedCount": 1 } ] }
```
**Lessons** `GET /finance/literacy/lessons?topic=SAVING_MONEY` → `List<LessonSummaryResponse>`
**Lesson detail** `GET /finance/literacy/lessons/{id}` → `LessonDetailResponse` (title/content localized by `Accept-Language`)
**Finish** `POST /finance/literacy/lessons/{id}/complete`
**Quiz** `GET /finance/literacy/lessons/{id}/quiz` → questions (no correct answer)
**Submit** `POST /finance/literacy/lessons/{id}/quiz/submit`
```json
{ "answers": [ { "questionId": "…", "selectedOption": "B" } ] }
```
Result:
```json
{ "score": 100, "correctCount": 2, "totalQuestions": 2, "passed": true,
  "xpEarned": 20, "learningBudgetCredited": 1.00,
  "results": [ { "questionId":"…","selectedOption":"B","correctOption":"B","correct":true,"explanation":"…" } ] }
```
```dart
class LessonSummaryResponse {
  final String lessonId, title, topic, contentType; final int? estimatedTime; final int xpReward;
  final bool completed, quizPassed;
  LessonSummaryResponse.fromJson(Map j) : lessonId=j['lessonId'], title=j['title'], topic=j['topic'],
    contentType=j['contentType'], estimatedTime=j['estimatedTime'], xpReward=j['xpReward'],
    completed=j['completed'], quizPassed=j['quizPassed'];
}
class QuizResult {
  final int score, correctCount, totalQuestions, xpEarned; final bool passed;
  final double learningBudgetCredited;
  QuizResult.fromJson(Map j) : score=j['score'], correctCount=j['correctCount'],
    totalQuestions=j['totalQuestions'], xpEarned=j['xpEarned'], passed=j['passed'],
    learningBudgetCredited=(j['learningBudgetCredited'] as num).toDouble();
}
```
Rules to reflect in UI: XP + $1 learning-budget granted **once** on first pass ≥ 60%; replays show `xpEarned: 0`. `contentType`: `ARTICLE`/`KHMER_TIP`/`VIDEO` (video → use `mediaUrl`). **errorCodes:** `NO_QUIZ`, `NOT_FOUND`.
