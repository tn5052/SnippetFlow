import AppKit
import ApplicationServices
import CoreGraphics

@MainActor
final class PermissionManager {
    static let shared = PermissionManager()

    private init() {}

    var hasScreenRecordingPermission: Bool {
        CGPreflightScreenCaptureAccess()
    }

    var hasAccessibilityPermission: Bool {
        AXIsProcessTrusted()
    }

    func ensureScreenRecordingPermission() -> Bool {
        if CGPreflightScreenCaptureAccess() {
            return true
        }

        _ = CGRequestScreenCaptureAccess()

        if CGPreflightScreenCaptureAccess() {
            return true
        }

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Screen Recording Permission Required"
        alert.informativeText = "SnippetFlow needs Screen Recording permission to capture text. Open System Settings, enable SnippetFlow under Privacy & Security > Screen Recording, then relaunch the app."
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                NSWorkspace.shared.open(url)
            }
        }
        return false
    }

    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "SnippetFlow requires Accessibility permission for global paste monitoring. Enable it in Privacy & Security > Accessibility."
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            openAccessibilitySettings()
        }
    }
}
