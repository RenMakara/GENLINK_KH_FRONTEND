# GenLink KH — Flutter Frontend Implementation Guide

> **For the Flutter team.** How to wire the app to the backend: API contract, Dart models, and screen → endpoint maps.
> Pair this with the spec docs in [`docs/domains/`](../domains). **Read this file first**, then your domain file.

**Ownership (per team assignment):** Auth, Profile, and Settings screens are owned by the doc author; the other domain files are for the teammate implementing Finance, Productivity (Lifestyle), Entertainment, Community, and the Mobile dashboards.

**Implementation status:** ✅ live · ⏸ deferred (endpoints not built).

| Domain file | Status |
|---|---|
| [community.md](community.md) | ✅ (chat/polls/stories ⏸) |
| [finance.md](finance.md) | ✅ |
| [lifestyle.md](lifestyle.md) (Productivity) | ✅ |
| [entertainment.md](entertainment.md) | ✅ (multiplayer/friends ⏸) |
| [mobile-bff.md](mobile-bff.md) | ✅ home/finance/productivity/profile · ⏸ events/notifications |
| [auth.md](auth.md) | ✅ (my screens) |
| [profile-settings.md](profile-settings.md) | ✅ (my screens) |
| Notifications | ⬜ backend not built — do not wire yet |

---

## 1. Base setup

- **Base URL:** `https://<host>/api/v1`
- **Suggested packages:** `dio` (HTTP), `flutter_secure_storage` (tokens), `intl`/`flutter_localizations` (i18n). Models below are plain classes with `fromJson` (no codegen assumed; freezed/json_serializable is fine if you prefer).
- **Every response is wrapped** in an envelope — unwrap once, centrally (see §3).
- **Every protected call** sends `Authorization: Bearer <accessToken>` and `Accept-Language: km|en`.

---

## 2. Response envelopes (unwrap these everywhere)

Success:
```json
{ "success": true, "message": "Wallet retrieved", "data": { }, "timestamp": "2026-07-19T10:00:00Z" }
```
Error:
```json
{ "success": false, "errorCode": "DEMO_WALLET_INSUFFICIENT_BALANCE" }
```
Paginated `data` (list endpoints):
```json
{ "content": [ ], "page": 0, "size": 20, "totalElements": 42, "totalPages": 3, "hasNext": true }
```

### Dart: envelope + page
```dart
class ApiResponse<T> {
  final bool success;
  final String? message;
  final String? errorCode;
  final T? data;
  ApiResponse({required this.success, this.message, this.errorCode, this.data});

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic)? parse) {
    return ApiResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      errorCode: json['errorCode'] as String?,
      data: (json['data'] != null && parse != null) ? parse(json['data']) : null,
    );
  }
}

class PageResponse<T> {
  final List<T> content;
  final int page, size, totalPages;
  final int totalElements;
  final bool hasNext;
  PageResponse({required this.content, required this.page, required this.size,
    required this.totalElements, required this.totalPages, required this.hasNext});

  factory PageResponse.fromJson(Map<String, dynamic> json, T Function(dynamic) parse) {
    return PageResponse(
      content: (json['content'] as List).map(parse).toList(),
      page: json['page'], size: json['size'],
      totalElements: json['totalElements'], totalPages: json['totalPages'],
      hasNext: json['hasNext'],
    );
  }
}
```

---

## 3. ApiClient (Dio) — auth, language, unwrap, refresh

```dart
class ApiClient {
  final Dio _dio;
  final TokenStore _tokens;          // your secure-storage wrapper
  final String Function() _lang;     // returns 'km' or 'en'

  ApiClient(this._dio, this._tokens, this._lang) {
    _dio.options.baseUrl = 'https://<host>/api/v1';
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (opts, h) async {
        final t = await _tokens.access();
        if (t != null) opts.headers['Authorization'] = 'Bearer $t';
        opts.headers['Accept-Language'] = _lang();
        h.next(opts);
      },
      onError: (e, h) async {
        // 401 -> try refresh once, then retry
        if (e.response?.statusCode == 401 && await _tokens.refresh() != null) {
          if (await _refresh()) return h.resolve(await _retry(e.requestOptions));
        }
        h.next(e);
      },
    ));
  }

  // Unwrap the success envelope; throw ApiException on failure.
  Future<T> get<T>(String path, T Function(dynamic) parse, {Map<String, dynamic>? query}) async {
    final res = await _dio.get(path, queryParameters: query);
    final api = ApiResponse.fromJson(res.data, parse);
    if (!api.success) throw ApiException(api.errorCode ?? 'UNKNOWN');
    return api.data as T;
  }
  // post/put/delete follow the same unwrap pattern.
}

class ApiException implements Exception { final String errorCode; ApiException(this.errorCode); }
```

