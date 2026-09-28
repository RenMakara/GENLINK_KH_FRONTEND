# Flutter — Community

> Read [README.md](README.md) first. Payloads = unwrapped `data`. Base: `/api/v1/community`. User content is shown **as written**. Chat REST/new-message realtime, Polls, and Stories are implemented; advanced chat realtime remains deferred.

## Screens → endpoints

| Screen | Endpoint(s) |
|---|---|
| Home feed | `GET /community/posts/feed` |
| Create / edit post | `POST/PUT/DELETE /community/posts` |
| Post detail | `GET /community/posts/{id}`, `GET/POST /posts/{id}/comments`, `POST/DELETE /posts/{id}/like`, `/save` |
| Hashtag | `GET /community/hashtags/{tag}/posts` |
| Communities | `GET /community/communities`, `/discover`, `POST /{id}/join`, `/leave` |
| Create event | `POST /community/events` |
| Events list / detail | `GET /community/events`, `/{id}`, `PUT/DELETE /{id}` |
| Event registration | `POST/DELETE /community/events/{id}/rsvp`, `GET /community/events/{id}/attendees` |
| Forum | `GET/POST /community/discussions`, `POST/DELETE /{id}/react`, `/report`, comments |
| Stories | `GET/POST /community/stories`, `POST/DELETE /{id}/like`, `/view`, `/viewers` |
| Opportunities | `GET /community/opportunities`, `/{id}`; admin `POST/PUT/DELETE` |
| Saved | `GET/POST /profile/saved`, `DELETE /profile/saved/{itemType}/{itemId}` |

---

## Feed & posts

**Feed** `GET /community/posts/feed?page=0&size=20` → `PageResponse<PostResponse>`
**Create** `POST /community/posts` → `{ "contentText":"Hello #flutter","imageUrl":null,"postType":"TEXT","visibility":"PUBLIC" }`
**Like** `POST /community/posts/{id}/like` adds the reaction; `DELETE` removes it. Both are idempotent and return `data: { "likeCount": 3 }`.
**Save** `POST /profile/saved` with `{ "itemType":"POST","itemId":"<uuid>" }` returns a `SavedItemResponse`; `DELETE /profile/saved/POST/{id}` removes it. `GET /profile/saved/check?itemType=POST&itemId=<uuid>` returns `{ "saved":true }`.
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
`postType`: TEXT/IMAGE/VIDEO/POLL/ANNOUNCEMENT. `visibility`: PUBLIC/FRIENDS/COMMUNITY/ONLY_ME. `ONLY_ME` is author-only; `FRIENDS` requires a mutual accepted follow; `COMMUNITY` requires active membership in the attached community. Toggle heart/bookmark from `likedByMe`/`savedByMe`.

**Comments** `GET /community/posts/{id}/comments` → `PageResponse<CommentResponse>`; `POST` → `{ "content":"Nice!","parentCommentId":null }`. Fields: `commentId, author, content, parentCommentId, language, likeCount, mine, createdAt`. Comment reactions use `POST`/`DELETE /community/comments/{commentId}/like` and return `{ "likeCount": 1 }`.

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

**Create** `POST /community/events` and **update** `PUT /community/events/{id}` accept the complete event detail contract:
```json
{ "title":"Meetup", "description":"…", "category":"TECH", "coverImageUrl":null,
  "startDateTime":"2026-08-01T18:00:00", "endDateTime":"2026-08-01T20:00:00",
  "mode":"IN_PERSON", "meetingUrl":null, "locationName":"Phnom Penh",
  "latitude":11.5564, "longitude":104.9282, "attendeeLimit":50,
  "status":"PUBLISHED", "language":"ENGLISH", "paid":false, "price":null, "currency":null }
```
`endDateTime` must be after `startDateTime`. `mode=ONLINE` requires an http(s) `meetingUrl`; `mode=IN_PERSON` requires `locationName`. Coordinates are optional but must be supplied as a pair.

For a paid event, send `paid=true`, a `price` greater than zero, and
`currency="USD"` or `currency="KHR"`. The amount is expressed in that currency;
there is no USD/KHR conversion. Free events use `paid=false`, `price=null` and
`currency=null`.

