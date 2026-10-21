import AppKit
import Foundation

enum ScreenCaptureError: LocalizedError {
    case failed(String)
    case emptyResult

    var errorDescription: String? {
        switch self {
        case .failed(let message): return message
        case .emptyResult: return "The capture did not produce an image."
        }
    }
}

final class ScreenCapturer {
    static func capture(rect: CGRect, mute: Bool) throws -> URL {
        let directory = try cacheDirectory()
        let url = directory.appendingPathComponent("capture-\(UUID().uuidString).png")

        let captureRect = screenCaptureRect(from: rect)
        let x = Int(floor(captureRect.origin.x))
        let y = Int(floor(captureRect.origin.y))
        let width = max(1, Int(ceil(captureRect.width)))
        let height = max(1, Int(ceil(captureRect.height)))

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        var arguments = [
            "-R", "\(x),\(y),\(width),\(height)",
            "-t", "png"
        ]
        if mute {
            arguments.append("-x")
        }
        arguments.append(url.path)
        process.arguments = arguments

        let errorPipe = Pipe()
        process.standardError = errorPipe
        process.standardOutput = FileHandle.nullDevice
        process.qualityOfService = .userInitiated

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let message = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            throw ScreenCaptureError.failed(message?.isEmpty == false ? message! : "Screen capture failed.")
        }

        guard FileManager.default.fileExists(atPath: url.path),
              let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              (attributes[.size] as? NSNumber)?.intValue ?? 0 > 0 else {
            throw ScreenCaptureError.emptyResult
        }

        return url
    }

    static func remove(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    private static func cacheDirectory() throws -> URL {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let directory = base.appendingPathComponent("SnippetFlow", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static func screenCaptureRect(from globalRect: CGRect) -> CGRect {
        let mainHeight = NSScreen.screens
            .first(where: { $0.frame.origin == .zero })?
            .frame.height ?? NSScreen.main?.frame.height ?? 0
        return CGRect(
            x: globalRect.origin.x,
            y: mainHeight - globalRect.maxY,
            width: globalRect.width,
            height: globalRect.height
        )
    }
}
