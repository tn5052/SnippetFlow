import AppKit
import XCTest
@testable import SnippetFlow

final class ClipboardManagerTests: XCTestCase {
    private let preferences = Preferences.shared

    override func setUp() {
        super.setUp()
        preferences.keepHistory = false
        preferences.clipboard = ""
        NSPasteboard.general.clearContents()
    }

    override func tearDown() {
        preferences.keepHistory = false
        preferences.clipboard = ""
        NSPasteboard.general.clearContents()
        super.tearDown()
    }

    func testCopiesOnlyLatestTextWhenHistoryIsOff() {
        preferences.lastPasteboardChangeCount = 123
        ClipboardManager.shared.copy("first")
        ClipboardManager.shared.copy("second")

        XCTAssertEqual(NSPasteboard.general.string(forType: .string), "second")
        XCTAssertEqual(preferences.clipboard, "")
        XCTAssertEqual(preferences.lastPasteboardChangeCount, 123)
    }

    func testAppendsHistoryWhenEnabled() {
        preferences.keepHistory = true

        ClipboardManager.shared.copy("first")
        ClipboardManager.shared.copy("second")

        XCTAssertEqual(preferences.clipboard, "first\n\nsecond")
        XCTAssertEqual(NSPasteboard.general.string(forType: .string), "first\n\nsecond")
    }

    func testClearHistoryLeavesPasteboardUntouched() {
        preferences.keepHistory = true
        ClipboardManager.shared.copy("first")
        let current = NSPasteboard.general.string(forType: .string)

        ClipboardManager.shared.clearHistory()

        XCTAssertEqual(preferences.clipboard, "")
        XCTAssertEqual(NSPasteboard.general.string(forType: .string), current)
    }

    func testBarcodeCopyReplacesPasteboardAndDoesNotChangeHistory() {
        preferences.keepHistory = true
        preferences.clipboard = "prior"

        ClipboardManager.shared.copyBarcode("https://example.com")

        XCTAssertEqual(NSPasteboard.general.string(forType: .string), "https://example.com")
        XCTAssertEqual(preferences.clipboard, "prior")
    }
}
