# Contributing to SnippetFlow

Thanks for helping improve SnippetFlow. Bug reports, feature proposals, and pull
requests are welcome.

## Before you start

- Search existing issues before opening a new one.
- For a substantial change, open an issue first so the approach can be discussed.
- Report security vulnerabilities privately using [SECURITY.md](SECURITY.md), not
  in a public issue.
- Follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## Development setup

Requirements:

- macOS 13 Ventura or later.
- Xcode 15 or later, or the Xcode Command Line Tools with Swift 5.9 or later.

```sh
git clone https://github.com/tn5052/SnippetFlow.git
cd SnippetFlow
swift test
./build.sh
open SnippetFlow.app
```

The project uses Swift Package Manager and has no third-party dependencies.
`build.sh` creates a locally signed `SnippetFlow.app` bundle.

If you rebuild the app and macOS no longer prompts for permissions, reset them:

```sh
tccutil reset ScreenCapture com.umarjaved.SnippetFlow
tccutil reset Accessibility com.umarjaved.SnippetFlow
```

Launch the app again and grant access when prompted.

## Making changes

- Keep changes focused. Separate unrelated fixes and refactors into different
  pull requests.
- Follow the existing Swift and AppKit/SwiftUI style.
- Keep OCR, barcode recognition, and text processing local. Do not add network
  access or telemetry without prior discussion.
- Do not log clipboard contents, recognized text, or other user data.
- Add or update tests for logic that can be tested without a screen capture.
- Update the README when behavior, setup, or permissions change.

## Tests

Run the full suite before opening a pull request:

```sh
swift test
```

For UI or capture changes, also build and manually test the app:

```sh
./build.sh
open SnippetFlow.app
```

Test text capture, barcode capture, shortcut recording, permissions, and any
settings affected by your change. Remove or redact sensitive text from
screenshots before attaching them to an issue or pull request.

## Pull requests

A useful pull request includes:

- A short explanation of the problem and the approach.
- The user-visible behavior change, if any.
- Test results and manual verification steps.
- Screenshots or a short recording for UI changes, with sensitive content
  removed.

Before submitting:

- [ ] `swift test` passes.
- [ ] The app builds with `./build.sh`.
- [ ] The change is limited to the intended scope.
- [ ] No `.build/`, `.app`, screenshots, crash logs, or local preferences are
      included.
- [ ] No credentials, tokens, private keys, or personal data are included.
- [ ] New code and assets are original or license-compatible with attribution.

## Commit messages

Use short, imperative messages that describe the change, for example:

```text
Fix barcode capture on secondary displays
Add custom words validation tests
Document Screen Recording permission setup
```

## Licensing

By contributing, you agree that your contributions are licensed under the
project's [MIT License](LICENSE). Do not submit code or assets copied from
another app unless their license allows it and the source is credited.
