# habitbank

Social fitness accountability app — Flutter (Cupertino) + Supabase.

## Setup

```bash
flutter pub get
dart run flutter_launcher_icons    # regenerates platform app icons
dart run flutter_native_splash:create  # regenerates native splash assets
flutter run
```

The launcher-icon and native-splash configs live in `pubspec.yaml`. Source
artwork is in `assets/`:

| File | Purpose |
| --- | --- |
| `assets/logo.svg` | Vector source — rendered in-app via `flutter_svg` |
| `assets/logo.png` | 1024-wide PNG of the logo (transparent) |
| `assets/icon.png` | 1024×1024 square, white bg — fed to `flutter_launcher_icons` |
| `assets/splash.png` | Native-splash centerpiece — fed to `flutter_native_splash` |

To regenerate the PNGs from `logo.svg`:

```bash
python3 scripts/build_logo_assets.py
```
