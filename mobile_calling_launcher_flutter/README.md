
# Mobile Calling Launcher

Flutter Android implementation of a mobile calling launcher.

## Build

Install Flutter, then from this folder:

```bash
flutter pub get
flutter analyze
flutter build apk --release
```

APK:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Install

Enable USB debugging on the Android phone, connect it, then:

```bash
flutter install
```

or copy the generated APK to the phone and open it.

## Notes

- The call button launches the Android phone-call flow using `tel:`.
- The app requests CALL_PHONE through the Android manifest.
- Recent calls in this starter are calls initiated from the app during the current session.
- Favorites are persisted locally.
- The exact Figma component tree could not be extracted from the published Figma site, so the implementation uses a clean calling-launcher interpretation rather than claiming pixel-perfect reproduction.
