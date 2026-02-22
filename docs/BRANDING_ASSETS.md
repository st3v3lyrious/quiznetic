# BRANDING ASSETS

This guide defines the branding pipeline for app icons, splash screens, and core color tokens.

## Current Status

- Branding automation is configured in `pubspec.yaml`:
  - `flutter_launcher_icons`
  - `flutter_native_splash`
- Theme colors are centralized in `lib/config/brand_config.dart`.
- Web manifest branding metadata is set in `web/manifest.json`.

## Source Assets

Use these source files as the single source of truth:

- App icon source: `assets/images/logo-color.png` (square PNG, recommended 1024x1024+)
- Splash light logo: `assets/images/logo-color.png` (transparent or opaque PNG)
- Splash dark logo: `assets/images/logo-white.png`

If you rename files, update `pubspec.yaml` launcher/splash config before regeneration.

## Color Tokens

Update brand colors in:

- `lib/config/brand_config.dart` for app theme tokens
- `web/manifest.json` for web/PWA colors
- `pubspec.yaml` `flutter_native_splash` colors
- `pubspec.yaml` `flutter_launcher_icons.web.theme_color`

Current active tokens (stable until full EIRENYA rollout):

- Primary: `#4A596D`
- Surface/background: `#F3F4F5`
- Neutral surface container: `#DBDEE2`

EIRENYA palette swatches (from brand reference):

- `Bleu Sérénité`: `#4A90E2`
- `Bleu Nuit Profond`: `#001B2A`
- `Doré Spirituel`: `#F5C542`
- `Jaune Lumière Douce`: `#FFD87A`
- `Blanc cassé`: `#F9F9F6`
- `Beige Lin`: `#E6DDC6`
- `Gris Perle`: `#D3D3D3`

Suggested semantic mapping for app refresh:

- Primary buttons/links: `#4A90E2`
- Primary text on dark areas and app-bar contrast: `#001B2A`
- Accent CTA/highlights/badges: `#F5C542`
- Soft accent/hover/secondary emphasis: `#FFD87A`
- App background: `#F9F9F6`
- Cards/surfaces: `#E6DDC6`
- Dividers/disabled/neutral chips: `#D3D3D3`

## Generate Icons And Splash

Run:

```bash
./tools/refresh_branding_assets.sh
```

Equivalent manual commands:

```bash
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## iOS Post-Generation Sanity Check

After running branding generation, verify `ios/Runner.xcodeproj/project.pbxproj`
still has valid iOS build settings:

- `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES`
  for project `Debug` and `Release` configurations.
- `IPHONEOS_DEPLOYMENT_TARGET = 15.0` for Runner target
  `Debug`/`Release`/`Profile` configurations (matches `ios/Podfile`).

Invalid values here can trigger `ASSETCATALOG` and Xcode compiler failures in CI.

## MVP Completion Conditions For M12

Mark M12 complete after all are true:

- Final icon artwork exported and generated for Android, iOS, web, macOS, and Windows.
- Final splash artwork/colors generated for Android and iOS (light and dark).
- Visual QA passed on at least one real Android device and one iOS device/simulator.
- Web tab/favicon/manifest colors visually match brand.
