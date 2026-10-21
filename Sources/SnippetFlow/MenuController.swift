import AppKit

@MainActor
final class MenuController: NSObject, NSMenuDelegate {
    var onCaptureText: (@MainActor () -> Void)?
    var onCaptureBarcode: (@MainActor () -> Void)?
    var onTakePhoto: (@MainActor () -> Void)?
    var onShowPreferences: (@MainActor () -> Void)?
    var onClearHistory: (@MainActor () -> Void)?
    var onStopSpeaking: (@MainActor () -> Void)?

    let menu = NSMenu()
    private var lineBreaksItem: NSMenuItem?
    private var additiveItem: NSMenuItem?
    private var ttsItem: NSMenuItem?

    override init() {
        super.init()
        buildMenu()
    }

    func install(on statusItem: NSStatusItem) {
        statusItem.menu = menu
    }

    func refresh() {
        lineBreaksItem?.state = Preferences.shared.lineSettings ? .on : .off
        additiveItem?.state = Preferences.shared.keepHistory ? .on : .off
        ttsItem?.state = Preferences.shared.textToSpeech ? .on : .off
    }

    func menuWillOpen(_ menu: NSMenu) {
        refresh()
    }

    private func buildMenu() {
        menu.title = "SnippetFlow"
        menu.delegate = self

        add("Capture Text", action: #selector(captureText))
        add("Read QR/Bar Code", action: #selector(captureBarcode))
        addTakePhoto()
        menu.addItem(.separator())

        let lineBreaks = add("Keep Line Breaks", action: #selector(toggleLineBreaks))
        lineBreaksItem = lineBreaks
        menu.addItem(.separator())

        let additive = add("Additive Clipboard", action: #selector(toggleAdditive))
        additiveItem = additive
        add("Clear Clipboard History", action: #selector(clearHistory))
        menu.addItem(.separator())

        let tts = add("Text to Speech", action: #selector(toggleTTS))
        ttsItem = tts
        add("Stop Speaking", action: #selector(stopSpeaking))
        menu.addItem(.separator())

        add("Preferences...", action: #selector(showPreferences))
        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit SnippetFlow", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.keyEquivalentModifierMask = [.command]
        quit.target = NSApp
        menu.addItem(quit)

        refresh()
    }

    @discardableResult
    private func add(_ title: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        menu.addItem(item)
        return item
    }

    private func addTakePhoto() {
        let item = NSMenuItem(title: "Take Photo", action: #selector(takePhoto), keyEquivalent: "")
        item.target = self
        item.identifier = NSMenuItem.importFromDeviceIdentifier
        item.toolTip = "Click Right Mouse to Import From Iphone"
        menu.addItem(item)
    }

    @objc private func captureText() {
        onCaptureText?()
    }

    @objc private func captureBarcode() {
        onCaptureBarcode?()
    }

    @objc private func takePhoto() {
        onTakePhoto?()
    }

    @objc private func toggleLineBreaks() {
        Preferences.shared.lineSettings.toggle()
        refresh()
    }

    @objc private func toggleAdditive() {
        Preferences.shared.keepHistory.toggle()
        refresh()
    }

    @objc private func toggleTTS() {
        Preferences.shared.textToSpeech.toggle()
        refresh()
    }

    @objc private func clearHistory() {
        onClearHistory?()
    }

    @objc private func stopSpeaking() {
        onStopSpeaking?()
    }

    @objc private func showPreferences() {
        onShowPreferences?()
    }
}