**Token refresh:** call `POST /auth/refresh-token` with the stored refresh token; on success store the new access token and retry the failed request; on failure, log the user out.

---

## 4. Error handling (map errorCode → localized message)

Backend returns a **stable `errorCode`**; never show raw backend text. Keep a KM/EN map in the app:

```dart
const errorMessages = {
  'VALIDATION_ERROR': {'en': 'Please check your input.', 'km': 'សូមពិនិត្យ...'},
  'NOT_FOUND': {'en': 'Not found.', 'km': '...'},
  'DEMO_WALLET_INSUFFICIENT_BALANCE': {'en': 'Not enough balance.', 'km': '...'},
  'DEMO_WALLET_NOT_FOUND': {'en': 'Open your wallet first.', 'km': '...'},
  'BUDGET_ALREADY_EXISTS': {'en': 'A budget already exists for this month.', 'km': '...'},
  'GOAL_CANCELLED': {'en': 'This goal is cancelled.', 'km': '...'},
  'NO_QUIZ': {'en': 'No quiz for this lesson.', 'km': '...'},
  'NO_QUESTIONS': {'en': 'This quiz has no questions.', 'km': '...'},
  'NOT_IMPLEMENTED': {'en': 'Coming soon.', 'km': '...'},
  // ... plus generic UNAUTHORIZED / FORBIDDEN
};
```
Each domain file lists the `errorCode`s that endpoint can return.

---

## 5. Localization

- **UI labels:** Flutter `en.json` / `km.json` — the backend does **not** send UI strings.
- **System content** (lessons, motivation, quizzes, challenges, badges, notifications) is **already localized** by the backend based on your `Accept-Language` header — you receive a single `title`/`content`/`name` string, not `_en`/`_km`. Send `km` or `en`.
- **User content** (posts, comments, bio, event descriptions) comes back **as written** — display verbatim.
- Default language **KHMER**; store the user's choice and set it as `Accept-Language`.

---

## 6. Conventions for models

- JSON keys are **camelCase** (e.g. `walletId`, `likeCount`, `progressPercentage`). Money is a JSON number → parse as `num`/`double` (backend uses BigDecimal, 2 decimals).
- IDs are UUID **strings**. Timestamps are ISO-8601 **strings** → `DateTime.parse`.
- Enums arrive as UPPER_SNAKE strings → map to Dart enums (values listed per domain; full list in [common.md](../domains/common.md)).
- Nullable fields: dashboards/cards degrade to `null`/empty for new users — always null-check.

```dart
enum BudgetStatus { safe, warning, limitReached }
BudgetStatus budgetStatusOf(String s) => {
  'SAFE': BudgetStatus.safe, 'WARNING': BudgetStatus.warning, 'LIMIT_REACHED': BudgetStatus.limitReached
}[s]!;
```

---

## 7. Auth token lifecycle (all screens depend on it)

1. `POST /auth/login` or `/auth/google` → `{ accessToken, refreshToken, expiresIn, user }`. Store both tokens securely.
2. Attach `Bearer accessToken` on every call (§3).
3. On `401`, refresh once via `/auth/refresh-token`; retry; else route to login.
4. `POST /auth/logout` clears tokens + revokes server-side.

See [auth.md](auth.md) for full request/response shapes.

---

## 8. How to read a domain file

Each domain file gives, per screen:
- **Screen → endpoint(s)** it calls,
- **Request** JSON (for POST/PUT),
- **Response** JSON (the `data` payload, already unwrapped),
- a **Dart model** mirroring it,
- **errorCodes** to handle.

Start with the screens list at the top, then wire top-to-bottom.