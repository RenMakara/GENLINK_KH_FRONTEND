# Community Domain

> Source of truth: DD v5 sheet **Community** + `backend/docs/COMMUNITY_PLAN.md`. Read [common.md](common.md) first.
> **Audience:** 🟦 Flutter · 🟩 Backend · 🟨 QA · 🟪 Designer

---

## 1. Overview

Community is the social/engagement layer: a **feed** (posts, likes, comments, hashtags), **communities & follows**, an **events** system with RSVP and simulated paid entry, a **forum** (discussions, reactions, reports, anonymity), and an **opportunities** hub (jobs, scholarships, internships, hackathons). It also feeds Home's Recommended Communities, Upcoming Event, and Mini Feed cards.

**Status legend:** ✅ implemented · ⏸ deferred.
- ✅ Feed (posts/comments/reactions/hashtags/saved), Communities + follows, Events + RSVP (+ paid RSVP via demo wallet), Forum (discussions/reactions/reports/anonymous), Opportunities + saved.
- ⏸ **Chat & Communication** (private/group chat), **Polls**, **Stories** — deferred (chat needs a real-time/WebSocket layer). Tables exist; no service/endpoints yet.

---

## 2. Features (DD v5 Final Feature Scope)

- **Social Feed:** Home Feed, Text/Image/Poll Post, Like/Comment/Share/Save, Trending Posts, Hashtags, Recommended Communities, Story Feature ⏸.
- **Chat & Communication ⏸:** Private Chat, Group Chat, Text/Image/Voice Message, Read Status, Online Status, Reply Message, Pinned Message.
- **Community Forum:** Create Discussion, Comment/Reply, Category System, Like/Reaction, Anonymous Discussion, Moderation Report.
- **Events & Activities:** Create Event, Join/RSVP, Event Detail, Location/Map, Reminder, Event Categories, QR Attendance Check-in.
- **Career & Networking:** Public Profile, Skill Showcase, Career Goals, Internship Hub, Scholarship Posts, Hackathon Opportunities, Job/Volunteer Opportunities, Mentor Matching.

---

## 3. User stories

- As a user, I can **post** text/image (or a poll ⏸) and see a **feed** that respects visibility.
- I can **like, comment, save, and share** posts and add **hashtags**; I can browse a hashtag.
- I can **join/follow communities** and get **recommended communities** I haven't joined.
- I can **create an event**, and others can **RSVP** (JOINED/INTERESTED); paid events debit my demo wallet; I earn XP for attending.
- I can start a **forum discussion** (optionally **anonymous**), react to it, and **report** abuse.
- I can browse **opportunities** (jobs, scholarships, internships, hackathons) and **save** them.
- ⏸ I can chat privately or in groups with read receipts and replies.

---

## 4. Functional requirements 🟩

1. **Feed** lists non-deleted posts by visibility (`PUBLIC` public; `COMMUNITY`/`FRIENDS` scoped). `LEFT JOIN FETCH` author so the card can render name/avatar even for nullable authors.
2. **Reactions/saves** are idempotent via `UNIQUE(post_id,user_id)`; counters updated atomically.
3. **Hashtags** parsed from post text (`[\p{L}\p{M}\p{N}_]`, Khmer-safe); `usage_count` maintained without inflation on edit (decrement old links, then re-link).
4. **Communities:** join/leave (idempotent), `member_count` maintained; discover excludes already-joined.
5. **Events:** create/list/detail; **RSVP** unique per (event,user); **capacity race-safe** via conditional `UPDATE attendee_count = attendee_count + 1 WHERE attendee_count < attendee_limit`; cancel releases the seat. Paid RSVP debits demo wallet (`EVENT_PAYMENT`); failure rolls the seat back in one transaction. RSVP awards XP once (`EVENT_RSVP`, +10).
6. **Forum:** discussions with `is_anonymous`; reactions unique per (discussion,user); reports unique per (discussion,user) — one report = one flag; counters maintained.
7. **Opportunities:** browse (filter by type); active-only queries keep dates in comparisons (avoid `:date IS NULL`); save unique per (opportunity,user).
8. Owner-scoped edits/deletes; soft delete via `deleted_at`.

---

## 5. Screen requirements 🟦🟪

| Screen | Contents |
|---|---|
| Home Feed | post cards (author, text, image, like/comment/save/share counts), infinite scroll |
| Create Post | text, image, hashtags, visibility; (poll ⏸) |
| Post Detail | full content, comment list, reply input, like/save |
| Communities | joined + **recommended** (excludes joined); join/leave |
| Community Detail | members, community feed |
| Events List / Detail | cover, date/time, location + **map**, attendee count, RSVP button, (paid → wallet), QR check-in |
| Forum | discussion list by **category**, create (with **anonymous** toggle), reactions, **report** |
| Opportunities | list by type (job/scholarship/internship/hackathon/volunteer), detail, apply link, **save** |
| Saved | saved posts + saved opportunities |
| ⏸ Chat List / Chat Screen / New Group | rooms, messages, read status, reply, pin |

---

## 6. API requirements 🟩🟦

