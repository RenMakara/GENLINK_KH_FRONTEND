# Google Sign-In setup

Everything except the plugin is already wired. This document covers the
three things that remain: the Google Cloud Console clients, the plugin, and
the one file that swaps the stub for the real implementation.

## What already works

| Piece | Status |
|---|---|
| `POST /api/v1/auth/google` | ✅ built |
| `GoogleTokenVerifier` (signature, audience, issuer, expiry, `email_verified`) | ✅ built |
| Account auto-creation on first Google login | ✅ built |
| `GoogleSignInButton` on Login + Register | ✅ built |
| `AuthController.signInWithGoogle()` | ✅ built |
| `GoogleAuthService` seam | ✅ built (stub impl) |
| `google_sign_in` plugin + OAuth clients | ❌ **you do this** |

Google login is also **registration**: `AuthServiceImpl.googleLogin` creates
the user when the email is unknown — `ACTIVE`, `emailVerified = true`, no OTP,
with a generated username. Existing email/password accounts are linked by
email on first Google sign-in.

## This project's OAuth clients

Both live in Google Cloud project `456895735825`. Their ids differ only
after the dash, so check the suffix, not the prefix.

| Type | Client id | Used where |
|---|---|---|
| Web | `456895735825-0jfa3vilbnhsv4hs780822s993f35k0h.apps.googleusercontent.com` | `AppConfig.googleServerClientId` **and** backend `GOOGLE_CLIENT_ID` |
| Android (debug) | `456895735825-g38h2i4tqp0mqc3ubduoc2sei5nklcfd.apps.googleusercontent.com` | **nowhere** — matched by package name + SHA-1 |

Client ids are not secrets; they ship inside the APK. The Web client's
*secret* is unused by this flow and must never be committed.

## 1. Google Cloud Console

Create **two** OAuth clients in the same project
(APIs & Services → Credentials → Create credentials → OAuth client ID).

### a. Web application client — this is the important one

Name it something like `GenLink KH backend`. No redirect URIs needed.

Its client id is used in **two** places, and they must match:

- Flutter: passed as `serverClientId`
- Backend: `GOOGLE_CLIENT_ID`

> **The single most common mistake.** On Android the ID token's `aud` claim
> is the **Web** client id, not the Android one. `GoogleTokenVerifier` checks
> `aud` against `app.google.client-id`. Put the Android client id there and
> every request fails with `AUTH_INVALID_GOOGLE_TOKEN`, even though sign-in
> on the device looked fine.

### b. Android client

Required for the device-side sign-in to succeed. It is never referenced in
code — Google matches it by package name + signing certificate.

```
Package name:  kh.edu.acleda.genlink.genlink_frontend
SHA-1 (debug): B1:11:7A:53:C4:CA:0B:77:B4:4A:28:4B:5A:9C:D6:0C:19:2A:54:36
```

Regenerate that fingerprint any time with:

```bash
keytool -list -v -alias androiddebugkey \
  -keystore ~/.android/debug.keystore -storepass android -keypass android
```

Add a **second** Android client with your release keystore's SHA-1 before
shipping, or Google sign-in works in debug and fails in release.

### c. OAuth consent screen

Set it to **External**, fill in app name and support email, and add your own
Google account under **Test users** while it is unpublished. Without that,
sign-in fails with `access_denied` for everyone but the project owner.

Scopes: `email` and `profile` are enough — the backend only reads `sub`,
`email`, `name` and `picture`.

## 2. Backend config

Set `GOOGLE_CLIENT_ID` to the **Web** client id from step 1a, in the
IntelliJ run configuration (Run → Edit Configurations → Environment
variables) — that is where the running app reads it from, not `.env.example`.

`GoogleTokenVerifier` accepts a comma-separated list, so iOS can be added
later without breaking Android:

```
GOOGLE_CLIENT_ID=<web-client-id>,<ios-client-id>
```

## 3. Flutter

### Install the plugin

```bash
cd frontend
flutter pub add google_sign_in
```

### Replace the stub

Create `lib/features/auth/data/services/google_auth_service_impl.dart`.
Check the API against the version `pub add` actually resolved — the plugin
changed shape significantly in 7.0, and the two are not interchangeable.

**google_sign_in 7.x**

```dart
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_error.dart';
import '../../domain/services/google_auth_service.dart';

class GoogleAuthServiceImpl implements GoogleAuthService {
  GoogleAuthServiceImpl();

  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: AppConfig.googleServerClientId,
    );
    _initialized = true;
  }

  @override
  Future<String?> signIn() async {
    if (!AppConfig.isGoogleSignInConfigured) {
      throw const AppError(
        message: 'Google Sign-In is not configured in this build yet.',
        errorCode: UnconfiguredGoogleAuthService.errorCode,
      );
    }
    try {
      await _ensureInitialized();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AppError(
          message: 'Google did not return an ID token.',
          errorCode: 'GOOGLE_NO_ID_TOKEN',
        );
      }
      return idToken;
    } on GoogleSignInException catch (e) {
      // A cancel is not an error — return null so the UI stays put.
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw AppError(
        message: e.description ?? 'Google Sign-In failed.',
        errorCode: 'GOOGLE_SIGN_IN_FAILED',
      );
    }
  }

  @override
  Future<void> signOut() async {
    if (!_initialized) return;
    await GoogleSignIn.instance.signOut();
  }
}
```

**google_sign_in 6.x**

```dart
final _googleSignIn = GoogleSignIn(
  serverClientId: AppConfig.googleServerClientId,
  scopes: const ['email', 'profile'],
);

@override
Future<String?> signIn() async {
  final account = await _googleSignIn.signIn();   // null when cancelled
  if (account == null) return null;
  final auth = await account.authentication;
  return auth.idToken;
}

@override
Future<void> signOut() => _googleSignIn.signOut();
```

### Register it

In `lib/features/auth/presentation/bindings/auth_binding.dart`, pass the
real implementation to the controller:

```dart
Get.put<AuthController>(
  AuthController(
    authRepository: authRepository,
    secureStorage: storage,
    localization: localization,
    googleAuthService: GoogleAuthServiceImpl(),   // <- was the default stub
  ),
  permanent: true,
);
```

Nothing else changes — the button, loading state, error banner, session
persistence and navigation are already wired.

### Run with the client id

```bash
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:8888 \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>.apps.googleusercontent.com
```

Put this in `.vscode/launch.json` or the Android Studio run config so you
do not retype it. Without the define, `AppConfig.isGoogleSignInConfigured`
is false and the button reports that the build is unconfigured rather than
failing at Google.

## Troubleshooting

| Symptom | Cause |
|---|---|
| `AUTH_INVALID_GOOGLE_TOKEN` from the backend | `GOOGLE_CLIENT_ID` is not the **Web** client id, or does not match `serverClientId` |
| `idToken` is null, `accessToken` is fine | `serverClientId` not passed — without it Google returns no ID token |
| `ApiException: 10` (DEVELOPER_ERROR) on device | SHA-1 or package name does not match the Android OAuth client |
| Works in debug, fails in release | Release keystore SHA-1 not registered |
| `access_denied` | Consent screen unpublished and the account is not a test user |
| `AUTH_GOOGLE_EMAIL_UNVERIFIED` | The Google account has no verified email |

## iOS, when you get there

Add an **iOS** OAuth client, put `GoogleService-Info.plist` in
`ios/Runner/`, add the reversed client id as a URL scheme in `Info.plist`,
and append the iOS client id to the backend's comma-separated
`GOOGLE_CLIENT_ID`.
