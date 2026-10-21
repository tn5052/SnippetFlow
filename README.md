# SnippetFlow

SnippetFlow is a lightweight, open-source macOS menu-bar utility for capturing
text from the screen with on-device OCR. It supports plain text capture, QR and
barcode reading, optional clipboard history, text-to-speech, custom words, and
configurable global shortcuts.

SnippetFlow runs as a menu-bar-only app: it has no Dock icon and no persistent
main window.

## Features

- Select any screen region and copy the recognized text.
- Read QR codes and barcodes.
- Import an image for OCR.
- Optionally preserve line breaks.
- Optional additive clipboard history.
- Optional text-to-speech with adjustable rate.
- Custom words for domain-specific vocabulary.
- Configurable global shortcuts.
- Automatic language detection and language selection.
- Menu-bar onboarding and permission guidance.

## Requirements

- macOS 13 Ventura or later.
- Swift 5.9 or later, or the matching Xcode Command Line Tools.

## Build

```sh
./build.sh
open SnippetFlow.app
```

The build script compiles the Swift package, assembles `SnippetFlow.app`, copies
the original project icon, and ad-hoc signs the bundle.

A prebuilt app is intentionally not committed. Build it locally or publish it as
a release artifact.

## Permissions

macOS requires two permissions:

- **Screen Recording** for region capture.
- **Accessibility** for reliable global shortcuts and paste monitoring.

Permissions are tied to the bundle identifier and code signature. If the app is
rebuilt with a different signature, macOS may require removing and re-adding it
in System Settings. See the in-app settings screen for direct links.

## Privacy

- OCR and barcode recognition run locally with Apple Vision/VisionKit.
- SnippetFlow makes no network requests and collects no telemetry.
- Clipboard history is stored only in local `UserDefaults`.
- Clipboard contents are not logged or transmitted.

## Development

```sh
swift test
```

The compatibility research in [`CLONE_SPEC.md`](CLONE_SPEC.md) documents the
observable behavior that informed the implementation. It contains behavioral
notes and evidence only; no proprietary source code, artwork, icons, fonts, or
other assets from the reference app are included.

TextSniper is a trademark of its respective owner. SnippetFlow is an independent
project and is not affiliated with or endorsed by TextSniper.

## License

MIT. See [`LICENSE`](LICENSE).
