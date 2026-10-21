# SnippetFlow Compatibility Specification

Project: [SnippetFlow](https://github.com/tn5052/SnippetFlow)

Status: Compatibility research for SnippetFlow, based on static analysis of TextSniper 1.11 (525).

Method: Produced with the REA (reverse-engineer-anything) workflow from analysis of the actual shipped TextSniper 1.11 (525) app bundle.

Target: `/Applications/TextSniper.app`, bundle `com.valerijs.boguckis.TextSniper`.

Purpose: define the observable behavior required for SnippetFlow, an independent macOS menu-bar OCR utility. This document records behavior and evidence only; it contains no proprietary implementation code or assets. Do not copy TextSniper artwork, icons, fonts, or source code. TextSniper is a trademark of its respective owner.

Evidence notation:

- `BIN 0x...` = virtual address in the arm64 slice.
- `NIB object N` = object index in `Base.lproj/Main.storyboardc/MainMenu.nib`.
- `PLIST` = `Contents/Info.plist` or the live preferences file.
- `UNKNOWN` = not established by the available evidence.

---

## 1. Product Summary

TextSniper is a menu-bar-only utility that:

1. Captures a user-selected area of the screen.
2. Recognizes text in the captured image, or reads a QR/barcode.
3. Copies recognized text to the system pasteboard.
4. Optionally keeps an additive clipboard history.
5. Optionally speaks recognized text.
6. Optionally opens detected links.
7. Supports recognition language selection, automatic language detection, custom words, login-at-start, and configurable global shortcuts.
8. Runs without a Dock icon.

The app uses `/usr/sbin/screencapture` for interactive region capture and Apple Vision/VisionKit for OCR. It is not sandboxed and uses the screen-capture Mach service exception plus Accessibility permission for global key handling.

---

## 2. App Identity and Packaging

| Property | Value |
|---|---|
| Bundle identifier | `com.valerijs.boguckis.TextSniper` |
| Version / build | `1.11` / `525` |
| Minimum macOS | `10.15` |
| UI element | `LSUIElement = true` |
| Main storyboard | `Main` |
| Principal class | `NSApplication` |
| Category | `public.app-category.productivity` |
| Team ID | `RPN9K33H8H` |
| Signing | Developer ID, hardened runtime, notarization stapled |
| Architectures | x86_64 and arm64 |
| arm64 minimum OS | 11.0 |
| arm64 SDK | 15.1 |

Required bundle resources:

- `Base.lproj/Main.storyboardc/MainMenu.nib`
- `GeneralPreferenceViewController.nib`
- `ShortcutPreferenceViewController.nib`
- `CustomWordsViewController.nib`
- `TranslationWindow.nib`
- `WindowScreen.nib`
- `MenubarNotificationController.nib`
- `CCWindowController.nib`
- `CCCustomItemView.nib`
- `Assets.car`, localization resources, and the TextSniper menu-bar icon.

Login helper:

- `Contents/Library/LoginItems/LaunchAtLoginHelper.app`
- Bundle identifier `com.valerijs.boguckis.TextSniper-LaunchAtLoginHelper`
- `LSBackgroundOnly = true`
- Version `1.0.1`, build `2`
- Minimum macOS `10.14.4`
- Copyright string indicates Sindre Sorhus `LaunchAtLogin` (MIT).

Frameworks:

- `Paddle.framework` for licensing.
- `Sparkle.framework` for updates.
- Third-party components include `Preferences`, `KeyboardShortcuts`, and `LaunchAtLogin`.

Info.plist update settings:

- `SUEnableAutomaticChecks = true`
- `SUFeedURL = https://textsniper.app/latest_releases.xml`
- `SUPublicEDKey = WIusXY4pcneBX0o4CvK/0o+GjVu7A+8lB8uPE3PXNHs=`

No `NSServices` key is present, even though `WrapperController` implements `NSServicesMenuRequestor`. System Services registration behavior is `UNKNOWN`.

---

## 3. Launch and Lifecycle

### 3.1 Normal launch

On launch the app must:

1. Initialize the licensing framework.
2. Install the menu-bar status item and its menu.
3. Register default keyboard shortcuts.
4. Install the global key-down monitor only when Accessibility is trusted.
5. Show onboarding on first launch.
6. Start the update framework.

The app is an agent (`LSUIElement`). It must not show a Dock icon or a normal document window at launch.

### 3.2 First launch

`isFirstTimeLaunch` controls onboarding. The app creates a welcome window, activates itself, and displays a menubar popover loaded from `MenubarNotificationController.nib`.

Required copy:

- `👋 Hey!`
- `Click the icon in the menu bar to get started with TextSniper`
- `Got It`

After dismissal, `isFirstTimeLaunch` is cleared.

### 3.3 Quit

The Quit item targets the standard application termination path and uses Command-Q.

### 3.4 Single instance / relaunch

Whether a second instance is prevented is `UNKNOWN`. The app is distributed as a normal `.app` and is commonly launched from Applications or Launchpad.

---

## 4. Menu Bar and Main Menu

### 4.1 Menu structure

The compiled `MainMenu.nib` contains:

- Object 55: `NSMenu` named `_NSAppleMenu`, title `TextSniper`.
- Object 90: `NSMenu` named `_NSMainMenu`.
- Object 95: `NSMenuItem` title `TextSniper`, submenu 55.

Only these two `NSMenu` objects are present. The status-item menu is therefore either wired at runtime or uses one of these menus. Exact status-item wiring is `UNKNOWN`.

### 4.2 Exact menu order

The status/main menu must contain the following items in this order:

| # | Title | Object | Identifier | Action / binding | Key equivalent |
|---|---|---|---|---|---|
| 1 | *(empty)* | 60 | — | separator-like placeholder | — |
| 2 | Capture Text | 9 | `captureTextMenuItem` | `captureTextAction:` | — |
| 3 | Read QR/Bar Code | 43 | `readBarcodeMenuItem` | `captureBarcode:` | — |
| 4 | Take Photo | 61 | — | `NSMenuItemImportFromDeviceIdentifier` system item | — |
| 5 | *(empty)* | 66 | — | separator-like placeholder | — |
| 6 | Keep Line Breaks | 37 | `keepLineBreaksMenuItem` | binding `values.LineSettings` | — |
| 7 | *(empty)* | 67 | — | separator-like placeholder | — |
| 8 | Additive Clipboard | 31 | `keepHistoryMenuItem` | binding `values.keepHistoryKey` | — |
| 9 | Clear Clipboard History | 25 | `clearHistoryMenuItem` | `clearHistoryAction:` | — |
| 10 | *(empty)* | 68 | — | separator-like placeholder | — |
| 11 | Text to Speech | 69 | — | binding `values.textToSpeech` | — |
| 12 | Stop Speaking | 49 | `stopSpeakingMenuItem` | `stopSpeakingAction:` | — |
| 13 | *(empty)* | 73 | — | separator-like placeholder | — |
| 14 | Preferences... | 74 | — | `showPreferences:` | — |
| 15 | *(empty)* | 78 | — | separator-like placeholder | — |
| 16 | Quit TextSniper | 79 | — | `terminate:` | Command-Q |

Exact binding connectors:

- Text to Speech: NIB objects 120-124. Source 69, destination `NSUserDefaultsController` 121, binding `value`, keypath `values.textToSpeech`, label `value: values.textToSpeech`.
- Keep Line Breaks: NIB objects 125-127. Source 37, destination 121, binding `value`, keypath `values.LineSettings`, label `value: values.LineSettings`.
- Additive Clipboard: NIB objects 128-130. Source 31, destination 121, binding `value`, keypath `values.keepHistoryKey`, label `value: values.keepHistoryKey`.

### 4.3 Empty menu items

Objects 60, 66, 67, 68, 73, and 78 have:

- empty title,
- empty key equivalent,
- `NSIsSeparator = false`,
- `NSHiddenInRepresentation = true`,
- no action or target.

They function as visual separators. Exact runtime rendering semantics are `UNKNOWN`; SnippetFlow may use standard separators if appearance matches.

### 4.4 Take Photo

`Take Photo` is an `NSMenuItem` with `NSMenuItemImportFromDeviceIdentifier`, not a custom action. It is the system “Import from iPhone/iPad” item used for Continuity Camera.

There is a help connector with the string `Click Right Mouse to Import From Iphone`. Its destination object is 43 (the Read QR/Bar Code item), not 61; the intended hover target is `UNKNOWN`. The string contains the original “Iphone” spelling.

### 4.5 Menu bar icon

`Show in Menu Bar` controls visibility. The settings note says:

`To restore menu bar icon relaunch TextSniper from Applications folder or Launchpad.`

The app does not implement a separate “show menu bar icon” command in the menu. Exact icon template/layout is a non-goal; use an original icon.

---

## 5. Capture Workflow

### 5.1 Capture Text

`captureTextAction:` must:

1. Create the screen capturer.
2. Start interactive region selection.
3. Pass the interactive capture mode and use the user’s line-break preference.
4. On completion, run OCR on the captured file.
5. On success, copy text and run post-capture actions.

The capture command is `NSTask` with:

- executable `/usr/sbin/screencapture`
- output file `screen_latest.png`
- interactive flag `-i`
- optionally `-x`

`-x` is added when the internal `Sound` value is true. The relationship between `Sound`, the visible `Disable Sound Effects` checkbox, and whether `-x` means “mute” is `UNKNOWN`; verify before cloning sound behavior.

### 5.2 Previous area

The app supports re-capturing the previous rectangle:

- The rectangle is stored under the misspelled key `PreviousCaptureAread`.
- The capture command uses `screencapture -R`.
- If the previous file exists, it is deleted before capture.
- If no previous rectangle exists, show the relevant error or fall back according to the original behavior; exact fallback is `UNKNOWN`.

### 5.3 Line break modes

Internal capture modes allow:

- use the `LineSettings` preference,
- force line breaks,
- force no line breaks.

For the interactive `Capture Text` action the app uses mode 2, which consults `LineSettings`. The exact mapping of every shortcut to every mode is `UNKNOWN`; the observable requirement is that “Keep Line Breaks” changes whether recognized lines are joined with newlines or spaces.

### 5.4 Screen Recording permission

Before capture, the app checks screen-capture access using CoreGraphics preflight APIs. If access is missing:

- Show a permission alert.
- Explain that Screen Recording permission is required.
- Offer a button that opens `x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture`.

Exact alert wording and button order are `UNKNOWN`; the required destination URL and permission are known.

### 5.5 Barcode capture

`captureBarcode:` uses the same screen-capture pipeline but a separate completion path for QR/barcode decoding. Supported symbologies, payload handling, and whether the result is copied, displayed, or opened are `UNKNOWN`.

---

## 6. OCR Backend Selection

The app contains two recognition paths.

### 6.1 macOS version gate

- macOS 10.15–13: use the older Vision path (`VNImageRequestHandler` + `VNRecognizeTextRequest`).
- macOS 14 and later: choose between the old Vision path and the newer VisionKit `ImageAnalyzer` path.

### 6.2 Language gate on macOS 14+

The selected language is compared against this exact static list:

- `zh-Hans`
- `zh-Hant`
- `yue-Hans`
- `yue-Hant`
- `ja-JP`
- `ko-KR`

Behavior established from `BIN 0x10001fb94` / `0x10001fce4` / `0x100020024`:

- If the selected language **is in** the six-item list, use VisionKit `ImageAnalyzer` with `AnalysisTypes.text`.
- If the selected language **is not in** the list, use the older Vision path.
- If macOS is older than 14, always use the older Vision path.

Debug strings in the original:

- `This is current selected language`
- `OLD TEXT RECOGNITON WAS CALLEd`
- `NEW TEXT RECOGNITON WAS CALLEd`

These typo-bearing strings are evidence only; they do not need to be user-visible.

### 6.3 Vision request configuration

The older path creates `VNRecognizeTextRequest` and configures:

- revision from `visionRevisionVersionKey`,
- `usesLanguageCorrection = true`,
- automatic language detection when `isAutomaticallyDetectLanguageEnabled` is true and macOS is 13+,
- custom words from the Custom Words preference,
- recognition languages from `RecognitionLanguage` when the revision supports it.

Debug strings:

- `This is our request custom words`
- `Current set of recognition Languages`
- `Is language correction turned on`

### 6.4 VisionKit path

The VisionKit path:

1. Loads the captured image.
2. Creates `ImageAnalyzer` configured for text.
3. Runs analysis.
4. Reads the transcript.
5. Replaces newline characters with spaces.
6. Copies, speaks, and scans the resulting text.

The VisionKit path appears to flatten line breaks regardless of `LineSettings`. Confirm this on macOS 14+ before treating “Keep Line Breaks” as universal.

### 6.5 Old Vision result path

The older path:

1. Runs the request.
2. Bridges `results` to `VNObservation`.
3. Keeps recognized-text observations.
4. If no observations exist, runs the no-text path.
5. Resets `textNoDetectedCount` to zero on success.
6. Builds recognized lines, including bounding-box geometry.
7. Produces line-break and no-line-break variants.
8. Chooses a variant using the capture mode and `LineSettings`.
9. Applies final text cleanup.
10. Copies the text to the pasteboard.
11. Runs TTS, link opening, and success feedback.

Debug string: `This is recognized line of Text`.

---

## 7. Text Post-Processing

### 7.1 Per-line replacements

`BIN 0x10001a184` builds recognized lines and applies six replacement pairs in order:

| From | To | Effect |
|---|---|---|
| `"-  "` | `""` | remove a leading hyphen followed by two spaces |
| `"- "` | `""` | remove a leading hyphen followed by one space |
| `"  "` | `" "` | collapse double spaces |
| `" -"` | `"-"` | remove a space before a hyphen |
| `"-\n"` | `"\n"` | remove a trailing hyphen before a newline |
| `"-"` | `"$#CLEAN_AFTER$#"` | protect a remaining hyphen from later cleanup |

The fourth and sixth pairs are part of a hyphen-protection scheme: the marker survives intermediate processing and is restored to `"-"` in final cleanup.

### 7.2 Final replacements

`BIN 0x10001dc0c` applies four replacement pairs to the final text:

| From | To | Notes |
|---|---|---|
| `"  "` | `" "` | collapse double spaces |
| `"-\n"` | `"\n"` | remove a trailing hyphen before a newline |
| `"support@textsnip"` | `""` | first 16 characters of `support@textsniper.app`; intent `UNKNOWN`, likely a bug |
| `"$#CLEAN_AFTER$#"` | `"-"` | restore protected hyphen |

Do not reproduce the `support@textsnip` replacement unless compatibility testing explicitly requires it. It can corrupt legitimate text containing that substring.

### 7.3 Line joining

The old Vision path has geometry-aware joining:

- Lines are grouped by vertical position.
- Lines in the same visual block can be joined with a space or newline.
- A boolean preference (`LineSettings`) selects the line-break-preserving variant.
- The no-line-break variant uses spaces.

The exact geometric thresholds are implementation details and need not match pixel-for-pixel. The observable requirement is that OCR of multi-line text produces either readable joined lines or preserved line breaks according to the preference.

---

## 8. Clipboard Behavior

### 8.1 Pasteboard type

The app writes `NSPasteboardTypeString` only. It clears the general pasteboard and declares that type before writing.

### 8.2 Additive Clipboard off

When `keepHistoryKey` is false:

- The recognized text replaces the pasteboard contents.
- No internal history is appended.
- `lastPasteboardChangeCount` is not updated by this branch.

### 8.3 Additive Clipboard on

When `keepHistoryKey` is true:

1. Read the current `clipboardKey` history string.
2. Append the new text, separated by two newline characters (`\n\n`).
3. Store the combined string back into `clipboardKey`.
4. Update `lastPasteboardChangeCount` to the pasteboard’s new change count.
5. Write the **entire combined history** to the pasteboard.

Consequences:

- Copying three snippets yields a pasteboard containing all three, oldest first.
- The user’s next paste may include prior captures, not only the latest.
- The history is stored in UserDefaults, not a dedicated database.

### 8.4 Clear Clipboard History

`clearHistoryAction:` sets `clipboardKey` to an empty string. It does not call `NSPasteboard clearContents`; the current system pasteboard is left intact. After clearing, the next additive capture starts a new history.

### 8.5 Pasteboard change count

`lastPasteboardChangeCount` is used to avoid reacting to the app’s own pasteboard writes. The global paste monitor compares the current change count with this stored value.

### 8.6 Privacy

`clipboardKey` can contain recognized text, including sensitive content, in plain-text preferences. SnippetFlow should document this clearly. Do not log or transmit clipboard contents.

---

## 9. Speech

### 9.1 Read recognized text aloud

If `textToSpeech` is true, the app speaks the recognized text after copying it.

Speech uses `NSSpeechSynthesizer` with rate from `ttsSpeedRate` (default 180).

### 9.2 One-shot TTS shortcut

`isTriggeredWithTexttoSpeechShortcut` forces speech for a single capture even when the `textToSpeech` preference is off. The flag is reset after use.

### 9.3 VoiceOver status announcements

Status phrases such as:

- `Text Copied to Clipboard`
- `No Text Detected`
- `Something went Wrong`

are announced only when VoiceOver is enabled. The app does not speak these status phrases to ordinary users who merely enabled text-to-speech.

### 9.4 Stop Speaking

`stopSpeakingAction:` stops the active synthesizer. Exact behavior when nothing is speaking is `UNKNOWN`.

---

## 10. Link Opening

If `isOpenLinksEnabled` is true, the app scans recognized text for URLs and opens detected links with `NSWorkspace`.

Requirements:

- Do not open arbitrary non-URL text.
- Use URL parsing rather than simple string prefix matching.
- Exact URL detection heuristics (one link vs multiple, `http`/`https` only, mail addresses) are `UNKNOWN`.

---

## 11. Success, Failure, and Notification Behavior

### 11.1 Successful capture

On success:

1. Copy text.
2. Speak text if enabled.
3. Open links if enabled.
4. If success notifications are not disabled, show/announce success.
5. If VoiceOver is enabled, announce `Text Copied to Clipboard`.
6. Show the in-app notification `Copied to Clipboard`.

The preference `DisableSuccessNotifications` suppresses the success feedback.

### 11.2 No text detected

When OCR produces no text:

- Speak/announce `No Text Detected` when appropriate.
- Increment `textNoDetectedCount`.
- If the count exceeds 1, call the secondary no-text handling path (`BIN 0x1000126d4`).
- Show the no-text notification.

The exact secondary behavior after repeated failures is `UNKNOWN`.

### 11.3 Errors

The app reports recognition errors with:

- `Something went Wrong`
- `Something went wrong: <error>`
- `Unable to perform requests`
- `This revision is not available`
- `Presetup of screen recognition has failed`

The exact alert layout and button labels are `UNKNOWN`.

### 11.4 Notification mechanism

Evidence points to an in-app menubar popover/HUD rather than `NSUserNotification` or `UNUserNotificationCenter`:

- `MenubarNotificationController.nib`
- `Copied to Clipboard`
- `No Text Detected`
- `Additive Clipboard Emptied`

SnippetFlow may use a small non-modal panel/popover. Exact animation, duration, and positioning are `UNKNOWN`.

---

## 12. Preferences

### 12.1 General

Visible labels and controls include:

- `Automatically Detect Language`
- `System:`
- `Launch at Login`
- `Show in Menu Bar`
- `Disable Sound Effects`
- `Disable Success Notification`
- `Automatically Open Links`
- `Title`
- `Recognition Language:`

Menu-bar visibility note:

`To restore menu bar icon relaunch TextSniper from Applications folder or Launchpad.`

### 12.2 Recognition languages

The language list includes:

- English
- French
- Italian
- German
- Spanish
- Portuguese
- Chinese Simplified
- Chinese Traditional

Additional languages may be present in the binary but not exposed in this nib. The full supported-language matrix is `UNKNOWN`.

### 12.3 Custom Words

The Custom Words screen contains:

- Placeholder: `Type custom words seperated by comma...` (original typo).
- Explanation beginning: `If the text you’re recognizing uses domain-specific jargon, such as medical or technical terms, you can tailor the language correction’s behavior by setting the Custom Words list. The words in the list takes precedence over the standard lexicon.`

Behavior:

- Split input on commas.
- Trim whitespace.
- Pass the resulting words to Vision’s custom-words API.
- Empty input should produce an empty list.

Exact handling of duplicates, empty entries, and multi-word phrases is `UNKNOWN`.

### 12.4 Shortcuts

Shortcut fields include:

- `captureTextShortcutField`
- `capturePreviousTextAreaShortcutField`
- `captureTextWithoutLineBreaksShortcutField`
- `captureTextWithLineBreaksShortcutField`
- `captureWithTextToSpeechShortcutField`
- `toggleAdditiveClipboardShortcutField`
- `clearAdditiveClipboardHistoryShortcutField`
- `stopSpeakingShortcutField`
- `barcodeShortcutField`

Obsolete or misspelled outlets:

- `additativeClipboardShortcutField`
- `captureTextModeSectionTitle`

Default shortcut records constructed at startup:

| Preference key | Key code | Modifiers | Default |
|---|---:|---|---|
| `textToSpeechShortcut` | 1 | Command | Command-S |
| `keepLineBrakesShortcut` | 37 | Command | Command-L |
| `keepHistoryShortcut` | 4 | Command | Command-H |
| `keyboardShortcut` | 19 | Command+Shift | Command-Shift-2 |

The reference app contained non-default shortcut overrides on the analysis system. Those values are environment-specific; treat only the records listed above as defaults and do not copy local overrides.

Whether every shortcut field is actively registered or only persisted in the UI is `UNKNOWN`. At minimum, the four names above are initialized by the app.

### 12.5 Launch at Login

Uses the bundled login helper. Toggling the checkbox should add/remove the helper from login items. Exact error handling for helper installation failure is `UNKNOWN`.

### 12.6 Sound

The UI exposes `Disable Sound Effects`. Internally the capture code reads a `Sound` value before deciding whether to pass `-x` to `screencapture`. The exact polarity between the UI checkbox and `Sound` is `UNKNOWN`.

---

## 13. Global Shortcuts and Paste Monitoring

### 13.1 Accessibility

The global key-down monitor is installed only when `AXIsProcessTrusted()` is true. Without Accessibility permission, global shortcuts do not work.

The app references:

- `TextSniper requires Accessibility permission`
- `x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility`

### 13.2 Paste monitor

The global monitor watches for Command-V and compares the pasteboard change count with `lastPasteboardChangeCount`.

When the user pastes after an additive capture:

- If additive clipboard is enabled, the app may clear history according to `IsAdditativeClipboardClearHistoryEnabled`.
- It may display `Additive Clipboard Emptied`.

The exact state machine and timing are `UNKNOWN`, but the requirement is that the app must not fight the user’s own pasteboard writes and must update its stored change count.

### 13.3 Keyboard shortcuts framework

The app uses `KeyboardShortcuts` records. SnippetFlow should use the same persistence format only if compatibility with existing user shortcuts is required; otherwise it can use its own shortcut recorder.

---

## 14. Persistence

### 14.1 UserDefaults keys

| Key | Type / meaning | Evidence |
|---|---|---|
| `clipboardKey` | String: additive clipboard history | BIN `0x100081ca0`; copy path |
| `keepHistoryKey` | Bool: additive clipboard enabled | BIN `0x100081ca8`; NIB binding |
| `textToSpeech` | Bool: speak recognized text | BIN `0x100081cb0`; NIB binding |
| `Permissions` | Stored permission state | BIN `0x100081cb8` |
| `LineSettings` | Bool: keep line breaks | BIN `0x100081cc0`; NIB binding |
| `isFirstTimeLaunch` | Bool: show onboarding | BIN `0x100081cc8` |
| `DisableSuccessNotifications` | Bool: suppress success feedback | BIN `0x100081cf0` |
| `PreviousCaptureAread` | Stored previous capture rectangle (typo original) | BIN `0x100081cf8` |
| `ttsSpeedRate` | Int: speech rate, default 180 | BIN `0x100081d00` |
| `IsAdditativeClipboardClearHistoryEnabled` | Bool: paste-monitor behavior | BIN `0x100081d08` |
| `lastPasteboardChangeCount` | Int: last seen pasteboard change count | BIN `0x100081d10` |
| `isMigrationDone` | Bool: defaults migration marker | BIN `0x100081d18` |
| `isOpenLinksEnabled` | Bool: open detected links | BIN `0x100081d20` |
| `isTriggeredWithTexttoSpeechShortcut` | Bool: one-shot TTS flag | BIN `0x100081d28` |
| `textNoDetectedCount` | Int: repeated no-text counter | BIN `0x100081d30` |
| `isAutomaticallyDetectLanguageEnabled` | Bool: auto language detection | preference key |
| `RecognitionLanguage` | String: selected language code | preference key |
| `visionRevisionVersionKey` | Int: Vision revision | preference key |
| `launchAtLogin` | Bool: login item preference | preference key |

The globals listed above live in `__common` (BSS) and are zero on disk. Their key strings are assembled by initializers; do not try to read them as static data at `0x100081...`.

### 14.2 Preference-state caveat

The reference preferences were inspected on a single analysis system and may contain environment-specific licensing and clipboard values. Do not use Paddle/license values or stored clipboard content as product requirements, and do not reproduce them in derived projects.

### 14.3 Application Support

`~/Library/Application Support/TextSniper/` contains Paddle files:

- `618662.padl`
- `com.valerijs.boguckis.TextSniper.ipak`

SnippetFlow, using a different licensing system, should not create these files.

### 14.4 Updates

Use Sparkle with the feed URL and public key above if compatibility with the original update channel is required. Otherwise use an independent update mechanism.

---

## 15. Permissions and System Integration

| Capability | Requirement |
|---|---|
| Screen capture | Screen Recording permission |
| Global shortcuts / paste monitoring | Accessibility permission |
| Login item | Login helper bundle |
| Screen capture IPC | `com.apple.screencapture.interactive` Mach service exception |
| Camera / microphone | Not required; no entitlements |
| App Sandbox | Disabled |
| Continuity Camera | System “Take Photo” import item |

The app links CoreGraphics preflight/request APIs:

- `CGPreflightScreenCaptureAccess`
- `CGRequestScreenCaptureAccess`

The permission alert should link to the relevant Privacy pane. Exact prompt order (preflight vs system prompt vs custom alert) is `UNKNOWN`.

`WrapperController` conforms to `NSServicesMenuRequestor`; whether the app registers a Services provider at runtime is `UNKNOWN`.

---

## 16. Error and Status Strings

Use these exact strings where user-visible compatibility matters:

| String | Context |
|---|---|
| `No Text Detected` | OCR returned nothing |
| `No Data Detected` | Barcode/QR returned nothing |
| `Something went Wrong` | Generic recognition failure, spoken/announced |
| `Something went wrong: ` | Error alert prefix |
| `Unable to perform requests` | Vision request failure |
| `This revision is not available` | Unsupported Vision revision |
| `Presetup of screen recognition has failed` | OCR preflight failure |
| `Current extension` | Debug/error context |
| `Some error occured` | Generic error (original typo) |
| `Error - Application Support directory couldn't be created` | Paddle/storage setup |
| `Error couldn't be delete` | File deletion failure |
| `File has been deleted` | Cleanup message |
| `This is captures URL:` | Debug URL message |
| `Text Copied to Clipboard` | VoiceOver success announcement |
| `Copied to Clipboard` | Visual success notification |
| `Additive Clipboard Emptied` | Paste-monitor notification |
| `TextSniper requires Accessibility permission` | Accessibility denial |

Paddle-specific deactivation, support, and license strings are out of scope unless licensing compatibility is required.

---

## 17. Non-Goals and Open Questions

### 17.1 Non-goals

- Copying the TextSniper icon, artwork, fonts, colors, or exact window chrome.
- Reimplementing Paddle’s proprietary licensing protocol.
- Matching Vision’s internal OCR output byte-for-byte.
- Reproducing the `support@textsnip` corruption bug unless a compatibility test demands it.
- Recreating the original Sparkle feed or signing keys.

### 17.2 Open questions

1. Exact status-item menu wiring and whether it reuses `_NSMainMenu`.
2. Exact behavior of the six empty menu items versus standard separators.
3. Exact `Sound` ↔ `Disable Sound Effects` polarity and whether `-x` mutes capture sound.
4. Full supported-language list beyond the visible eight.
5. Barcode symbologies, payload handling, and result presentation.
6. Exact URL-detection heuristic.
7. Exact no-text secondary path after `textNoDetectedCount > 1`.
8. Exact success-notification UI, duration, and positioning.
9. Whether all shortcut preference fields are actively registered.
10. Services registration and Continuity Camera IPC details.
11. Exact screen-recording permission prompt order and button labels.
12. Whether the VisionKit path truly ignores `LineSettings`.
13. Exact `support@textsnip` replacement intent.
14. Paddle behavior under nonstandard license state.

---

## 18. Acceptance Criteria

SnippetFlow is behaviorally acceptable when:

1. It launches as a menu-bar-only agent with no Dock icon.
2. The menu contains the exact items and order in §4.2.
3. The three bound toggles control `LineSettings`, `keepHistoryKey`, and `textToSpeech`.
4. “Capture Text” opens interactive region selection and copies recognized text.
5. “Read QR/Bar Code” captures and decodes a code.
6. “Clear Clipboard History” empties the internal history without necessarily clearing the current pasteboard.
7. Additive Clipboard off: pasteboard contains only the latest capture.
8. Additive Clipboard on: pasteboard contains prior captures joined by two newlines.
9. “Keep Line Breaks” changes multi-line output between line-preserving and space-joined forms (except possibly the VisionKit CJK path).
10. “Text to Speech” speaks recognized text at `ttsSpeedRate`.
11. “Stop Speaking” stops active speech.
12. “Automatically Open Links” opens valid URLs found in recognized text.
13. First launch shows the onboarding popover with the exact copy in §3.2.
14. Without Screen Recording permission, capture is blocked and the user is directed to the correct Privacy pane.
15. Without Accessibility permission, global shortcuts are inactive.
16. OCR failure produces the correct no-text or error feedback.
17. No recognized text or clipboard contents are logged or transmitted.
18. The app does not copy TextSniper’s proprietary assets or code.

---

## Appendix A: Key Binary Evidence

| Address | Meaning |
|---|---|
| `0x10000b630` | Startup: licensing, menu setup, key monitor, onboarding |
| `0x10000c594` | `captureTextAction:` |
| `0x10000c63c` | `captureBarcode:` |
| `0x10000c7e0` | `clearHistoryAction:`; empties `clipboardKey` |
| `0x10000c748` | `stopSpeakingAction:` |
| `0x10000c904` | `showPreferences:` |
| `0x10000c6fc` | `changeShortcutAction:` |
| `0x10000c89c` | `runWelcomeScreen:` |
| `0x10000c544` | `launchAtLoginAction:` |
| `0x100007d14` | Vision request configuration |
| `0x10001fb94` | OCR backend selection and result handling |
| `0x10001a010` | `Array.contains` for language gate |
| `0x100020024` | Old Vision path |
| `0x10001fe5c` | VisionKit `ImageAnalyzer` path |
| `0x10001f49c` | Old Vision result completion |
| `0x10001a184` | Recognized-line construction and six replacements |
| `0x10001b010` | Geometry-aware line joining / two variants |
| `0x10001dc0c` | Final text cleanup; four replacements |
| `0x1000190a8` | Append text to additive history with `\n\n` |
| `0x100019214` | Pasteboard copy and history selection |
| `0x1000194c8` | Speak recognized text |
| `0x1000196c4` | VoiceOver-only status announcement |
| `0x10001ee34` | Open detected links |
| `0x10001287c` | No-text handling |
| `0x10000a5b4` | Async notification/UI dispatcher |
| `0x100020920` | `ScreenCapturer` init |
| `0x100020bbc` | `ScreenCapturer.capture` |
| `0x100019834` | Default shortcut registration |
| `0x1000408a0` / `0x100040c44` | Global shortcut handler setup |

## Appendix B: NIB Evidence

- `MainMenu.nib` objects 120-124: Text to Speech binding.
- `MainMenu.nib` objects 125-127: Keep Line Breaks binding.
- `MainMenu.nib` objects 128-130: Additive Clipboard binding.
- `MainMenu.nib` item 79: Quit, Command-Q.
- `MainMenu.nib` item 61: `NSMenuItemImportFromDeviceIdentifier`.
- `GeneralPreferenceViewController.nib`: labels, outlets, language list, support link.
- `ShortcutPreferenceViewController.nib`: shortcut fields and section title.
- `CustomWordsViewController.nib`: custom-words placeholder and explanation.
- `MenubarNotificationController.nib`: onboarding popover strings.

## Appendix C: Verification Commands

These commands were used to derive the evidence:

```sh
lipo -thin arm64 TextSniper -output /tmp/ts-rea/TextSniper-arm64
otool -tV /tmp/ts-rea/TextSniper-arm64 > /tmp/ts-rea/disasm.txt
otool -oV /tmp/ts-rea/TextSniper-arm64 > /tmp/ts-rea/objc.txt
strings -a /tmp/ts-rea/TextSniper-arm64 > /tmp/ts-rea/strings.txt
python3 -m pip install nibarchive
```

Parsing a compiled nib:

```python
import nibarchive
path = "/Applications/TextSniper.app/Contents/Resources/Base.lproj/Main.storyboardc/MainMenu.nib"
archive = nibarchive.NIBArchiveParser().parse(open(path, "rb"))
```

Do not use `ibtool` on the compiled nib; it rejects compiled nibs.
