# Flutter — Entertainment / Gamification

> Read [README.md](README.md) first. Payloads = unwrapped `data`. Base: `/api/v1/entertainment`. Content localized by `Accept-Language`.

## Screens → endpoints

| Screen | Endpoint(s) |
|---|---|
| Quiz home / play / result | `GET /quizzes`, `/{id}`, `POST /{id}/attempts`, `GET /quizzes/history` |
| Challenge dashboard | `GET /challenges`, `/mine`, `POST /{id}/join`, `/complete`, `/claim` |
| Rewards (XP/level/badges) | `GET /badges`, `/badges/mine` (level/XP from `/mobile/home` or `/auth/me`) |
| Leaderboard | `GET /leaderboards?category=&period=` |
| Short content feed | `GET /short-content`, `/{id}`, `POST /{id}/like|save|share`, `GET /short-content/saved`, `POST /short-content` |

---

## Quiz

**List** `GET /entertainment/quizzes?category=FINANCE&difficulty=EASY` → `List<QuizResponse>`
```json
{ "quizId":"…","title":"Money Basics","category":"FINANCE","difficulty":"EASY","xpReward":30,"questionCount":3 }
```
**Detail** `GET /entertainment/quizzes/{id}` → questions + options, **correct flag withheld**:
```json
{ "quizId":"…","title":"Money Basics","category":"FINANCE","difficulty":"EASY","xpReward":30,
  "questions":[ { "questionId":"…","questionText":"What is a budget?",
    "options":[ { "optionId":"…","optionText":"A plan for your money" } ] } ] }
```
**Submit** `POST /entertainment/quizzes/{id}/attempts`
```json
{ "answers":[ { "questionId":"…","selectedOptionId":"…" } ] }
```
Result (reveals correct option + explanation after submit):
```json
{ "attemptId":"…","score":100,"correctCount":3,"totalQuestions":3,"xpEarned":30,
  "results":[ { "questionId":"…","selectedOptionId":"…","correctOptionId":"…","correct":true } ] }
```
**History** `GET /entertainment/quizzes/history` → `List<QuizAttemptSummary>` (attemptId, quizId, quizTitle, score, correctCount, totalQuestions, xpEarned, completedAt).
```dart
class QuizResponse {
  final String quizId, title, difficulty; final String? category; final int xpReward, questionCount;
  QuizResponse.fromJson(Map j): quizId=j['quizId'], title=j['title'], difficulty=j['difficulty'],
    category=j['category'], xpReward=j['xpReward'], questionCount=j['questionCount'];
}
```
Rules: XP `round(xpReward × correct/total)`, **once per quiz** — replays return `xpEarned: 0`. `difficulty`: `EASY`/`MEDIUM`/`HARD`. **errorCodes:** `NO_QUESTIONS`, `NOT_FOUND`.

---

## Daily challenges

