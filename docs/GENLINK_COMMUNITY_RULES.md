# GenLink Community Module Development Rules

> **Role & Standard**: Senior Flutter Engineer working on production-level Flutter application **GenLink** (University Community Platform). Every feature must strictly adhere to these engineering and UI/UX standards.

---

## 1. Architecture & Clean Code
* Follow Clean Architecture and modular folder structure (`lib/features/.../{data,domain,presentation}`).
* Keep UI, business logic, and data layers strictly separated.
* Business logic belongs in GetX Controllers and Services—never inside View/Widget classes.
* Utilize reusable components; eliminate duplicate code.

---

## 2. Navigation
* **GetX Navigation Only**: Never use raw `Navigator.push()` or `MaterialPageRoute`.
* Register every screen route in `AppRoutes`.
* Navigate exclusively using `Get.toNamed()` or `Get.offNamed()`.

---

## 3. Localization
* All user-facing text strings must append `.tr` (e.g., `"create_story".tr`).
* Never hardcode raw English text strings in UI widgets.
* Ensure all new key-value string pairs are added to English (`en_US.json`) and Khmer (`km_KH.json`) translation files.

---

## 4. Design System Enforcers
* Utilize standardized design system tokens:
  - `AppColors` (Pure B&W theme: dark surfaces `#121212`, `#1C1C1C`, `#2F2F2F`, `#FFFFFF`, `#000000`).
  - `AppSpacing`
  - `AppRadius`
  - `AppTextStyles` / `Theme.of(context).textTheme`
* Never hardcode raw HSL/RGB hex color values, padding, or font sizes in feature widgets.

---

## 5. Data & Repository Flow
* Never hardcode mock data inside UI widgets.
* Data Flow: `Controller` → `Repository` → `API / Mock DataSource`.
* If backend APIs are in development, rely on Mock Repositories or robust Empty States.

---

## 6. Responsive UI & Layout Safety
* Guaranteed responsiveness across Android, iPhone, and Tablet devices.
* Avoid fixed width boundaries unless structurally required.
* Utilize `Expanded`, `Flexible`, `LayoutBuilder`, and `MediaQuery`.
* Zero tolerance for `RenderFlex` overflow warnings.

---

## 7. Performance & State Efficiency
* Minimize widget rebuilds using targeted `Obx()` / `GetBuilder` scopes.
* Implement lazy loading for lists/media streams.
* Always dispose controllers and stream listeners.
* Optimize asset image caching and maintain smooth 60 FPS animation execution.

---

## 8. UX & Social Interaction Patterns
* Deliver interactions inspired by modern social media platforms (Facebook, Instagram, TikTok) customized for GenLink branding.
* Prioritize: simplicity, discoverability, fast editing, minimal taps, and natural multi-touch gestures.

---

## 9. Story Editor Standards
* Full gesture support: drag, pinch-to-zoom, rotate, resize, double-tap to fit, responsive canvas clamping.
* Instant element deletion during drafting with non-intrusive `Undo` action—no individual deletion dialogs.
* Confirmation popups reserved strictly for system destructive actions (`"Discard Story?"` draft leave and published story deletion).

---

## 10. Senior Engineering Directive
> **Architectural Compliance**: If a requested implementation violates GenLink's architecture, coding standards, localization, or design system tokens, do not generate quick workarounds. Explicitly highlight the issue and deliver a solution fully compliant with project standards. Prioritize long-term maintainability and production readiness over quick hacks.
