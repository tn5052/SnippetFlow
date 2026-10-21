import AppKit
import ApplicationServices
import Carbon
import Foundation

struct Shortcut: Equatable {
    var keyCode: UInt32
    var modifiers: UInt32

    var display: String {
        ShortcutFormatter.string(keyCode: keyCode, modifiers: modifiers)
    }
}

enum ShortcutAction: String, CaseIterable {
    case captureText
    case capturePreviousArea
    case captureWithoutLineBreaks
    case captureWithLineBreaks
    case textToSpeech
    case toggleLineBreaks
    case toggleAdditiveClipboard
    case clearHistory
    case stopSpeaking
    case barcode

    var title: String {
        switch self {
        case .captureText: return "Capture Text"
        case .capturePreviousArea: return "Capture Previous Area"
        case .captureWithoutLineBreaks: return "Capture Without Line Breaks"
        case .captureWithLineBreaks: return "Capture With Line Breaks"
        case .textToSpeech: return "Capture With Text to Speech"
        case .toggleLineBreaks: return "Toggle Keep Line Breaks"
        case .toggleAdditiveClipboard: return "Toggle Additive Clipboard"
        case .clearHistory: return "Clear Clipboard History"
        case .stopSpeaking: return "Stop Speaking"
        case .barcode: return "Read QR/Bar Code"
        }
    }

    var preferenceKey: String {
        switch self {
        case .captureText: return "keyboardShortcut"
        case .capturePreviousArea: return "capturePreviousTextAreaShortcut"
        case .captureWithoutLineBreaks: return "captureTextWithoutLineBreaksShortcut"
        case .captureWithLineBreaks: return "captureTextWithLineBreaksShortcut"
        case .textToSpeech: return "textToSpeechShortcut"
        case .toggleLineBreaks: return "keepLineBrakesShortcut"
        case .toggleAdditiveClipboard: return "keepHistoryShortcut"
        case .clearHistory: return "clearAdditiveClipboardHistoryShortcut"
        case .stopSpeaking: return "stopSpeakingShortcut"
        case .barcode: return "barcodeShortcut"
        }
    }

    var defaultShortcut: Shortcut? {
        switch self {
        case .captureText:
            return Shortcut(keyCode: UInt32(kVK_ANSI_2), modifiers: UInt32(cmdKey | shiftKey))
        case .capturePreviousArea:
            return nil
        case .captureWithoutLineBreaks:
            return nil
        case .captureWithLineBreaks:
            return nil
        case .textToSpeech:
            return Shortcut(keyCode: UInt32(kVK_ANSI_S), modifiers: UInt32(cmdKey | optionKey | shiftKey))
        case .toggleLineBreaks:
            return Shortcut(keyCode: UInt32(kVK_ANSI_L), modifiers: UInt32(cmdKey | optionKey | shiftKey))
        case .toggleAdditiveClipboard:
            return Shortcut(keyCode: UInt32(kVK_ANSI_H), modifiers: UInt32(cmdKey | optionKey | shiftKey))
        case .clearHistory:
            return nil
        case .stopSpeaking:
            return nil
        case .barcode:
            return nil
        }
    }

    var storageKey: String { "KeyboardShortcuts_\(preferenceKey)" }
}

enum ShortcutStore {
    static func shortcut(for action: ShortcutAction) -> Shortcut {
        guard let value = UserDefaults.standard.dictionary(forKey: action.storageKey),
              let keyCode = value["carbonKeyCode"] as? Int,
              let modifiers = value["carbonModifiers"] as? Int else {
            return action.defaultShortcut ?? Shortcut(keyCode: 0, modifiers: 0)
        }
        return Shortcut(keyCode: UInt32(keyCode), modifiers: UInt32(modifiers))
    }

    static func set(_ shortcut: Shortcut?, for action: ShortcutAction) {
        let value = shortcut ?? Shortcut(keyCode: 0, modifiers: 0)
        UserDefaults.standard.set(
            ["carbonKeyCode": Int(value.keyCode), "carbonModifiers": Int(value.modifiers)],
            forKey: action.storageKey
        )
        NotificationCenter.default.post(name: .shortcutsChanged, object: nil)
    }
}

enum ShortcutFormatter {
    static func string(keyCode: UInt32, modifiers: UInt32) -> String {
        if keyCode == 0 && modifiers == 0 {
            return "None"
        }
        var value = ""
        if modifiers & UInt32(controlKey) != 0 { value += "⌃" }
        if modifiers & UInt32(optionKey) != 0 { value += "⌥" }
        if modifiers & UInt32(shiftKey) != 0 { value += "⇧" }
        if modifiers & UInt32(cmdKey) != 0 { value += "⌘" }
        value += keyName(for: keyCode)
        return value
    }

