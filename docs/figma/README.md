# GenLink KH — Figma design system handoff

`genlink_design_system.json` is the source-of-truth handoff for rebuilding the
GenLink KH design system in Figma. It mirrors the Flutter tokens in
`lib/design_system/colors/app_colors.dart` and
`lib/design_system/typography/app_text_theme.dart`.

## Figma setup

### Native file

The foundations have been created in the signed-in Figma workspace:

- [GenLink KH Design System](https://www.figma.com/design/KZ1MTVeYjfyP4RX4E33PAg/GenLink-KH-Design-System)
- Page: `Foundations`
- Page: `Theme Playground` (mode-switch verification surface)
- Page: `Translations` (locale copy reference and binding playground)
- Variables: `GenLink / Colors` (29 variables; `Light`, `Dark`) and
  `GenLink / Typography` (5 variables; `English`, `Khmer`)
- Variables: `GenLink / Copy` (286 scoped string variables; `English`, `Khmer`)
  imported from `lib/core/localization/app_translations.dart`. The imported
  scope covers Common/First-run, Auth, Navigation, Profile/Profile setup,
  Settings, Privacy, Notifications, and related profile labels.
- Text styles: locale-prefixed styles for all 15 entries in `textStyles`
  (`English / ...` and `Khmer / ...`), with `text/primary` or
  `text/secondary` variable fills.
- Theme Playground: a preview frame bound to `bg/primary`, a rounded card
  bound to `surface/primary` + `border/subtle`, and English/Khmer preview text
  with the locale styles available in the `English` and `Khmer` style groups.
  Select the page and use **Apply variable mode** in the right sidebar to
  switch `Light` ↔ `Dark` and `English` ↔ `Khmer`. Figma text styles are
  explicit style objects, so choose the matching locale style from the style
  picker when you want the preview copy to change font/metrics; the Typography
  mode selector remains the source for variable-bound font properties.

The checked-in DTCG import files used to create the native collections are
`genlink_colors_light.dtcg.json`, `genlink_colors_dark.dtcg.json`,
`genlink_typography_english.dtcg.json`, `genlink_typography_khmer.dtcg.json`,
`genlink_copy_english.dtcg.json`, and `genlink_copy_khmer.dtcg.json`.

### Locale copy workflow

1. Open the `Translations` page and select `Translation Reference / Locale
   Playground`.
2. In the right sidebar, open the `GenLink / Copy` mode selector and choose
   `English` or `Khmer`.
3. The bound samples (`auth.login`, `auth.verifyEmail`, and
   `auth.verifySubtitle`) update from the string variables. Placeholder tokens
   such as `@email`, `@count`, and `@seconds` are kept intact for design review.
4. The complete 286-key scoped table is available in the `GenLink / Copy`
   Variables view; the variable names map directly from Dart dotted keys to
   slash groups (for example, `auth.login` → `auth/login`).

1. Create a Variables collection named `GenLink / Colors` with the modes
   `Light` and `Dark`.
2. Add the color variables using the `name` and the matching mode value from
   the JSON file. Values ending in `B8`, `D6`, `14`, `29`, or `33` are 8-digit
   RGBA colors; keep their alpha instead of converting them to opaque colors.
3. Create a second collection named `GenLink / Typography` with the modes
   `English` and `Khmer`. Use the `font/family` and weight variables to build
   locale-specific text styles.
4. Create the global text styles from `textStyles`. The English and Khmer
   values are explicit because Khmer uses a slightly larger size, more line
   height, and lighter weight for readability.
5. Apply the `fillVariable` color to each text style so Light/Dark switching is
   controlled by the color collection rather than duplicated hex values.

## Font files

- English: `Sora` (`assets/fonts/Sora-*.ttf`)
- Khmer: `KantumruyPro` (`assets/fonts/KantumruyPro-*.ttf`)

The JSON is intentionally a neutral, tool-friendly handoff format rather than
a proprietary `.fig` binary. A native `.fig` file must be created or imported
inside a signed-in Figma workspace; this package keeps the values reviewable,
versionable, and traceable back to Flutter. It is a checked-in handoff rather
than a live Figma–Flutter sync, so update both token sources together when the
design system changes.

### Font-weight mapping

Flutter numeric weights map to the closest installed Figma styles: `400` →
Regular, `500` → Medium where available (Regular for Sora where Figma exposes
no Medium face), `600` → SemiBold, and `700` → Bold. The source JSON remains
numeric so Flutter and Figma can continue to share the same token contract.
