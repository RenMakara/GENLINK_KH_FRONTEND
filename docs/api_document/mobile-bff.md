# Flutter — Mobile BFF (dashboards)

> Read [README.md](README.md) first. Payloads = unwrapped `data`. Base: `/api/v1/mobile`. One call per dashboard screen. **Every card can be null/empty** for new users — null-check everything.

## Screens → endpoints

| Screen | Endpoint | Status |
|---|---|---|
| Home (Super Dashboard) | `GET /mobile/home` | ✅ |
| Finance tab landing | `GET /mobile/finance-dashboard` | ✅ |
| Productivity landing | `GET /mobile/productivity-dashboard` | ✅ |
| Profile header (yours) | `GET /mobile/profile-summary` | ✅ |
| Event detail | `GET /mobile/events/{id}` | ⏸ stub |
| Notification center | `GET /mobile/notifications` | ⏸ stub |

---

## `GET /mobile/home`

```json
{
  "user": { "userId":"…","fullName":"Sok","avatarUrl":null,"level":2,"totalXp":150 },
  "todayProgress": { "habitsCompletedToday":2,"habitsTotal":4,"tasksCompleted":1,"tasksTotal":5 },
  "dailyChallenge": { "challengeId":"…","title":"…","description":"…","xpReward":15,"deadline":"…" },
  "financeSnapshot": { "totalBudget":300.00,"spentAmount":180.00,"remainingAmount":120.00,
                       "budgetStatus":"WARNING","savingTarget":800.00,"savingCurrent":150.00 },
  "upcomingEvent": { "eventId":"…","title":"Meetup","dateTime":"…","locationName":"…","coverImageUrl":null },
  "recommendedCommunities": [ { "communityId":"…","name":"Flutter KH","slug":"flutter-kh","category":"TECH","memberCount":42,"avatarUrl":null } ],
  "dailyMotivation": { "motivationId":"…","title":"Start small","content":"…" },
  "feedPreview": [ { "postId":"…","authorName":"Sok","authorAvatarUrl":null,"contentText":"…","imageUrl":null,"likeCount":3,"createdAt":"…" } ]
}
```
Any of `dailyChallenge`, `financeSnapshot`, `upcomingEvent`, `dailyMotivation` may be **null**; the lists may be **empty**.
```dart
class HomeUser {
  final String userId; final String? fullName, avatarUrl; final int level, totalXp;
  HomeUser.fromJson(Map j): userId=j['userId'], fullName=j['fullName'], avatarUrl=j['avatarUrl'],
    level=j['level'], totalXp=j['totalXp'];
}
class TodayProgress {
  final int habitsCompletedToday, habitsTotal, tasksCompleted, tasksTotal;
  TodayProgress.fromJson(Map j): habitsCompletedToday=(j['habitsCompletedToday'] as num).toInt(),
    habitsTotal=(j['habitsTotal'] as num).toInt(), tasksCompleted=(j['tasksCompleted'] as num).toInt(),
    tasksTotal=(j['tasksTotal'] as num).toInt();
}
class HomeResponse {
  final HomeUser user; final TodayProgress todayProgress;
  final Map<String,dynamic>? dailyChallenge, financeSnapshot, upcomingEvent, dailyMotivation;
  final List recommendedCommunities, feedPreview;
  HomeResponse.fromJson(Map j): user=HomeUser.fromJson(j['user']),
    todayProgress=TodayProgress.fromJson(j['todayProgress']),
    dailyChallenge=j['dailyChallenge'], financeSnapshot=j['financeSnapshot'],
    upcomingEvent=j['upcomingEvent'], dailyMotivation=j['dailyMotivation'],
    recommendedCommunities=j['recommendedCommunities'] ?? const [], feedPreview=j['feedPreview'] ?? const [];
}
```
`budgetStatus`: SAFE/WARNING/LIMIT_REACHED. *(Note: the Home finance snapshot currently reads the stored budget counter — a known follow-up; `/mobile/finance-dashboard` has live spend.)*

---

## `GET /mobile/finance-dashboard`

```json
{
  "month": { "month":7,"year":2026,"spent":180.00,"budgetTotal":300.00,"budgetRemaining":120.00,"budgetStatus":"WARNING" },
  "topCategories": [ { "category":"FOOD","amount":90.00 } ],
  "saving": { "totalTarget":800.00,"totalSaved":150.00,"progressPercent":18,"activeGoals":1 },
  "recentExpenses": [ { "expenseId":"…","title":"Coffee","category":"FOOD","amount":2.50,"expenseDate":"2026-07-19" } ],
  "wallet": { "balance":85.00,"currency":"USD" },
  "financialTip": "Track every expense for a week — awareness alone cuts spending.",
  "quickActions": [ "ADD_EXPENSE","SET_BUDGET","NEW_SAVING_GOAL","TOP_UP_WALLET" ]
}
```
`month.budget*` and `wallet` may be **null** (no budget / no wallet). `quickActions` are keys → map to buttons + routes. Reuse the Finance models from [finance.md](finance.md).

---

## `GET /mobile/productivity-dashboard`

```json
{
  "habits": { "total":3,"checkedInToday":1,"items":[ { "habitId":"…","title":"Read","checkedInToday":true } ] },
  "tasks": { "total":5,"completed":2,"dueToday":1,"overdue":1 },
  "goals": [ { "goalId":"…","title":"Ship app","progressPercentage":50.00,"status":"IN_PROGRESS" } ],
  "focus": { "todaySessions":1,"todayMinutes":25,"totalXp":15 },
  "motivation": { "motivationId":"…","title":"Start small","content":"…" }
}
```
`motivation` may be **null**.
```dart
class HabitsToday {
  final int total, checkedInToday; final List items;
  HabitsToday.fromJson(Map j): total=j['total'], checkedInToday=j['checkedInToday'], items=j['items'] ?? const [];
}
class TasksSummary {
  final int total, completed, dueToday, overdue;
  TasksSummary.fromJson(Map j): total=(j['total'] as num).toInt(), completed=(j['completed'] as num).toInt(),
    dueToday=j['dueToday'], overdue=j['overdue'];
}
```

---

## `GET /mobile/profile-summary` (your screen)

```json
{ "userId":"…","fullName":"Sok","username":"sok","email":"…","phoneNumber":null,"avatarUrl":null,
  "bio":"…","universityName":null,"location":"…","emailVerified":true,"totalXp":150,"level":2, … }
```
Aggregated identity + counts for the profile header. (Auth/Profile owned by the doc author — see [profile-settings.md](profile-settings.md).)

---

## Deferred (do not wire yet)
`GET /mobile/events/{id}` and `GET /mobile/notifications` return TODO stubs.
