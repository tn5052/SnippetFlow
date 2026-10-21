import Foundation

enum PrefKey {
    static let clipboard = "clipboardKey"
    static let keepHistory = "keepHistoryKey"
    static let textToSpeech = "textToSpeech"
    static let permissions = "Permissions"
    static let lineSettings = "LineSettings"
    static let firstLaunch = "isFirstTimeLaunch"
    static let disableSuccessNotifications = "DisableSuccessNotifications"
    static let previousCaptureArea = "PreviousCaptureAread"
    static let ttsSpeedRate = "ttsSpeedRate"
    static let additiveClearHistory = "IsAdditativeClipboardClearHistoryEnabled"
    static let lastPasteboardChangeCount = "lastPasteboardChangeCount"
    static let migrationDone = "isMigrationDone"
    static let openLinks = "isOpenLinksEnabled"
    static let triggeredTTS = "isTriggeredWithTexttoSpeechShortcut"
    static let noTextCount = "textNoDetectedCount"
    static let autoDetectLanguage = "isAutomaticallyDetectLanguageEnabled"
    static let recognitionLanguage = "RecognitionLanguage"
    static let visionRevision = "visionRevisionVersionKey"
    static let launchAtLogin = "launchAtLogin"
    static let customWords = "customWords"
    static let disableSound = "DisableSoundEffects"
    static let showInMenuBar = "showInMenuBar"
}

extension Notification.Name {
    static let preferencesChanged = Notification.Name("SnippetFlow.preferencesChanged")
    static let shortcutsChanged = Notification.Name("SnippetFlow.shortcutsChanged")
    static let menuBarVisibilityChanged = Notification.Name("SnippetFlow.menuBarVisibilityChanged")
}

final class Preferences {
    static let shared = Preferences()

    private let defaults = UserDefaults.standard

    private init() {
        defaults.register(defaults: [
            PrefKey.recognitionLanguage: "en-US",
            PrefKey.autoDetectLanguage: true,
            PrefKey.lineSettings: false,
            PrefKey.keepHistory: false,
            PrefKey.textToSpeech: false,
            PrefKey.openLinks: false,
            PrefKey.disableSuccessNotifications: false,
            PrefKey.disableSound: true,
            PrefKey.ttsSpeedRate: 180,
            PrefKey.additiveClearHistory: false,
            PrefKey.lastPasteboardChangeCount: 0,
            PrefKey.migrationDone: true,
            PrefKey.triggeredTTS: false,
            PrefKey.noTextCount: 0,
            PrefKey.visionRevision: 0,
            PrefKey.launchAtLogin: false,
            PrefKey.customWords: "",
            PrefKey.showInMenuBar: true,
            PrefKey.permissions: ""
        ])

        if defaults.object(forKey: PrefKey.firstLaunch) == nil {
            defaults.set(true, forKey: PrefKey.firstLaunch)
        }
    }

    var clipboard: String {
        get { defaults.string(forKey: PrefKey.clipboard) ?? "" }
        set { defaults.set(newValue, forKey: PrefKey.clipboard) }
    }

    var keepHistory: Bool {
        get { defaults.bool(forKey: PrefKey.keepHistory) }
        set { defaults.set(newValue, forKey: PrefKey.keepHistory); changed() }
    }

    var textToSpeech: Bool {
        get { defaults.bool(forKey: PrefKey.textToSpeech) }
        set { defaults.set(newValue, forKey: PrefKey.textToSpeech); changed() }
    }

    var lineSettings: Bool {
        get { defaults.bool(forKey: PrefKey.lineSettings) }
        set { defaults.set(newValue, forKey: PrefKey.lineSettings); changed() }
    }

    var firstLaunch: Bool {
        get { defaults.bool(forKey: PrefKey.firstLaunch) }
        set { defaults.set(newValue, forKey: PrefKey.firstLaunch) }
    }

    var disableSuccessNotifications: Bool {
        get { defaults.bool(forKey: PrefKey.disableSuccessNotifications) }
        set { defaults.set(newValue, forKey: PrefKey.disableSuccessNotifications); changed() }
    }

    var ttsSpeedRate: Int {
        get { defaults.integer(forKey: PrefKey.ttsSpeedRate) }
        set { defaults.set(newValue, forKey: PrefKey.ttsSpeedRate) }
    }

    var additiveClearHistory: Bool {
        get { defaults.bool(forKey: PrefKey.additiveClearHistory) }
        set { defaults.set(newValue, forKey: PrefKey.additiveClearHistory) }
    }

    var lastPasteboardChangeCount: Int {
        get { defaults.integer(forKey: PrefKey.lastPasteboardChangeCount) }
        set { defaults.set(newValue, forKey: PrefKey.lastPasteboardChangeCount) }
    }

    var openLinks: Bool {
        get { defaults.bool(forKey: PrefKey.openLinks) }
        set { defaults.set(newValue, forKey: PrefKey.openLinks); changed() }
    }

    var triggeredTTS: Bool {
        get { defaults.bool(forKey: PrefKey.triggeredTTS) }
        set { defaults.set(newValue, forKey: PrefKey.triggeredTTS) }
    }

    var noTextCount: Int {
        get { defaults.integer(forKey: PrefKey.noTextCount) }
        set { defaults.set(newValue, forKey: PrefKey.noTextCount) }
    }

    var autoDetectLanguage: Bool {
        get { defaults.bool(forKey: PrefKey.autoDetectLanguage) }
        set { defaults.set(newValue, forKey: PrefKey.autoDetectLanguage); changed() }
    }

    var recognitionLanguage: String {
        get { defaults.string(forKey: PrefKey.recognitionLanguage) ?? "en-US" }
        set { defaults.set(newValue, forKey: PrefKey.recognitionLanguage); changed() }
    }

    var customWords: String {
        get { defaults.string(forKey: PrefKey.customWords) ?? "" }
        set { defaults.set(newValue, forKey: PrefKey.customWords); changed() }
    }

    var disableSound: Bool {
        get { defaults.bool(forKey: PrefKey.disableSound) }
        set { defaults.set(newValue, forKey: PrefKey.disableSound) }
    }

    var showInMenuBar: Bool {
        get { defaults.bool(forKey: PrefKey.showInMenuBar) }
        set { defaults.set(newValue, forKey: PrefKey.showInMenuBar); changed() }
    }

    var launchAtLogin: Bool {
        get { defaults.bool(forKey: PrefKey.launchAtLogin) }
        set { defaults.set(newValue, forKey: PrefKey.launchAtLogin) }
    }

    var previousCaptureArea: CGRect? {
        get {
            guard let raw = defaults.string(forKey: PrefKey.previousCaptureArea) else { return nil }
            let parts = raw.split(separator: ",").compactMap { Double($0) }
            guard parts.count == 4 else { return nil }
            return CGRect(x: parts[0], y: parts[1], width: parts[2], height: parts[3])
        }
        set {
            if let r = newValue {
                defaults.set("\(r.origin.x),\(r.origin.y),\(r.size.width),\(r.size.height)", forKey: PrefKey.previousCaptureArea)
            } else {
                defaults.removeObject(forKey: PrefKey.previousCaptureArea)
            }
        }
    }

    var customWordList: [String] {
        customWords
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    func synchronize() {
        defaults.synchronize()
    }

    private func changed() {
        NotificationCenter.default.post(name: .preferencesChanged, object: nil)
    }
}