Base `/api/v1/community`. Lists paginated. Selected endpoints (implemented):

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/community/feed` | Visibility-aware feed |
| POST/GET/PUT/DELETE | `/community/posts`, `/posts/{id}` | Post CRUD |
| POST/DELETE | `/community/posts/{id}/like` | Toggle like |
| POST/DELETE | `/community/posts/{id}/save` | Toggle save |
| GET/POST | `/community/posts/{id}/comments` | Comments + replies |
| GET | `/community/hashtags/{tag}/posts` | Posts by hashtag |
| GET/POST | `/community/communities` (+ `/{id}/join`, `/leave`, `/discover`) | Communities & follows |
| GET/POST | `/community/events`, `/events/{id}` | Event CRUD/detail |
| POST | `/community/events/{id}/rsvp` (+ cancel) | RSVP (JOINED/INTERESTED), paid, QR check-in |
| GET/POST | `/community/forum/discussions` (+ `/{id}/react`, `/report`, comments) | Forum |
| GET | `/community/opportunities` (+ `/{id}`, `/{id}/save`) | Opportunities |
| ⏸ | `/community/chats`, `/chats/group`, `/chats/{room}/messages` | Chat (deferred) |

**Domain errors:** `DEMO_WALLET_NOT_FOUND`, `DEMO_WALLET_INSUFFICIENT_BALANCE` (paid RSVP), event full (RSVP rows-affected = 0).

---

## 7. Database references (DD v5 — exact) 🟩🟨

**Feed:** `posts` (post_id PK; user_id FK; content_text; language; image_url; post_type TEXT/IMAGE/POLL/ANNOUNCEMENT; visibility PUBLIC/FRIENDS/COMMUNITY; like_count; comment_count; share_count; save_count; audit+deleted_at). `post_comments` (comment_id PK; post_id FK; user_id FK; content; language; parent_comment_id self-FK; like_count; audit). `post_reactions` (**UNIQUE(post_id,user_id)**; reaction_type). `saved_posts` (**UNIQUE(post_id,user_id)**; saved_at).

**Polls ⏸:** `polls` (poll_id PK; post_id FK; question). `poll_options` (option_id PK; poll_id FK; option_text; vote_count). `poll_votes` (**UNIQUE(poll_id,user_id)**; option_id FK).

**Chat ⏸:** `chat_rooms` (chat_type PRIVATE/GROUP; name; created_by). `chat_room_members` (**UNIQUE(chat_room_id,user_id)**; role; status ACTIVE/LEFT/REMOVED; muted_until; joined_at/left_at). `chat_messages` (message_type TEXT/IMAGE/VOICE/SYSTEM; content; media_url; reply_to_message_id self-FK; audit+deleted_at). `message_reads` (**UNIQUE(message_id,user_id)**; read_at — group reads use this, not `is_read`).

**Forum:** `forum_discussions` (discussion_id PK; user_id FK; title; content; language; category; is_anonymous; reaction_count; comment_count; report_count; audit+deleted_at). `discussion_comments` (discussion_id FK; user_id FK; content; language; parent_comment_id self-FK).

**Events:** `events` (event_id PK; organizer_id FK; title; description; language; category; cover_image_url; date_time; location_name; latitude/longitude decimal(10,7); attendee_limit; attendee_count; status DRAFT/PUBLISHED/CANCELLED/COMPLETED). `event_rsvps` (**UNIQUE(event_id,user_id)**; status JOINED/INTERESTED/CANCELLED/ATTENDED; checked_in; qr_code).

**Opportunities:** `opportunities` (opportunity_id PK; title; organization; type; description; language; deadline; location; apply_link). `saved_opportunities` (**UNIQUE(opportunity_id,user_id)**).

> **Implementation additions (ERD v5.1):** `communities`, `community_members` (UNIQUE(community_id,user_id)), `follows`, `hashtags` (usage_count), `post_hashtags`, `forum_reactions` (UNIQUE(discussion_id,user_id)), `discussion_reports` (UNIQUE(discussion_id,user_id)). Events gained pricing columns (is_paid, price).

**Relationships/constraints:** all `user_id`/`organizer_id`/`sender_id` → `users`; unique constraints on reactions/saves/votes/RSVPs/memberships/reads as listed.

---

## 8. Business rules 🟩🟨

- One like/save/vote/RSVP/membership/report per user per target (unique constraints).
- Counters (`like_count`, `comment_count`, `attendee_count`, `usage_count`, `member_count`, `reaction_count`, `report_count`) maintained transactionally.
- RSVP capacity is race-safe; paid RSVP is atomic with the wallet debit.
- Anonymous discussions hide author identity in responses but retain `user_id` for moderation.
- Soft delete for posts/comments/discussions/messages.
- Post soft-delete should also decrement hashtag `usage_count` *(known follow-up)*.

---

## 9. Notifications 🟨

- **All community actions → push** (like/comment/follow/RSVP/mention) — category `COMMUNITY`.
- **Chat messages → real-time notification** ⏸ (with chat).
- **Event reminder** before `date_time` — category `EVENT`.

---

## 10. Localization 🟦🟩

- Posts, comments, discussions, event descriptions, opportunities: **user content stored as written** + `language` enum; never auto-translated.
- Category labels/UI: Flutter localization.

---

## 11. Permissions 🟩

- Authenticated for all actions. Author-only edit/delete of own posts/comments/discussions/events.
- Moderation (hide/remove reported content) → `ADMIN`.
- Visibility gating (`PUBLIC`/`FRIENDS`/`COMMUNITY`) governs feed reads.

---

## 12. Future scope

- **Chat** (WebSocket/STOMP: rooms, members, messages, read receipts, presence, reply, pin).
- **Polls** and **Stories**.
- Mentor matching, richer Career/Networking; trending ranking; map integration; QR attendance UI.
