import AppKit
import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gearshape") }
            ShortcutsSettingsView()
                .tabItem { Label("Shortcuts", systemImage: "command") }
            CustomWordsSettingsView()
                .tabItem { Label("Custom Words", systemImage: "text.badge.plus") }
            AboutSettingsView()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .padding(16)
        .frame(width: 620, height: 560)
    }
}

private struct GeneralSettingsView: View {
    @AppStorage(PrefKey.autoDetectLanguage) private var autoDetect = true
    @AppStorage(PrefKey.recognitionLanguage) private var language = "en-US"
    @AppStorage(PrefKey.lineSettings) private var keepLineBreaks = false
    @AppStorage(PrefKey.textToSpeech) private var textToSpeech = false
    @AppStorage(PrefKey.openLinks) private var openLinks = false
    @AppStorage(PrefKey.disableSuccessNotifications) private var disableSuccess = false
    @AppStorage(PrefKey.disableSound) private var disableSound = true
    @AppStorage(PrefKey.ttsSpeedRate) private var ttsRate = 180
    @AppStorage(PrefKey.showInMenuBar) private var showInMenuBar = true

    @State private var launchAtLogin = LaunchAtLogin.isEnabled
    @State private var loginError: String?

    private let languages: [(String, String)] = [
        ("English", "en-US"),
        ("French", "fr-FR"),
        ("Italian", "it-IT"),
        ("German", "de-DE"),
        ("Spanish", "es-ES"),
        ("Portuguese", "pt-BR"),
        ("Chinese Simplified", "zh-Hans"),
        ("Chinese Traditional", "zh-Hant"),
        ("Japanese", "ja-JP"),
        ("Korean", "ko-KR")
    ]