    static func keyName(for keyCode: UInt32) -> String {
        switch Int(keyCode) {
        case kVK_ANSI_A: return "A"
        case kVK_ANSI_B: return "B"
        case kVK_ANSI_C: return "C"
        case kVK_ANSI_D: return "D"
        case kVK_ANSI_E: return "E"
        case kVK_ANSI_F: return "F"
        case kVK_ANSI_G: return "G"
        case kVK_ANSI_H: return "H"
        case kVK_ANSI_I: return "I"
        case kVK_ANSI_J: return "J"
        case kVK_ANSI_K: return "K"
        case kVK_ANSI_L: return "L"
        case kVK_ANSI_M: return "M"
        case kVK_ANSI_N: return "N"
        case kVK_ANSI_O: return "O"
        case kVK_ANSI_P: return "P"
        case kVK_ANSI_Q: return "Q"
        case kVK_ANSI_R: return "R"
        case kVK_ANSI_S: return "S"
        case kVK_ANSI_T: return "T"
        case kVK_ANSI_U: return "U"
        case kVK_ANSI_V: return "V"
        case kVK_ANSI_W: return "W"
        case kVK_ANSI_X: return "X"
        case kVK_ANSI_Y: return "Y"
        case kVK_ANSI_Z: return "Z"
        case kVK_ANSI_0: return "0"
        case kVK_ANSI_1: return "1"
        case kVK_ANSI_2: return "2"
        case kVK_ANSI_3: return "3"
        case kVK_ANSI_4: return "4"
        case kVK_ANSI_5: return "5"
        case kVK_ANSI_6: return "6"
        case kVK_ANSI_7: return "7"
        case kVK_ANSI_8: return "8"
        case kVK_ANSI_9: return "9"
        case kVK_ANSI_Period: return "."
        case kVK_ANSI_Comma: return ","
        case kVK_ANSI_Slash: return "/"
        case kVK_ANSI_Backslash: return "\\"
        case kVK_ANSI_Semicolon: return ";"
        case kVK_ANSI_Quote: return "'"
        case kVK_ANSI_LeftBracket: return "["
        case kVK_ANSI_RightBracket: return "]"
        case kVK_ANSI_Minus: return "-"
        case kVK_ANSI_Equal: return "="
        case kVK_ANSI_Grave: return "`"
        case kVK_Space: return "Space"
        case kVK_Return: return "Return"
        case kVK_Tab: return "Tab"
        case kVK_Delete: return "Delete"
        case kVK_ForwardDelete: return "Forward Delete"
        case kVK_Escape: return "Esc"
        case kVK_LeftArrow: return "←"
        case kVK_RightArrow: return "→"
        case kVK_UpArrow: return "↑"
        case kVK_DownArrow: return "↓"
        case kVK_Home: return "Home"
        case kVK_End: return "End"
        case kVK_PageUp: return "Page Up"
        case kVK_PageDown: return "Page Down"
        case kVK_F1: return "F1"
        case kVK_F2: return "F2"
        case kVK_F3: return "F3"
        case kVK_F4: return "F4"
        case kVK_F5: return "F5"
        case kVK_F6: return "F6"
        case kVK_F7: return "F7"
        case kVK_F8: return "F8"
        case kVK_F9: return "F9"
        case kVK_F10: return "F10"
        case kVK_F11: return "F11"
        case kVK_F12: return "F12"
        default: return "Key \(keyCode)"
        }
    }

    static func isFunctionKey(_ keyCode: UInt16) -> Bool {
        switch Int(keyCode) {
        case kVK_F1, kVK_F2, kVK_F3, kVK_F4, kVK_F5, kVK_F6,
             kVK_F7, kVK_F8, kVK_F9, kVK_F10, kVK_F11, kVK_F12:
            return true
        default:
            return false
        }
    }

    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var value: UInt32 = 0
        if flags.contains(.command) { value |= UInt32(cmdKey) }
        if flags.contains(.shift) { value |= UInt32(shiftKey) }
        if flags.contains(.option) { value |= UInt32(optionKey) }
        if flags.contains(.control) { value |= UInt32(controlKey) }
        return value
    }
}

@MainActor
final class ShortcutManager {
    var onAction: (@MainActor (ShortcutAction) -> Void)?

    private let signature: OSType = 0x54534E50
    private var eventHandler: EventHandlerRef?
    private var hotKeyRefs: [EventHotKeyRef] = []
    private var handlers: [UInt32: ShortcutAction] = [:]

    init() {
        installHandler()
    }

    func registerAll() {
        unregisterAll()
        guard AXIsProcessTrusted() else { return }

        for (index, action) in ShortcutAction.allCases.enumerated() {
            let shortcut = ShortcutStore.shortcut(for: action)
            guard shortcut.keyCode != 0 || shortcut.modifiers != 0 else { continue }
            let id = UInt32(index + 1)
            var ref: EventHotKeyRef?
            let hotKeyID = EventHotKeyID(signature: signature, id: id)
            let status = RegisterEventHotKey(
                shortcut.keyCode,
                shortcut.modifiers,
                hotKeyID,
                GetApplicationEventTarget(),
                0,
                &ref
            )
            if status == noErr, let ref {
                hotKeyRefs.append(ref)
                handlers[id] = action
            }
        }
    }

    func handle(id: UInt32) {
        guard let action = handlers[id] else { return }
        onAction?(action)
    }

    private func unregisterAll() {
        for ref in hotKeyRefs {
            UnregisterEventHotKey(ref)
        }
        hotKeyRefs.removeAll()
        handlers.removeAll()
    }

    private func installHandler() {
        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let userData = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            hotKeyEventHandler,
            1,
            &spec,
            userData,
            &eventHandler
        )
    }
}

private func hotKeyEventHandler(
    _ nextHandler: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event, let userData else { return noErr }
    var hotKeyID = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )
    guard status == noErr else { return status }
    let manager = Unmanaged<ShortcutManager>.fromOpaque(userData).takeUnretainedValue()
    Task { @MainActor in
        manager.handle(id: hotKeyID.id)
    }
    return noErr
}
