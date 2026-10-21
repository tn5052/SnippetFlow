import AppKit
import XCTest
@testable import SnippetFlow

@MainActor
final class MenuControllerTests: XCTestCase {
    func testMenuMatchesDocumentedOrder() {
        let controller = MenuController()
        XCTAssertEqual(
            controller.menu.items.map(\.title),
            [
                "Capture Text",
                "Read QR/Bar Code",
                "Take Photo",
                "",
                "Keep Line Breaks",
                "",
                "Additive Clipboard",
                "Clear Clipboard History",
                "",
                "Text to Speech",
                "Stop Speaking",
                "",
                "Preferences...",
                "",
                "Quit SnippetFlow"
            ]
        )
    }

    func testTakePhotoUsesImportIdentifier() {
        let controller = MenuController()
        XCTAssertEqual(controller.menu.items[2].identifier, NSMenuItem.importFromDeviceIdentifier)
    }

    func testQuitHasCommandQ() {
        let controller = MenuController()
        let quit = controller.menu.items.last
        XCTAssertEqual(quit?.keyEquivalent, "q")
        XCTAssertEqual(quit?.keyEquivalentModifierMask, [.command])
    }

    func testActionItemsHaveTargets() {
        let controller = MenuController()
        for item in controller.menu.items where !item.isSeparatorItem && item.title != "Quit SnippetFlow" {
            XCTAssertNotNil(item.target, "Missing target for \(item.title)")
            XCTAssertNotNil(item.action, "Missing action for \(item.title)")
        }
    }
}
