# GenLink KH — Mobile Application

> **Connect. Grow. Thrive.**  
> The official cross-platform mobile client for **GenLink KH** — an intergenerational community, personal growth, and youth empowerment platform tailored for Cambodia.

Built with **Flutter** and **GetX**, GenLink KH brings together practical real-world learning, community interaction, financial literacy, productivity habits, gamified challenges, and opportunity discovery into a single, cohesive, bilingual mobile experience.

---

## 📋 Table of Contents

- [About GenLink KH](#-about-genlink-kh)
  - [Core Features & Modules](#core-features--modules)
- [Technology Stack](#-technology-stack)
- [Architecture & Design System](#-architecture--design-system)
  - [Clean Feature-First Architecture](#clean-feature-first-architecture)
  - [Bilingual Design System & Typography](#bilingual-design-system--typography)
- [Project Structure](#-project-structure)
- [Getting Started & Local Setup](#-getting-started--local-setup)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Environment Configuration](#environment-configuration)
  - [Running the App](#running-the-app)
  - [Firebase & Google Sign-In Setup](#firebase--google-sign-in-setup)
- [Testing & Quality Assurance](#-testing--quality-assurance)
- [Build & Release](#-build--release)
- [Development Team](#-development-team)

---

## 🌟 About GenLink KH

**GenLink KH** bridges the generational divide in Cambodia by connecting youth, students, and seniors through mentorship, cultural preservation, skill exchange, and shared experiences.

The mobile app serves as the daily digital companion for users to:
- **Learn & Upskill**: Engage with micro-lessons, interactive quizzes, and daily challenges.
- **Engage in Community**: Participate in discussions, discover stories, share knowledge, and connect with like-minded peers and mentors.
- **Build Financial Literacy**: Learn practical budgeting habits, track personal milestones, and gain financial confidence.
- **Track Growth & Habits**: Boost daily focus with productivity timers, habit tracking, and progress metrics.
- **Stay Motivated**: Earn XP, collect achievement badges, build daily streaks, and climb community leaderboards.

### Core Features & Modules

| Module | Location | Description |
|---|---|---|
| **Splash & Onboarding** | `lib/features/splash`, `onboarding` | Session resolution, seamless animated splash, bilingual language selection (Khmer & English), and feature walk-through slides. |
| **Authentication** | `lib/features/auth` | Email/phone sign-in & registration, OTP verification, Google OAuth (Google Sign-In), password reset, and a 3-step skippable profile builder. |
| **Home Dashboard** | `lib/features/home` | Unified feed featuring daily spotlights, motivational quotes, recommended challenges, and quick navigation doorways. |
| **Community & Social** | `lib/features/community` | Discussion forums, categorized post feeds, comment threads, member roles, likes, post creation with media, and deep-linkable stories. |
| **Chat & Messaging** | `lib/features/chat` | Real-time 1-on-1 messaging and community chat channels. |
| **Learning & Quizzes** | `lib/features/quiz`, `challenge` | Interactive multiple-choice quizzes, daily knowledge checks, and step-by-step challenges. |
| **Gamification & XP** | `lib/features/levelup`, `leaderboard` | Real-time level-up celebrations, XP rewards, achievement badges, streak tracking, and peer leaderboards. |
| **Finance & Budgeting** | `lib/features/finance` | Financial literacy guides, budget tracking, and healthy money habits. |
| **Productivity** | `lib/features/productivity` | Daily habit tracking, focus timer, and personal goal management. |
| **Short Content** | `lib/features/short_content` | Vertical video reels and preview playback for educational content. |
| **Profile & Settings** | `lib/features/profile`, `settings` | User profile editing, cover photos, avatars, live language switcher, appearance (theme mode), notification preferences, and account security. |
| **Notifications** | `lib/features/notification` | Push notifications via Firebase Cloud Messaging (FCM) and in-app alert history. |

---

## 🛠 Technology Stack

### Core Framework & Runtime
- **Framework**: [Flutter](https://flutter.dev/) (Channel stable, Dart SDK `^3.12.2`)
- **State Management & Routing**: [GetX 4.7.2](https://pub.dev/packages/get)
  - Reactive state management (`Rx`, `Obx`, `GetxController`)
  - Declarative route management (`GetPage`, `GetMaterialApp`)
  - Dependency injection (`Bindings`, `Get.put`, `Get.find`, `Get.lazyPut`)
  - Integrated localization management (`Get.updateLocale`)

### Networking & Data Layer
- **HTTP Client**: [Dio 5.4.0](https://pub.dev/packages/dio)
  - Centralized `AuthInterceptor` with transparent token refresh via asynchronous lock
  - Custom error mapper (`AppError.fromDio`)
- **Secure Storage**: [flutter_secure_storage 11.0.0](https://pub.dev/packages/flutter_secure_storage) for tokens and credentials
- **Deep Linking**: [app_links 7.2.1](https://pub.dev/packages/app_links) for community and story links

### Authentication & Cloud Services
- **Google Sign-In**: [google_sign_in 7.2.0](https://pub.dev/packages/google_sign_in)
- **Push Notifications**:
  - [firebase_core 4.14.0](https://pub.dev/packages/firebase_core)
  - [firebase_messaging 16.6.0](https://pub.dev/packages/firebase_messaging)
  - [flutter_local_notifications 22.3.0](https://pub.dev/packages/flutter_local_notifications)

### Hardware, Media & Utilities
- **Camera & Scanner**: [camera 0.12.1](https://pub.dev/packages/camera), [mobile_scanner 7.0.1](https://pub.dev/packages/mobile_scanner)
- **Image & Gallery**: [image_picker 1.1.2](https://pub.dev/packages/image_picker), [photo_manager 3.12.0](https://pub.dev/packages/photo_manager)
- **Image Caching**: [cached_network_image 3.4.1](https://pub.dev/packages/cached_network_image), [flutter_cache_manager 3.4.1](https://pub.dev/packages/flutter_cache_manager)
- **Video Playback**: [video_player 2.9.2](https://pub.dev/packages/video_player)
- **Vector Graphics**: [flutter_svg 2.3.0](https://pub.dev/packages/flutter_svg)
- **Permissions**: [permission_handler 13.0.2](https://pub.dev/packages/permission_handler)
- **Device Information**: [device_info_plus 13.2.0](https://pub.dev/packages/device_info_plus)
- **URL Launching**: [url_launcher 6.3.2](https://pub.dev/packages/url_launcher)

### Testing & Code Quality
- **Unit & Widget Testing**: `flutter_test`
- **Mocking**: [mocktail 1.0.3](https://pub.dev/packages/mocktail)
- **Code Linter**: [flutter_lints 6.0.0](https://pub.dev/packages/flutter_lints)

---

## 🏛 Architecture & Design System

### Clean Feature-First Architecture
The codebase strictly adheres to a **feature-first** modular layout where each domain feature encapsulates three clean layers:

```text
features/<feature_name>/
├── data/              # Remote & local data sources, API DTOs, mappers, and repository implementations
├── domain/            # Pure business logic: domain entities, value objects, and repository interfaces
└── presentation/      # UI Layer: GetView screens, GetxControllers, route Bindings, and local widgets
```

### Bilingual Design System & Typography
GenLink KH is built from the ground up to provide world-class bilingual readability:

- **Typography**:
  - **Sora**: Latin heading and body font (`assets/fonts/Sora-*.ttf`).
  - **Kantumruy Pro**: Native Khmer typography (`assets/fonts/KantumruyPro-*.ttf`) with customized line heights to eliminate clipped diacritics.
- **Themes**:
  - Full support for **Light** and **Dark** themes dynamically adjusted per language (`AppTheme.lightFor(languageCode)` / `AppTheme.darkFor(languageCode)`).
- **Design Primitives**:
  - Consistent tokens in `lib/design_system/` covering colors, spacing, radius, elevations, and glassmorphic card overlays.
  - Reusable components: `AppButton` (with built-in loading spinner), `AppTextField`, `OtpInput`, `AppAvatar`, and custom bottom navigation sheets.

---

## 📁 Project Structure

```text
GENLINK_KH_FRONTEND/
├── android/                  # Native Android configuration (Gradle, Manifest, permissions)
├── assets/                   # Static app assets
│   ├── fonts/                # Sora and Kantumruy Pro font files
│   ├── icons/                # PNG and SVG icon sets
│   ├── images/               # Raster artwork, profile covers, level-up graphics
│   ├── logos/                # GenLink KH brand logos & icons
│   ├── splash/               # Splash screen illustrations
│   └── stickers/             # Reaction stickers & chat media
├── ios/                      # Native iOS project (Runner, Info.plist, Podfile)
├── lib/
│   ├── app/                  # Application bootstrap, routing table, theme wiring, bindings
│   ├── core/                 # Cross-cutting infrastructure
│   │   ├── config/           # AppConfig & compile-time environment flags
│   │   ├── localization/     # GetX AppTranslations (Khmer & English dictionaries)
│   │   ├── network/          # Dio client, AuthInterceptor, token refresh, AppError
│   │   ├── storage/          # LocalStorage (flutter_secure_storage)
│   │   └── theme/            # ThemeController, colors, typography, theme definitions
│   ├── design_system/        # Design system tokens and reusable UI widgets
│   ├── features/             # Modular feature packages (data / domain / presentation)
│   ├── shared/               # Shared models, global widgets, and utilities
│   ├── main.dart             # Application entry point
│   └── main_screen.dart      # Persistent bottom navigation shell
├── test/                     # Unit, widget, and golden test suites
├── pubspec.yaml              # Dependencies, asset declarations, and font definitions
└── analysis_options.yaml     # Static analysis and lint configurations
```

---

## 🚀 Getting Started & Local Setup

### Prerequisites

Ensure the following tools are installed on your machine:
- **Flutter SDK**: `>= 3.22.x` (Channel `stable`)
- **Dart SDK**: `^3.12.2`
- **Android Studio** (with Android SDK & Command-line Tools) and/or **Xcode** (for macOS/iOS development)
- **CocoaPods** (for iOS dependencies: `sudo gem install cocoapods`)

Verify your installation by running:
```bash
flutter doctor
```

### Installation

1. Navigate to the project directory:
   ```bash
   cd GENLINK_KH_FRONTEND
   ```

2. Fetch all package dependencies:
   ```bash
   flutter pub get
   ```

### Environment Configuration

The application uses compile-time environment flags defined in `lib/core/config/app_config.dart`. You can override them using `--dart-define`:

| Variable | Default Value | Description |
|---|---|---|
| `API_BASE_URL` | `https://api.genlink.enat.online` | Base URL of the Spring Boot API backend |
| `GOOGLE_SERVER_CLIENT_ID` | Configured Web Client ID | OAuth 2.0 Web Client ID for Google Sign-In |

For local backend development running Spring Boot at `http://10.0.2.2:8888` (Android emulator) or `http://localhost:8888` (iOS simulator):
```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8888
```

### Running the App

1. Connect a physical device or start an emulator/simulator.
2. Launch the application:
   ```bash
   # Run on default connected device
   flutter run

   # Run on a specific device
   flutter run -d android
   flutter run -d ios
   flutter run -d chrome
   ```

### Firebase & Google Sign-In Setup

1. **Android**:
   - Ensure `google-services.json` is located in `android/app/`.
   - Register your local SHA-1 and SHA-256 keystore fingerprints in the Firebase Console:
     ```bash
     cd android && ./gradlew signingReport
     ```
2. **iOS**:
   - Ensure `GoogleService-Info.plist` is added to `ios/Runner/`.
   - Verify URL Schemes in Xcode under **Runner > Info > URL Types**.

---

## 🧪 Testing & Quality Assurance

Run the automated test suite and linter before submitting changes:

```bash
# Run all unit and widget tests
flutter test

# Run static analysis
flutter analyze

# Verify code formatting
dart format --output=none --set-exit-if-changed .
```

---

## 📦 Build & Release

To create production binaries:

### Android
```bash
# Build a release APK
flutter build apk --release

# Build an Android App Bundle (AAB) for Google Play
flutter build appbundle --release
```

### iOS
```bash
# Build an iOS archive
flutter build ipa --release
```

---

## 👥 Development Team

### **Full Stack Developers**
- **Ren Makara**
- **Heng Chansela**
- **Sokny Enat**
- **Chhaeng Sokuntheara**

---

*Part of the **GenLink KH** Project — Connecting generations through technology.*
