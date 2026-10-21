import AppKit
import CoreImage
import XCTest
@testable import SnippetFlow

@MainActor
final class OCRServiceTests: XCTestCase {
    private var temporaryFiles: [URL] = []

    override func tearDown() {
        for url in temporaryFiles {
            try? FileManager.default.removeItem(at: url)
        }
        temporaryFiles.removeAll()
        super.tearDown()
    }

    func testRecognizesRenderedText() async throws {
        let url = try makeTextImage("HELLO 123")
        let text = try await recognize(url)
        XCTAssertTrue(text.localizedCaseInsensitiveContains("HELLO"))
        XCTAssertTrue(text.contains("123"))
    }

    func testRecognizesQRCode() async throws {
        let url = try makeQRCode("https://example.com/ocr-test")
        let text = try await detectBarcode(url)
        XCTAssertEqual(text, "https://example.com/ocr-test")
    }

    func testBlankImageReportsNoResult() async throws {
        let url = try makeTextImage(" ")
        do {
            _ = try await recognize(url)
            XCTFail("Expected OCR to fail on a blank image")
        } catch OCRError.noResult {
        } catch {
            XCTFail("Expected noResult, got \(error)")
        }
    }

    private func recognize(_ url: URL) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            OCRService.shared.recognize(
                imageURL: url,
                language: "en-US",
                automaticallyDetectLanguage: false,
                customWords: [],
                keepLineBreaks: false
            ) {
                continuation.resume(with: $0)
            }
        }
    }

    private func detectBarcode(_ url: URL) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            OCRService.shared.recognizeBarcode(imageURL: url) {
                continuation.resume(with: $0)
            }
        }
    }

    private func makeTextImage(_ text: String) throws -> URL {
        let size = NSSize(width: 900, height: 260)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.white.setFill()
        NSRect(origin: .zero, size: size).fill()
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 84, weight: .bold),
            .foregroundColor: NSColor.black
        ]
        (text as NSString).draw(at: NSPoint(x: 32, y: 82), withAttributes: attributes)
        image.unlockFocus()

        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:]) else {
            throw TestImageError.encodingFailed
        }
        return try write(png)
    }

    private func makeQRCode(_ payload: String) throws -> URL {
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            throw TestImageError.encodingFailed
        }
        filter.setValue(Data(payload.utf8), forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")
        guard let output = filter.outputImage else {
            throw TestImageError.encodingFailed
        }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 12, y: 12))
        guard let cgImage = CIContext().createCGImage(scaled, from: scaled.extent) else {
            throw TestImageError.encodingFailed
        }
        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        guard let png = bitmap.representation(using: .png, properties: [:]) else {
            throw TestImageError.encodingFailed
        }
        return try write(png)
    }

    private func write(_ data: Data) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("SnippetFlowTests-\(UUID().uuidString).png")
        try data.write(to: url)
        temporaryFiles.append(url)
        return url
    }
}

private enum TestImageError: Error {
    case encodingFailed
}
