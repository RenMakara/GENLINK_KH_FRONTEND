# GenLink KH — Frontend Handoff

## What it is
Flutter mobile app for **GenLink KH**, a Khmer-first Gen Z super-app. Talks to a Spring Boot backend. Owned area is **auth, profile, settings, splash/onboarding, and home** — those are complete; other feature modules (community, finance, productivity, growth, notification) are scaffolded to varying degrees.

**Location:** `frontend/` (the Flutter app lives here, not at repo root).

## Stack
- **Flutter** (Dart SDK `^3.12.2`), **GetX 4.7.2** for state / routing / DI / i18n
- **Dio 5.4** (HTTP, with auth interceptor + token refresh), **flutter_secure_storage 10.3.1**
- **google_sign_in 7.2.0**, **device_info_plus 13.2.0**, **cupertino_icons**
- Dev: **flutter_lints 6**, **mocktail 1.0.3**
- Status: **84 tests passing, 0 analyzer errors/warnings**, ~14 pre-existing info-level lints (mostly `prefer_initializing_formals`)

## Architecture & conventions
- **Clean-ish feature-first layout.** Each feature: `presentation/{screens,controllers,bindings,widgets}`, `domain/{entities,repositories}`, `data/{models,datasources,repositories}`.
- **GetX everywhere** — `provider` was removed; do not reintroduce it. Controllers extend `GetxController`; screens use `GetView<T>` or plain `StatelessWidget` + `Get.find`.
- **Bindings register dependencies per route.** Note: a screen that never calls `Get.find` on its controller must use eager `Get.put`, not `lazyPut`, or the controller never constructs (this bit us on splash).
- **Design system** in `lib/design_system/` — tokens (`colors`, `typography`, `spacing`, `radius`, `shadows`) + `widgets/` (AppButton, OtpInput, AppAvatar, etc.). Buttons are pill-shaped; inputs follow Figma specs. Don't hardcode colors/sizes — use tokens.
- **`AppButton`** has a `loading` param (swaps label for spinner, disables tap).
- **Startup** is in `lib/app/bootstrap.dart` -> `runApp(GenLinkKhApp)`. `bootstrap()` MUST always reach `runApp` — preloads are wrapped in try/catch + 3s timeout, and `FlutterError.onError`/`PlatformDispatcher.onError` log startup failures. (A prior unguarded `ThemeController.load()` throw caused a permanent black screen with no logs.)
- **`GenLinkKhApp`** wraps `GetMaterialApp` in `Obx` reading theme mode + language; theme is per-language (`AppTheme.lightFor(languageCode)`).

## Localization (important gotcha)
- Default **English**; auto-**Khmer** if the device is Khmer; follows device live until the user makes an explicit choice.
- `LocalizationService` owns this. **Changing language at runtime requires `Get.updateLocale()`** — `.tr` reads `Get.locale`, and `GetMaterialApp` resolves `Get.locale ?? locale`, so rebuilding with a new `locale:` alone does nothing. The call is guarded (`Get.key.currentState != null`) so it doesn't throw pre-app/in tests. Invoked from `setLanguage`, `syncFromAccount`, `didChangeLocales`.
- Translations are GetX maps (`AppTranslations`), not `.arb` — `flutter_localizations` is NOT a dependency, so Material's own widgets (date picker) won't render Khmer.

## Backend integration
- Base URL in `lib/core/config/app_config.dart` -> `http://165.22.101.156`, port **8888**. `googleServerClientId` = the **Web** OAuth client.
- Network stack in `lib/core/network/` — `AuthInterceptor` refreshes tokens via a shared `Completer` (handles concurrent 401s), replays through the configured Dio client. `DioException` -> `AppError` via `AppError.fromDio` + `guardDio()`.
- Tokens in `flutter_secure_storage`. Non-secret prefs (theme, language, onboarding-seen) also live there via `LocalStorage` (could be moved to `shared_preferences` later — noted, not done).

## Key screens (owned area, done)
- **Splash** -> resolves session, routes to home / language-select / login. Min 600ms display.
- **Onboarding**: language select -> slides.
- **Auth**: login, register, verify OTP (registration), forgot-password -> reset OTP -> reset password (split into separate screens). 3-step profile setup after registration (skippable). Reset-OTP shows a 1s loading beat and locks the input before redirecting.
- **Profile / Edit profile / Settings** (hub + language/appearance/privacy/account sub-screens) — built to the design sheet.
- **Home**: single `GET /mobile/home` dashboard.

## Standing policy: do NOT fabricate data
Cards/stats with no backend (streaks, unread counts, focus minutes, career path) are **deliberately omitted or shown as empty states**, never filled with fake numbers. The reasoning is documented in code comments. Keep this.

## Open items / not done
- Khmer strings (~150) need native-speaker review.
- `assets/fonts/` is empty — Sora/Kantumruy fall back to system fonts.
- Other feature modules (community/finance/productivity/growth/notification) are incomplete.
- Golden tests exist for auth/home/profile/settings; keep them updated on UI changes.

## Working preferences
- Commit style: `feat(scope): msg` / `fix(scope): msg`, short subject, no long body, **no `Co-Authored-By` trailer**.
- Docs & Postman collection: update but **don't commit** unless asked.
- Don't commit/push unless explicitly told.
