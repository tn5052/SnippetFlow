# SnippetFlow

SnippetFlow is a lightweight macOS menu-bar app for capturing text from the
screen with on-device OCR. Select a region, recognize the text, and copy it
without switching apps. It can also read QR codes and barcodes, import images,
speak recognized text, and keep an optional clipboard history.

SnippetFlow has no Dock icon and no persistent main window. It lives in the menu
bar and stays out of the way until you need it.

- Source: <https://github.com/tn5052/SnippetFlow>
- License: [MIT](LICENSE)

## Features

- Capture text from any screen region using Apple Vision OCR.
- Read QR codes and barcodes from a selected region.
- Import an image for OCR.
- Preserve or collapse line breaks.
- Auto-detect the recognition language or choose one manually.
- Improve recognition with a custom words list.
- Optional text-to-speech with an adjustable speech rate.
- Optional additive clipboard history.
- Configurable global shortcuts.
- Launch at login and menu-bar visibility controls.
- Local-only operation with no telemetry.

## Requirements

- macOS 13 Ventura or later.
- Xcode 15 or later, or the Xcode Command Line Tools with Swift 5.9 or later.

To install the command-line tools:

```sh
xcode-select --install
swift --version
```

## Build and install

```sh
git clone https://github.com/tn5052/SnippetFlow.git
cd SnippetFlow
./build.sh
open SnippetFlow.app
```

`build.sh` compiles the Swift package, assembles `SnippetFlow.app`, copies the
app icon, and ad-hoc signs the bundle. No Apple Developer account is required
for a local build.

To install, drag `SnippetFlow.app` to `/Applications` and launch it from there.
The app is not notarized because it is built locally; if macOS warns about an
app downloaded from the internet, build from source instead.

For a debug build:

```sh
CONFIG=debug ./build.sh
```

## First run

1. Launch `SnippetFlow.app`.
2. Click the menu-bar icon to open the menu.
3. Follow the onboarding prompt and grant **Screen Recording** permission.
4. Grant **Accessibility** permission if you want global shortcut handling and
   paste monitoring.
5. Open **Preferences...** to choose shortcuts, language, output, and clipboard
   behavior.

The default capture shortcut is `Command-Shift-2`.

## Permissions

SnippetFlow uses two macOS privacy permissions:

| Permission | Why it is needed |
| --- | --- |
| Screen Recording | Required to capture the selected screen region. |
| Accessibility | Used for reliable global shortcut handling and the optional paste monitor. |

Permissions are tied to the app's bundle identifier and code signature. If a
rebuilt app stops responding to shortcuts or cannot capture the screen, remove
the existing entries and grant permission again in **System Settings > Privacy &
Security**.

You can also reset the permissions from Terminal:

```sh
tccutil reset ScreenCapture com.umarjaved.SnippetFlow
tccutil reset Accessibility com.umarjaved.SnippetFlow
```

Relaunch the app and grant access when prompted.

If a capture fails with an error such as `could not create image from rect`,
macOS is blocking Screen Recording; the rectangle itself is not the problem.
Quit SnippetFlow, reset the permission with the command above, relaunch, and
enable SnippetFlow under **System Settings > Privacy & Security > Screen
Recording**. You may need to quit and reopen the app after changing the setting.

## Usage

| Action | Default shortcut |
| --- | --- |
| Capture text | `Command-Shift-2` |
| Capture with text to speech | `Command-Option-Shift-S` |
| Toggle keep line breaks | `Command-Option-Shift-L` |
| Toggle additive clipboard | `Command-Option-Shift-H` |

Other actions, including **Capture Previous Area**, **Capture Without Line
Breaks**, **Capture With Line Breaks**, and **Read QR/Bar Code**, can be assigned
from **Preferences > Shortcuts**.

The menu also provides:

- **Take Photo** to import an image from disk for OCR.
- **Clear Clipboard History** to remove saved clipboard entries.
- **Stop Speaking** to stop text-to-speech playback.

## Configuration

Open **Preferences...** from the menu bar:

- **General**: language detection, recognition language, line breaks,
  text-to-speech, link opening, launch at login, menu-bar visibility, sounds,
  notifications, and permission status.
- **Shortcuts**: click a shortcut, then press a new key combination. Press
  `Escape` to cancel.
- **Custom Words**: comma-separated terms that should be preferred during
  recognition.
- **About**: version and project information.

Clipboard history is optional. When enabled, entries are stored in the app's
local preferences and can be cleared from the menu.

## Privacy

- OCR, barcode recognition, and text processing run locally using Apple
  frameworks.
- SnippetFlow makes no network requests, collects no telemetry, and requires no
  account.
- Clipboard history is stored only in local `UserDefaults`.
- Clipboard contents and recognized text are not logged or transmitted.

Screen captures can contain sensitive information. Review captured text before
copying it into another service or storing it in clipboard history.

## Development

Run the test suite:

```sh
swift test
```

The suite covers text processing, clipboard behavior, OCR helpers, screen
capture error handling, shortcut storage, and menu construction.

Build the app bundle without installing it:

```sh
./build.sh
```

## Project structure

```text
Sources/SnippetFlow/       Application source
Tests/SnippetFlowTests/    Unit tests
Support/                   Info.plist and app icon
build.sh                   App bundle assembly script
CLONE_SPEC.md              Compatibility research from REA analysis
```

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for the
development workflow and pull-request expectations.

By participating, you agree to follow the [Code of Conduct](CODE_OF_CONDUCT.md).
Please report security issues privately as described in [SECURITY.md](SECURITY.md).

The compatibility research in [CLONE_SPEC.md](CLONE_SPEC.md) documents observable
behavior that informed the implementation. Do not submit source code, artwork,
icons, fonts, or other assets copied from the reference app or any other
third-party project unless their licenses permit it and attribution is included.

## Compatibility research

[`CLONE_SPEC.md`](CLONE_SPEC.md) documents compatibility research for
SnippetFlow. It was produced with the REA (reverse-engineer-anything) workflow
from static and runtime analysis of the actual shipped TextSniper 1.11 (525) app
bundle.

The document records observable behavior, packaging details, and evidence
references used to define SnippetFlow's compatibility requirements. It does not
include or redistribute proprietary source code, artwork, icons, fonts, or other
assets from TextSniper. SnippetFlow is an independent implementation.

## Attribution

TextSniper is a trademark of its respective owner. SnippetFlow is not affiliated
with or endorsed by TextSniper. No proprietary source code or assets from the
reference product are included in this repository.

## License

MIT. See [LICENSE](LICENSE).