**List/detail** `GET /community/events?page=0&size=20` · `GET /community/events/{id}` → `EventResponse`
**RSVP** `POST /community/events/{id}/rsvp` accepts the full registration form. Paid events debit the demo wallet.
```json
{ "eventId":"…","organizer":{…},"title":"Meetup","description":"…","category":"TECH","coverImageUrl":null,
  "startDateTime":"2026-08-01T18:00:00","endDateTime":"2026-08-01T20:00:00","mode":"IN_PERSON",
  "meetingUrl":null,"locationName":"Phnom Penh","latitude":11.5564,"longitude":104.9282,
  "attendeeLimit":50,"attendeeCount":12,
  "status":"PUBLISHED","language":"ENGLISH","paid":true,"price":5.00,"currency":"USD","myRsvpStatus":null,"full":false,"createdAt":"…" }
```
```json
{ "fullName":"Registered Student", "email":"student@example.com", "phoneNumber":"012345678",
  "university":"ACLEDA University of Business", "faculty":"Computer Science",
  "studyYear":"Year 3", "termsAccepted":true }
```
RSVP result: `{ "eventId":"…","status":"JOINED","attendeeCount":13,"xpAwarded":10,"amountPaid":5.00,"simulatedPayment":true }`
```dart
class EventResponse {
  final String eventId; final AuthorSummary? organizer; final String title, status;
  final String? description, category, coverImageUrl, startDateTime, endDateTime, mode,
      meetingUrl, locationName, language, myRsvpStatus;
  final double? latitude, longitude;
  final int? attendeeLimit; final int attendeeCount; final bool paid, full; final double? price; final String? currency; final String createdAt;
  EventResponse.fromJson(Map j): eventId=j['eventId'],
    organizer=j['organizer']==null?null:AuthorSummary.fromJson(j['organizer']),
    title=j['title'], status=j['status'], description=j['description'], category=j['category'],
    coverImageUrl=j['coverImageUrl'], startDateTime=j['startDateTime'], endDateTime=j['endDateTime'],
    mode=j['mode'], meetingUrl=j['meetingUrl'], locationName=j['locationName'],
    latitude=(j['latitude'] as num?)?.toDouble(), longitude=(j['longitude'] as num?)?.toDouble(),
    language=j['language'], myRsvpStatus=j['myRsvpStatus'], attendeeLimit=j['attendeeLimit'],
    attendeeCount=j['attendeeCount'] ?? 0, paid=j['paid'], full=j['full'],
    price=(j['price'] as num?)?.toDouble(), currency=j['currency'], createdAt=j['createdAt'];
}
```
Registration request fields are all required and `termsAccepted` must be true. Disable RSVP when `full`; if `paid`, show the currency-formatted price and confirm before submitting. The backend debits `balanceUsd` or `balanceKhr` matching `currency`; handle `VALIDATION_ERROR`, `DEMO_WALLET_NOT_FOUND` / `DEMO_WALLET_INSUFFICIENT_BALANCE` and `EVENT_CURRENCY_MISSING`. `amountPaid` is returned in the event currency and `simulatedPayment=true`; there is no conversion. `myRsvpStatus`: null / JOINED / CANCELLED / ATTENDED.

---

## Forum

**List/create** `GET/POST /community/forum/discussions` → `{ "title":"…","content":"…","category":"STUDY","anonymous":true }`
**React / report** `POST`/`DELETE /community/discussions/{id}/react` · `POST /community/discussions/{id}/report`. Reactions return `{ "reactionCount": 4 }`; repeated add/remove requests are idempotent.
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
When `anonymous`, `author` is null — render "Anonymous". Use POST to add a reaction and DELETE to remove it; both requests are idempotent. Reporting is also idempotent per user.

---

## Stories

**Feed** `GET /community/stories` returns the current user's active stories and eligible followed users' stories, grouped by author. **Create** `POST /community/stories` accepts `mediaId` (preferred after upload/confirm) or a `mediaUrl`, plus `mediaType` (`IMAGE` or `VIDEO`), optional `caption`, `visibility`, `replyPermission`, and `allowReactions`.

