import AppKit
import ApplicationServices

@MainActor
final class PasteMonitor {
    private var monitor: Any?
    private var lastClearedChangeCount = -1
    private let preferences = Preferences.shared

    var isRunning: Bool { monitor != nil }

    func start() -> Bool {
        guard AXIsProcessTrusted() else {
            stop()
            return false
        }
        guard monitor == nil else { return true }

        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            Task { @MainActor in
                guard let self else { return }
                let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                guard flags.contains(.command) else { return }
                guard event.charactersIgnoringModifiers?.lowercased() == "v" else { return }
                guard self.preferences.keepHistory else { return }
                guard self.preferences.additiveClearHistory else { return }

                let pasteboard = NSPasteboard.general
                guard pasteboard.changeCount == self.preferences.lastPasteboardChangeCount else { return }
                guard pasteboard.changeCount != self.lastClearedChangeCount else { return }

                self.lastClearedChangeCount = pasteboard.changeCount
                ClipboardManager.shared.clearHistory()
                NotificationPresenter.shared.show("Additive Clipboard Emptied", force: true)
            }
        }
        return true
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }
}
