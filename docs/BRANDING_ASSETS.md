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

## MVP Completion Conditions For M12

Mark M12 complete after all are true:

- Final icon artwork exported and generated for Android, iOS, web, macOS, and Windows.
- Final splash artwork/colors generated for Android and iOS (light and dark).
- Visual QA passed on at least one real Android device and one iOS device/simulator.
- Web tab/favicon/manifest colors visually match brand.
