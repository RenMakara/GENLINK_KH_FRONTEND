# Flutter — Lifestyle (Productivity)

> Read [README.md](README.md) first. Payloads = unwrapped `data`. Base: `/api/v1/productivity`.

## Screens → endpoints

| Screen | Endpoint(s) |
|---|---|
| Productivity landing | `GET /mobile/productivity-dashboard` ([mobile-bff.md](mobile-bff.md)) |
| Habits | `GET/POST/PUT/DELETE /productivity/habits`, `POST /habits/{id}/check-in` |
| Tasks | `GET/POST/PUT/DELETE /productivity/tasks`, `POST /tasks/{id}/complete` |
| Goals + milestones | `GET/POST/PUT/DELETE /productivity/goals`, `/goals/{id}/milestones…` |
| Focus timer | `POST /productivity/focus-sessions/start`, `/{id}/complete`, `GET /focus-sessions`, `/stats` |
| Motivation | `GET /productivity/motivation`, `/saved`, `POST/DELETE /motivation/{id}/save` |

---

## Habits

**Create** `POST /productivity/habits` → `{ "title":"Read 20 min","category":"LEARNING","frequency":"DAILY","reminderTime":"07:30:00" }`
**List** `GET /productivity/habits` → `List<HabitResponse>`
**Check-in** `POST /productivity/habits/{id}/check-in` → body optional `{ "date":"2026-07-19","completed":true }` (omit date = today; `completed:false` = undo). Returns the habit with recomputed streak.
```json
{ "habitId":"…","title":"Read 20 min","category":"LEARNING","frequency":"DAILY",
  "reminderTime":"07:30:00","streakCount":3,"completionRate":40.00,"checkedInToday":true }
```
```dart
class HabitResponse {
  final String habitId, title; final String? category, frequency, reminderTime;
  final int streakCount; final double completionRate; final bool checkedInToday;
  HabitResponse.fromJson(Map j) : habitId=j['habitId'], title=j['title'], category=j['category'],
    frequency=j['frequency'], reminderTime=j['reminderTime'], streakCount=j['streakCount'],
    completionRate=(j['completionRate'] as num).toDouble(), checkedInToday=j['checkedInToday'];
}
```
UI: use `streakCount` + `completionRate` for the progress ring; `checkedInToday` toggles the check button. XP (+5) is awarded server-side on first check-in of the day.

---

## Tasks

**Create** `POST /productivity/tasks` → `{ "title":"Finish API","description":"…","priority":"HIGH","category":"WORK","dueDate":"2026-07-20T17:00:00","reminderTime":"2026-07-20T09:00:00" }`
**List** `GET /productivity/tasks?scope=overdue&category=WORK&priority=HIGH&completed=false` → `List<TaskResponse>` (`scope`: `today`/`overdue`/`upcoming`)
**Complete/reopen** `POST /productivity/tasks/{id}/complete?completed=true`
```json
{ "taskId":"…","title":"Finish API","description":"…","priority":"HIGH","category":"WORK",
  "dueDate":"2026-07-20T17:00:00","reminderTime":"2026-07-20T09:00:00","completed":false,"overdue":true }
```
```dart
class TaskResponse {
  final String taskId, title; final String? description, priority, category, dueDate, reminderTime;
  final bool completed, overdue;
  TaskResponse.fromJson(Map j) : taskId=j['taskId'], title=j['title'], description=j['description'],
    priority=j['priority'], category=j['category'], dueDate=j['dueDate'], reminderTime=j['reminderTime'],
    completed=j['completed'], overdue=j['overdue'];
}
```
UI: `overdue` (past due + not completed) → red; completing awards +5 XP once. **errorCodes:** `NOT_FOUND`.

---

## Goals + milestones

**Create** `POST /productivity/goals` → `{ "title":"Ship app","description":"…","goalType":"CAREER","deadline":"2026-12-31" }`
**Detail** `GET /productivity/goals/{id}` → `GoalResponse` (with milestones)
**Add milestone** `POST /productivity/goals/{id}/milestones` → `{ "title":"Finish tutorial" }`
**Toggle milestone** `POST /productivity/goals/{id}/milestones/{mid}/complete?completed=true`
**Delete milestone** `DELETE /productivity/goals/{id}/milestones/{mid}`
```json
{ "goalId":"…","title":"Ship app","description":"…","goalType":"CAREER","deadline":"2026-12-31",
  "progressPercentage":50.00,"status":"IN_PROGRESS","totalMilestones":2,"completedMilestones":1,
  "milestones":[ { "milestoneId":"…","title":"Finish tutorial","completed":true,"completedAt":"2026-07-19T10:00:00" } ] }
```
```dart
class Milestone {
  final String milestoneId, title; final bool completed; final String? completedAt;
  Milestone.fromJson(Map j): milestoneId=j['milestoneId'], title=j['title'],
    completed=j['completed'], completedAt=j['completedAt'];
}
class GoalResponse {
  final String goalId, title, status; final String? description, goalType, deadline;
  final double progressPercentage; final int totalMilestones, completedMilestones;
  final List<Milestone> milestones;
  GoalResponse.fromJson(Map j): goalId=j['goalId'], title=j['title'], status=j['status'],
    description=j['description'], goalType=j['goalType'], deadline=j['deadline'],
    progressPercentage=(j['progressPercentage'] as num).toDouble(),
    totalMilestones=j['totalMilestones'], completedMilestones=j['completedMilestones'],
    milestones=(j['milestones'] as List).map((e)=>Milestone.fromJson(e)).toList();
}
```
`status`: `NOT_STARTED`/`IN_PROGRESS`/`COMPLETED` (auto-completes at 100%). Progress bar = `progressPercentage`.

---

## Focus timer

**Start** `POST /productivity/focus-sessions/start` → `{ "mode":"POMODORO","durationMinutes":25,"ambientSound":"RAIN" }`
**Complete** `POST /productivity/focus-sessions/{id}/complete` (awards XP once)
**History** `GET /productivity/focus-sessions?page=0&size=20` → `PageResponse<FocusSessionResponse>`
**Stats** `GET /productivity/focus-sessions/stats`
```json
{ "sessionId":"…","mode":"POMODORO","durationMinutes":25,"ambientSound":"RAIN",
  "completed":true,"xpEarned":5,"startedAt":"…","endedAt":"…" }
```
```dart
class FocusStats {
  final int todaySessions, todayMinutes; final int totalSessions, totalMinutes, totalXp;
  FocusStats.fromJson(Map j): todaySessions=j['todaySessions'], todayMinutes=j['todayMinutes'],
    totalSessions=j['totalSessions'], totalMinutes=j['totalMinutes'], totalXp=j['totalXp'];
}
```
XP = `min(30, minutes/5)`; a session < 5 min earns 0. Completion is idempotent.

---

## Motivation

**List** `GET /productivity/motivation?category=FOCUS` → `List<MotivationResponse>` (title/content localized by language)
**Save / unsave** `POST` / `DELETE /productivity/motivation/{id}/save`
**My saved** `GET /productivity/motivation/saved`
```json
{ "motivationId":"…","title":"Start small","content":"…","category":"MINDSET","savedCount":5,"saved":true }
```
```dart
class MotivationResponse {
  final String motivationId, title, content; final String? category; final int savedCount; final bool saved;
  MotivationResponse.fromJson(Map j): motivationId=j['motivationId'], title=j['title'],
    content=j['content'], category=j['category'], savedCount=j['savedCount'], saved=j['saved'];
}
```
Send `Accept-Language: km` for Khmer (currently falls back to English where Khmer isn't seeded).
