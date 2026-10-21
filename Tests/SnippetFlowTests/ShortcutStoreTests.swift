import XCTest
@testable import SnippetFlow

final class ShortcutStoreTests: XCTestCase {
    override func tearDown() {
        for action in ShortcutAction.allCases {
            UserDefaults.standard.removeObject(forKey: action.storageKey)
        }
        super.tearDown()
    }

    func testDefaultShortcutIsUsedWhenNothingIsStored() {
        XCTAssertEqual(
            ShortcutStore.shortcut(for: .captureText),
            Shortcut(keyCode: 19, modifiers: 768)
        )
    }

    func testClearedShortcutStaysCleared() {
        ShortcutStore.set(nil, for: .captureText)
        XCTAssertEqual(
            ShortcutStore.shortcut(for: .captureText),
            Shortcut(keyCode: 0, modifiers: 0)
        )
    }

    func testRoundTrip() {
        let shortcut = Shortcut(keyCode: 0, modifiers: 768)
        ShortcutStore.set(shortcut, for: .captureText)
        XCTAssertEqual(ShortcutStore.shortcut(for: .captureText), shortcut)
    }

    func testActionWithoutDefaultIsUnset() {
        XCTAssertEqual(
            ShortcutStore.shortcut(for: .barcode),
            Shortcut(keyCode: 0, modifiers: 0)
        )
    }
}