**Active** `GET /entertainment/challenges` → `List<ChallengeResponse>` (each with the current user's `status`/`progress`)
**Mine** `GET /entertainment/challenges/mine`
**Flow** `POST /{id}/join` → `POST /{id}/complete` → `POST /{id}/claim` (each returns the updated `ChallengeResponse`; claim awards XP once)
```json
{ "challengeId":"…","title":"Do a focus session","description":"…","challengeType":"FOCUS",
  "xpReward":15,"deadline":"2026-07-20T23:59:00","status":"IN_PROGRESS","progress":50 }
```
```dart
class ChallengeResponse {
  final String challengeId, title, challengeType, status; final String? description, deadline;
  final int xpReward, progress;
  ChallengeResponse.fromJson(Map j): challengeId=j['challengeId'], title=j['title'],
    challengeType=j['challengeType'], status=j['status'], description=j['description'],
    deadline=j['deadline'], xpReward=j['xpReward'], progress=j['progress'];
}
```
`status`: `NOT_STARTED`/`IN_PROGRESS`/`COMPLETED`/`CLAIMED` — the **Claim** button is enabled only at `COMPLETED`. `challengeType`: HABIT/TASK/FINANCE/QUIZ/EVENT/COMMUNITY/FOCUS.

---

## Badges

**Catalog** `GET /entertainment/badges` → `List<BadgeResponse>` (each with `earned` flag)
**Mine** `GET /entertainment/badges/mine`
```json
{ "badgeId":"…","name":"Quiz Champion","description":"A quiz winner.",
  "requirement":"Earn XP on 3 different quizzes.","iconUrl":null,"earned":false,"unlockedAt":null }
```
```dart
class BadgeResponse {
  final String badgeId, name; final String? description, requirement, iconUrl, unlockedAt; final bool earned;
  BadgeResponse.fromJson(Map j): badgeId=j['badgeId'], name=j['name'], description=j['description'],
    requirement=j['requirement'], iconUrl=j['iconUrl'], unlockedAt=j['unlockedAt'], earned=j['earned'];
}
```
Badges **auto-unlock** as the user earns XP — refresh after quiz/challenge/RSVP completes. Show locked (grey) vs earned.

---

## Leaderboard

**Get** `GET /entertainment/leaderboards?category=OVERALL_XP&period=ALL_TIME`
```json
{ "category":"OVERALL_XP","period":"ALL_TIME",
  "entries":[ { "rank":1,"userId":"…","name":"Sok","avatarUrl":null,"level":4,"points":300 } ],
  "me":{ "rank":3,"points":50 } }
```
```dart
class LeaderboardEntry {
  final int rank, level; final String userId; final String? name, avatarUrl; final int points;
  LeaderboardEntry.fromJson(Map j): rank=j['rank'], level=j['level'], userId=j['userId'],
    name=j['name'], avatarUrl=j['avatarUrl'], points=(j['points'] as num).toInt();
}
class Leaderboard {
  final String category, period; final List<LeaderboardEntry> entries;
  final int? myRank; final int myPoints;
  Leaderboard.fromJson(Map j): category=j['category'], period=j['period'],
    entries=(j['entries'] as List).map((e)=>LeaderboardEntry.fromJson(e)).toList(),
    myRank=j['me']?['rank'], myPoints=(j['me']?['points'] as num?)?.toInt() ?? 0;
}
```
`category`: OVERALL_XP / PRODUCTIVITY / COMMUNITY_ENGAGEMENT / FINANCIAL_LEARNING / QUIZ_PERFORMANCE. `period`: WEEKLY / MONTHLY / ALL_TIME. `me.rank` is `null` if the user has no points. `FRIENDS` → **errorCode `NOT_IMPLEMENTED`** (hide the tab for now).

---

## Short content (reels)

**Feed** `GET /entertainment/short-content?category=EDUCATION&page=0&size=20` → `PageResponse<ShortContentResponse>`
**Detail** `GET /entertainment/short-content/{id}`
**Create** `POST /entertainment/short-content` → `{ "title":"3 study tips","description":"…","category":"EDUCATION","videoUrl":"https://…","thumbnailUrl":"https://…" }` (metadata only, no upload)
**Like/Save** `POST`/`DELETE /entertainment/short-content/{id}/like` · `/save` · **Share** `POST /{id}/share`
**My saved** `GET /entertainment/short-content/saved`
```json
{ "shortContentId":"…","title":"3 study tips","description":"…","category":"EDUCATION",
  "videoUrl":"https://…","thumbnailUrl":"https://…","creatorId":"…",
  "likeCount":10,"saveCount":4,"shareCount":2,"liked":true,"saved":false }
```
```dart
class ShortContentResponse {
  final String shortContentId, title; final String? description, category, videoUrl, thumbnailUrl, creatorId;
  final int likeCount, saveCount, shareCount; final bool liked, saved;
  ShortContentResponse.fromJson(Map j): shortContentId=j['shortContentId'], title=j['title'],
    description=j['description'], category=j['category'], videoUrl=j['videoUrl'],
    thumbnailUrl=j['thumbnailUrl'], creatorId=j['creatorId'], likeCount=j['likeCount'],
    saveCount=j['saveCount'], shareCount=j['shareCount'], liked=j['liked'], saved=j['saved'];
}
```
Like/save are idempotent; toggle the icon from `liked`/`saved`. **Deferred:** multiplayer quiz, friends ranking, media upload.
