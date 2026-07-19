# Flutter — Community

> Read [README.md](README.md) first. Payloads = unwrapped `data`. Base: `/api/v1/community`. User content is shown **as written**. ⏸ Chat, Polls, Stories are not built yet.

## Screens → endpoints

| Screen | Endpoint(s) |
|---|---|
| Home feed | `GET /community/feed` |
| Create / edit post | `POST/PUT/DELETE /community/posts` |
| Post detail | `GET /community/posts/{id}`, `GET/POST /posts/{id}/comments`, `POST/DELETE /posts/{id}/like`, `/save` |
| Hashtag | `GET /community/hashtags/{tag}/posts` |
| Communities | `GET /community/communities`, `/discover`, `POST /{id}/join`, `/leave` |
| Events list / detail | `GET /community/events`, `/{id}`, `POST /{id}/rsvp` |
| Forum | `GET/POST /community/forum/discussions`, `POST /{id}/react`, `/report`, comments |
| Opportunities | `GET /community/opportunities`, `/{id}`, `POST /{id}/save` |
| Saved | saved posts + saved opportunities |

---

## Feed & posts

**Feed** `GET /community/feed?page=0&size=20` → `PageResponse<PostResponse>`
**Create** `POST /community/posts` → `{ "contentText":"Hello #flutter","imageUrl":null,"postType":"TEXT","visibility":"PUBLIC" }`
**Like/Save** `POST`/`DELETE /community/posts/{id}/like` · `/save` (idempotent, returns updated post)
```json
{ "postId":"…","author":{ "userId":"…","fullName":"Sok","username":"sok","avatarUrl":null },
  "contentText":"Hello #flutter","imageUrl":null,"postType":"TEXT","visibility":"PUBLIC","language":"ENGLISH",
  "likeCount":3,"commentCount":1,"likedByMe":true,"savedByMe":false,"hashtags":["flutter"],"createdAt":"…" }
```
```dart
class AuthorSummary {
  final String userId; final String? fullName, username, avatarUrl;
  AuthorSummary.fromJson(Map j): userId=j['userId'], fullName=j['fullName'],
    username=j['username'], avatarUrl=j['avatarUrl'];
}
class PostResponse {
  final String postId; final AuthorSummary? author; final String? contentText, imageUrl;
  final String postType, visibility, language; final int likeCount, commentCount;
  final bool likedByMe, savedByMe; final List<String> hashtags; final String createdAt;
  PostResponse.fromJson(Map j): postId=j['postId'],
    author=j['author']==null?null:AuthorSummary.fromJson(j['author']),
    contentText=j['contentText'], imageUrl=j['imageUrl'], postType=j['postType'],
    visibility=j['visibility'], language=j['language'] ?? 'ENGLISH',
    likeCount=j['likeCount'] ?? 0, commentCount=j['commentCount'] ?? 0,
    likedByMe=j['likedByMe'], savedByMe=j['savedByMe'],
    hashtags=(j['hashtags'] as List?)?.cast<String>() ?? const [], createdAt=j['createdAt'];
}
```
`postType`: TEXT/IMAGE/POLL(⏸)/ANNOUNCEMENT. `visibility`: PUBLIC/FRIENDS/COMMUNITY. Toggle heart/bookmark from `likedByMe`/`savedByMe`.

**Comments** `GET /community/posts/{id}/comments` → `PageResponse<CommentResponse>`; `POST` → `{ "content":"Nice!","parentCommentId":null }`. Fields: `commentId, author, content, parentCommentId, language, likeCount, mine, createdAt`.

---

## Communities & follows

**List/discover** `GET /community/communities` · `GET /community/communities/discover` (excludes joined) → `List<CommunityResponse>`
**Join/leave** `POST /community/communities/{id}/join` · `/leave`
```json
{ "communityId":"…","name":"Flutter KH","slug":"flutter-kh","description":"…","category":"TECH",
  "coverImageUrl":null,"avatarUrl":null,"privacy":"PUBLIC","memberCount":42,"postCount":10,
  "joined":true,"myRole":"MEMBER","createdAt":"…" }
```
```dart
class CommunityResponse {
  final String communityId, name, slug, privacy; final String? description, category, coverImageUrl, avatarUrl, myRole;
  final int memberCount, postCount; final bool joined; final String createdAt;
  CommunityResponse.fromJson(Map j): communityId=j['communityId'], name=j['name'], slug=j['slug'],
    privacy=j['privacy'], description=j['description'], category=j['category'],
    coverImageUrl=j['coverImageUrl'], avatarUrl=j['avatarUrl'], myRole=j['myRole'],
    memberCount=j['memberCount'] ?? 0, postCount=j['postCount'] ?? 0, joined=j['joined'], createdAt=j['createdAt'];
}
```

