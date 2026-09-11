# GenLink KH Flutter Structure

Tagline: Connect. Grow. Thrive.

This project uses feature-first architecture, GetX-ready app wiring, and clean architecture layer boundaries.

```text
lib/
  app/                  App bootstrap, root app shell, routing, and initial bindings.
  core/                 Cross-cutting infrastructure such as config, network, storage, localization, services, utils, extensions, and errors.
  design_system/        Theme tokens, color tokens, typography, spacing, radius, shadows, glass effects, icons, and reusable UI widgets.
  features/             Feature-first modules. Each feature owns data, domain, and presentation layers.
  shared/               Cross-feature widgets, models, enums, mixins, and helpers that are not design-system primitives.
  l10n/                 ARB localization files for English and Khmer.

assets/
  fonts/                Sora and Kantumruy Pro font files.
  icons/svg/            Exported vector icons only.
  icons/png/            Exported raster icons only.
  logos/                Brand and partner logos.
  images/               General raster images.
  illustrations/        Decorative illustrations exported from design tools.
  lottie/               Lottie animation files.
  backgrounds/          Optimized WebP screen backgrounds grouped by feature.
  textures/             Noise and grain textures, such as noise.webp and grain.webp.
```

## Layer Notes

- `data/`: data sources, DTOs, mappers, and repository implementations.
- `domain/`: entities, value objects, repository contracts, and use cases.
- `presentation/`: GetX controllers, bindings, view models, and screen widgets.

## Design Asset Strategy

Flutter owns theme, buttons, cards, typography, navigation, glass effects, input fields, dialogs, and responsive layout.

Figma exports only backgrounds, decorative gradients, mesh gradients, noise textures, illustrations, logos, icons, and Lottie animations.

Do not export button backgrounds or cards from Figma. Only decorative assets belong inside `assets/backgrounds/`.

## Background Naming

Use one optimized WebP background per reusable screen background:

```text
assets/backgrounds/home/home_background.webp
assets/backgrounds/finance/finance_background.webp
assets/backgrounds/profile/profile_background.webp
```
