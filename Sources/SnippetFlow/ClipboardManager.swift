import AppKit

final class ClipboardManager {
    static let shared = ClipboardManager()
    private let preferences = Preferences.shared

    private init() {}

    func copy(_ text: String) {
        guard !text.isEmpty else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.declareTypes([.string], owner: nil)

        if preferences.keepHistory {
            let existing = preferences.clipboard
            let output = existing.isEmpty ? text : existing + "\n\n" + text
            preferences.clipboard = output
            pasteboard.setString(output, forType: .string)
            preferences.lastPasteboardChangeCount = pasteboard.changeCount
        } else {
            pasteboard.setString(text, forType: .string)
        }
    }

    func clearHistory() {
        preferences.clipboard = ""
    }

    func copyBarcode(_ text: String) {
        guard !text.isEmpty else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(text, forType: .string)
        preferences.lastPasteboardChangeCount = pasteboard.changeCount
    }
}