---

## Events & RSVP

**List/detail** `GET /community/events?page=0&size=20` · `GET /community/events/{id}` → `EventResponse`
**RSVP** `POST /community/events/{id}/rsvp` → `{ "status":"JOINED" }` (or INTERESTED). Paid events debit the demo wallet.
```json
{ "eventId":"…","organizer":{…},"title":"Meetup","description":"…","category":"TECH","coverImageUrl":null,
  "dateTime":"2026-08-01T18:00:00","locationName":"Phnom Penh","attendeeLimit":50,"attendeeCount":12,
  "status":"PUBLISHED","language":"ENGLISH","paid":true,"price":5.00,"myRsvpStatus":null,"full":false,"createdAt":"…" }
```
RSVP result: `{ "eventId":"…","status":"JOINED","attendeeCount":13,"xpAwarded":10,"amountPaid":5.00,"simulatedPayment":true }`
```dart
class EventResponse {
  final String eventId; final AuthorSummary? organizer; final String title, status;
  final String? description, category, coverImageUrl, dateTime, locationName, language, myRsvpStatus;
  final int? attendeeLimit; final int attendeeCount; final bool paid, full; final double? price; final String createdAt;
  EventResponse.fromJson(Map j): eventId=j['eventId'],
    organizer=j['organizer']==null?null:AuthorSummary.fromJson(j['organizer']),
    title=j['title'], status=j['status'], description=j['description'], category=j['category'],
    coverImageUrl=j['coverImageUrl'], dateTime=j['dateTime'], locationName=j['locationName'],
    language=j['language'], myRsvpStatus=j['myRsvpStatus'], attendeeLimit=j['attendeeLimit'],
    attendeeCount=j['attendeeCount'] ?? 0, paid=j['paid'], full=j['full'],
    price=(j['price'] as num?)?.toDouble(), createdAt=j['createdAt'];
}
```
Disable RSVP when `full`; if `paid`, show price + "simulated payment"; handle `DEMO_WALLET_NOT_FOUND` / `DEMO_WALLET_INSUFFICIENT_BALANCE` (prompt to top up the wallet). `myRsvpStatus`: null / JOINED / INTERESTED / CANCELLED / ATTENDED.

---

## Forum

**List/create** `GET/POST /community/forum/discussions` → `{ "title":"…","content":"…","category":"STUDY","anonymous":true }`
**React / report** `POST /community/forum/discussions/{id}/react` · `/report`
```json
{ "discussionId":"…","author":{…}|null,"title":"…","content":"…","category":"STUDY","anonymous":true,
  "language":"ENGLISH","reactionCount":4,"commentCount":2,"reactedByMe":false,"mine":false,"createdAt":"…" }
```
```dart
class DiscussionResponse {
  final String discussionId, title; final AuthorSummary? author; final String? content, category, language;
  final bool anonymous, reactedByMe, mine; final int reactionCount, commentCount; final String createdAt;
  DiscussionResponse.fromJson(Map j): discussionId=j['discussionId'], title=j['title'],
    author=j['author']==null?null:AuthorSummary.fromJson(j['author']), content=j['content'],
    category=j['category'], language=j['language'], anonymous=j['anonymous'],
    reactedByMe=j['reactedByMe'], mine=j['mine'], reactionCount=j['reactionCount'] ?? 0,
    commentCount=j['commentCount'] ?? 0, createdAt=j['createdAt'];
}
```
When `anonymous`, `author` is null — render "Anonymous". One reaction / one report per user (toggle from `reactedByMe`).

---

## Opportunities

**List/detail** `GET /community/opportunities?type=JOB` · `/{id}` · **Save** `POST /community/opportunities/{id}/save`
```json
{ "opportunityId":"…","title":"Intern","organization":"Acme","type":"INTERNSHIP","description":"…",
  "deadline":"2026-09-01","location":"Phnom Penh","applyLink":"https://…","savedByMe":false,"expired":false,"createdAt":"…" }
```
```dart
class OpportunityResponse {
  final String opportunityId, title; final String? organization, type, description, deadline, location, applyLink;
  final bool savedByMe, expired; final String createdAt;
  OpportunityResponse.fromJson(Map j): opportunityId=j['opportunityId'], title=j['title'],
    organization=j['organization'], type=j['type'], description=j['description'], deadline=j['deadline'],
    location=j['location'], applyLink=j['applyLink'], savedByMe=j['savedByMe'], expired=j['expired'],
    createdAt=j['createdAt'];
}
```
Grey out `expired`; open `applyLink` externally; toggle bookmark from `savedByMe`.

---

## Deferred (do not wire)
Chat (private/group, messages, read status), Polls, Stories — tables exist but no endpoints.