Example request and response data:
```json
{ "mediaId":"<uuid>", "mediaType":"IMAGE", "caption":"Campus day", "visibility":"FRIENDS",
  "replyPermission":"EVERYONE", "allowReactions":true }
```
```json
{ "storyId":"…", "mediaType":"IMAGE", "mediaUrl":"https://signed.example/…", "caption":"Campus day",
  "seen":true, "createdAt":"…", "expiresAt":"…", "visibility":"FRIENDS",
  "replyPermission":"EVERYONE", "allowReactions":true, "reactionCount":0, "reactedByMe":false }
```
Stories expire 24 hours after creation.

**React** `POST /community/stories/{id}/like` adds the caller's reaction; `DELETE` removes it. Both are idempotent; the successful envelope omits `data` because it is null. **View** `POST /{id}/view` is idempotent. **Viewers** `GET /{id}/viewers` is owner-only; unauthorized story/viewer access is returned as not found.

Stories currently accept `PUBLIC`, `FRIENDS`, and `ONLY_ME`; create requests with `COMMUNITY` fail with `INVALID_STORY_VISIBILITY`. Public stories can be viewed by any authenticated user; friends stories require a mutual accepted follow; Only Me stories are owner-only. Restricted story media is returned as a short-lived signed URL after story visibility is authorized.

---

## Authorization, pagination, errors, and media

All `/api/v1/community/**` routes require an authenticated bearer token. A successful response is wrapped as `{ "success":true,"message":"…","data":…,"timestamp":"…" }`. A failure uses the HTTP status plus `{ "success":false,"message":"…","errorCode":"…","timestamp":"…" }`; `data` is omitted when null. Common statuses are 400 validation/domain errors, 401 unauthenticated, 403 forbidden, 404 missing or intentionally hidden content, and 429 rate-limited.

Page endpoints accept zero-based `page` and `size` query parameters (default size is normally 20). The `data` value is `{ "content":[],"page":0,"size":20,"totalElements":0,"totalPages":0,"hasNext":false }`. A successful empty `content` is a real empty result. On request or response errors, retain any already displayed content and show an error/retry state.

Post visibility is enforced on reads, comments, and reactions: `PUBLIC` is available to authenticated users; `FRIENDS` requires a mutual accepted follow; `COMMUNITY` requires active membership; authors can see their own posts. Inaccessible posts are hidden as not found. Community visibility with no `communityId` has no eligible non-owner viewers. Anonymous forum discussions omit the author from the public response.

Upload media through the authenticated media flow: `POST /api/v1/media/presign` with `{ "contentType":"image/jpeg","sizeBytes":1234,"purpose":"POST","checksumSha256":"<64 lowercase hex chars>" }`, PUT the bytes directly to the returned `uploadUrl` with every `requiredHeaders` value, then `POST /api/v1/media/confirm` with the returned `mediaId`. Community requests should use confirmed `mediaId` values for post image/video fields (`imageMediaIds`, `videoMediaId`) and story `mediaId`; legacy public URLs remain supported where the request contract allows them.

Public media URLs are returned using the configured storage CDN base when present, with the storage endpoint as the configuration fallback. Preserve absolute CDN URLs in clients. A content service first checks the viewer's right to view a restricted post or story, then includes a short-lived presigned media URL in that authorized response. The standalone `GET /api/v1/media/{id}/url` endpoint mints a URL for public media or a private media URL for its owner only. Public object URLs are directly accessible to anyone who has the URL; do not attach private content to public media.

Community notifications use the `COMMUNITY` notification type. Their `referenceType` values identify the navigable resource: `POST` for post/comment activity, `STORY` for story reactions, `DISCUSSION` for forum moderation, and `EVENT` for event activity/reminders. `referenceId` is the corresponding resource UUID; consumers should route by the pair rather than parse notification text.

---

## Opportunities

**List/detail** `GET /community/opportunities?type=JOB` · `/{id}`. **Save** with the shared `POST /profile/saved` contract using `itemType:"OPPORTUNITY"`; unsave at `DELETE /profile/saved/OPPORTUNITY/{id}`.
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
Advanced chat realtime only: presence, typing, read receipts, delete/membership/pin broadcasts.
Chat REST/new-message realtime, Polls, and Stories have endpoints and can be wired.
