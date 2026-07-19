# Notifications Domain

> Source of truth: DD v5 sheet **Notifications**. Read [common.md](common.md) first.
> **Audience:** 🟦 Flutter · 🟩 Backend · 🟨 QA · 🟪 Designer

---

## 1. Overview

The Notification Center delivers in-app and push notifications across every domain, rendered from **bilingual templates** chosen by the user's `preferred_language`. It aggregates chat, event, productivity, finance, challenge, and security alerts.

**Status:** ⬜ **Not implemented** — tables (`notification_templates`, `notifications`) exist (migration 0012); no service/controller yet. **Known gap:** no `device_tokens` table for push delivery (needed when Firebase/push infra is chosen — flagged during the auth-provider swap).

---

## 2. Features (DD v5 Final Feature Scope)

Notification Center: **Chat Notification**, **Event Reminder**, **Productivity Reminder**, **Finance Reminder**, **Challenge Reminder**, **Security Alert**.

---

## 3. User stories

- As a user, I see a **notification center** listing my notifications, newest first, with read/unread state.
- I receive a **push** when someone interacts with me, an event/reminder is due, or a security event occurs — in **my language**.
- I can **mark notifications read** (individually or all).
- I can **toggle notifications** on/off in settings (`user_settings.notification_enabled`).

---

## 4. Functional requirements 🟩

1. A **template** (`notification_templates`) holds bilingual title/message + category; a `notifications` row is the **rendered** instance for a user (title/message/language snapshot + target).
2. Producing a notification: pick template by `template_key`, render with the receiver's `preferred_language`, store `target_type`/`target_id` for deep-linking.
3. **List** the user's notifications (paginated), unread count, **mark read** (`is_read`, `read_at`), mark-all-read.
4. **Push delivery** requires a device-token registry (future) + a push provider; delivery respects `user_settings.notification_enabled`.
5. Notifications are **produced by other domains** (Community, Events, Productivity, Finance, Entertainment, Auth) — this domain is the shared sink + center.

---

## 5. Screen requirements 🟦🟪

| Screen | Contents |
|---|---|
| Notification Center | grouped/tabbed list (All, by category), read/unread styling, timestamps, deep-link on tap |
| Notification Settings | master toggle + per-category toggles (see [profile-settings.md](profile-settings.md)) |

---

## 6. API requirements 🟩🟦

Base `/api/v1` (planned; BFF aggregation exists as a stub endpoint).

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/mobile/notifications` | Notification center aggregation (BFF; currently stub) |
| GET | `/users/me/notifications` | List user notifications (paginated) |
| POST | `/notifications/{id}/read` | Mark one read |
| POST | `/notifications/read-all` | Mark all read |
| (future) | device-token register/unregister | Push registration |

---

## 7. Database references (DD v5 — exact) 🟩🟨

- **`notification_templates`**: template_id PK; template_key varchar(120) **UNIQUE**; **title_en/km, message_en/km**; category; created_at.
- **`notifications`**: notification_id PK; user_id FK (receiver); template_id FK; title (rendered); message (rendered); language (rendered KHMER/ENGLISH); category; target_type; target_id; is_read; created_at; read_at.

**Relationships:** `notifications.user_id → users`, `notifications.template_id → notification_templates`. **Constraint:** `notification_templates.template_key` UNIQUE.

**Seed (DD v5 checklist):** 10 templates, 20 notifications — Khmer/English titles & messages.

---

## 8. Business rules 🟩🟨

- Rendered `language` is snapshotted at creation from the receiver's `preferred_language`.
- `is_read`/`read_at` track per-notification read state (not chat — chat uses `message_reads`).
- Respect `user_settings.notification_enabled` (and per-category prefs) before delivering push.
- `target_type`/`target_id` enable deep links (e.g., open the event, post, or lesson).

---

## 9. Notification categories 🟨

| Category | Source domain | Trigger |
|---|---|---|
| `CHAT` | Community (chat ⏸) | new message |
| `EVENT` | Community | event reminder before `date_time`, RSVP updates |
| `PRODUCTIVITY` | Lifestyle | habit/task reminders |
| `FINANCE` | Finance | budget limit, saving-goal deadline |
| `CHALLENGE` | Entertainment | new challenge, claim available |
| `SECURITY` | Auth | new-device login, password changed |
| `COMMUNITY` | Community | like/comment/follow/RSVP/mention |

---

## 10. Localization 🟦🟩

- Templates bilingual (`title_en/km`, `message_en/km`); backend renders by `users.preferred_language`.
- Default KHMER; EN fallback when KM missing.

---

## 11. Permissions 🟩

- A user sees only their own notifications (owner-scoped).
- Templates are system/admin-managed.

---

## 12. Future scope

- **Push infrastructure**: `device_tokens` table + FCM/APNs (or provider) integration; delivery workers.
- Per-category preferences; notification grouping/snooze; scheduled reminders (server-side cron).