    var body: some View {
        Form {
            Section {
                Toggle("Automatically Detect Language", isOn: $autoDetect)
                Picker("Recognition Language:", selection: $language) {
                    ForEach(languages, id: \.1) { item in
                        Text(item.0).tag(item.1)
                    }
                }
                .disabled(autoDetect)
                Text("System: \(Locale.current.localizedString(forIdentifier: Locale.current.identifier) ?? Locale.current.identifier)")
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle("Keep Line Breaks", isOn: $keepLineBreaks)
                Toggle("Text to Speech", isOn: $textToSpeech)
                HStack {
                    Text("Speech Rate")
                    Slider(value: Binding(
                        get: { Double(ttsRate) },
                        set: { ttsRate = Int($0) }
                    ), in: 100...400, step: 5)
                    Text("\(ttsRate)")
                        .monospacedDigit()
                        .frame(width: 34, alignment: .trailing)
                }
                .disabled(!textToSpeech)
                Toggle("Automatically Open Links", isOn: $openLinks)
            }

            Section {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newValue in
                        setLaunchAtLogin(newValue)
                    }
                Toggle("Show in Menu Bar", isOn: $showInMenuBar)
                Toggle("Disable Sound Effects", isOn: $disableSound)
                Toggle("Disable Success Notification", isOn: $disableSuccess)
            }

            Section {
                HStack {
                    Image(systemName: PermissionManager.shared.hasScreenRecordingPermission ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(PermissionManager.shared.hasScreenRecordingPermission ? .green : .orange)
                    Text("Screen Recording")
                    Spacer()
                    Button("Open Settings") {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
                HStack {
                    Image(systemName: PermissionManager.shared.hasAccessibilityPermission ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(PermissionManager.shared.hasAccessibilityPermission ? .green : .orange)
                    Text("Accessibility")
                    Spacer()
                    Button("Request") {
                        PermissionManager.shared.requestAccessibilityPermission()
                    }
                }
            } header: {
                Text("Permissions")
            }

            if let loginError {
                Text(loginError)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            Text("To restore the menu bar icon after disabling it, relaunch SnippetFlow from Applications or Launchpad.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
        .onAppear {
            launchAtLogin = LaunchAtLogin.isEnabled
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try LaunchAtLogin.setEnabled(enabled)
            Preferences.shared.launchAtLogin = enabled
            loginError = nil
        } catch {
            loginError = error.localizedDescription
            launchAtLogin = LaunchAtLogin.isEnabled
        }
    }
}

private struct ShortcutsSettingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Global Shortcuts")
                    .font(.headline)
                Text("Click a shortcut, then press the new key combination. Press Escape to cancel.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(ShortcutAction.allCases, id: \.self) { action in
                    HStack {
                        Text(action.title)
                        Spacer()
                        ShortcutRecorder(action: action)
                    }
                    Divider()
                }

                Text("Shortcuts require Accessibility permission for reliable global operation.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
}

private struct ShortcutRecorder: View {
    let action: ShortcutAction
    @StateObject private var model: ShortcutRecorderModel

    init(action: ShortcutAction) {
        self.action = action
        _model = StateObject(wrappedValue: ShortcutRecorderModel(action: action))
    }

    var body: some View {
        HStack(spacing: 8) {
            Button {
                model.toggle()
            } label: {
                Text(model.isRecording ? "Press shortcut…" : model.shortcut.display)
                    .frame(minWidth: 110)
                    .monospaced()
            }
            .buttonStyle(.bordered)

            Button {
                model.clear()
            } label: {
                Image(systemName: "xmark.circle")
            }
            .buttonStyle(.borderless)
            .help("Clear shortcut")
        }
        .onDisappear { model.stop() }
    }
}

final class ShortcutRecorderModel: ObservableObject {
    @Published var shortcut: Shortcut
    @Published var isRecording = false

    private let action: ShortcutAction
    private var monitor: Any?

    init(action: ShortcutAction) {
        self.action = action
        self.shortcut = ShortcutStore.shortcut(for: action)
    }

    func toggle() {
        if isRecording {
            stop()
        } else {
            begin()
        }
    }

    func begin() {
        stop()
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            if event.keyCode == 53 {
                self.stop()
                return nil
            }

            let modifiers = ShortcutFormatter.carbonModifiers(from: event.modifierFlags)
            guard modifiers != 0 || ShortcutFormatter.isFunctionKey(event.keyCode) else { return nil }

            let value = Shortcut(keyCode: UInt32(event.keyCode), modifiers: modifiers)
            self.shortcut = value
            ShortcutStore.set(value, for: self.action)
            self.stop()
            return nil
        }
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
        isRecording = false
    }

    func clear() {
        stop()
        ShortcutStore.set(nil, for: action)
        shortcut = ShortcutStore.shortcut(for: action)
    }
}

private struct CustomWordsSettingsView: View {
    @AppStorage(PrefKey.customWords) private var customWords = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Custom Words")
                .font(.headline)
            Text("If the text you’re recognizing uses domain-specific jargon, such as medical or technical terms, you can tailor the language correction’s behavior by setting the Custom Words list. The words in the list takes precedence over the standard lexicon.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            TextEditor(text: $customWords)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 260)
                .overlay(alignment: .topLeading) {
                    if customWords.isEmpty {
                        Text("Bluebird\nLumen-42\nProject Atlas")
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.tertiary)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.quaternary)
                }

            Text("Separate words with commas.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

private struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .interpolation(.high)
                .frame(width: 84, height: 84)
            Text("SnippetFlow")
                .font(.title2.weight(.semibold))
            Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")")
                .foregroundStyle(.secondary)
            Text("An open-source menu-bar OCR utility for macOS.")
                .foregroundStyle(.secondary)
            Text("Independent project. Not affiliated with TextSniper.")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
    }
}

final class SettingsWindowController: NSWindowController {
    init() {
        let hosting = NSHostingController(rootView: SettingsView())
        let window = NSWindow(contentViewController: hosting)
        window.title = "SnippetFlow Settings"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 620, height: 560))
        window.center()
        window.isReleasedWhenClosed = false
        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
