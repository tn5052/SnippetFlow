import XCTest
@testable import SnippetFlow

final class TextProcessorTests: XCTestCase {
    func testJoinsLinesWithSpaces() {
        XCTAssertEqual(TextProcessor.joinLines(["Hello", "world"], keepLineBreaks: false), "Hello world")
    }

    func testKeepsLineBreaks() {
        XCTAssertEqual(TextProcessor.joinLines(["Hello", "world"], keepLineBreaks: true), "Hello\nworld")
    }

    func testTrimsEmptyLines() {
        XCTAssertEqual(TextProcessor.joinLines(["", "  Alpha  ", "", "Beta", ""], keepLineBreaks: false), "Alpha Beta")
    }

    func testRemovesHyphenBeforeNewline() {
        XCTAssertEqual(TextProcessor.finish("sniper-\nshot"), "sniper\nshot")
    }

    func testVisionKitTranscriptJoinsLines() {
        XCTAssertEqual(TextProcessor.finishVisionKitTranscript("Alpha\nBeta\nGamma"), "Alpha Beta Gamma")
    }
}
