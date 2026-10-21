import Foundation

enum TextProcessor {
    static let marker = "$#CLEAN_AFTER$#"

    private static let linePairs: [(String, String)] = [
        ("-  ", ""),
        ("- ", ""),
        ("  ", " "),
        (" -", "-"),
        ("-\n", "\n"),
        ("-", marker)
    ]

    private static let finalPairs: [(String, String)] = [
        ("  ", " "),
        ("-\n", "\n"),
        (marker, "-")
    ]

    static func normalizeLine(_ input: String) -> String {
        var value = input
        for (from, to) in linePairs {
            value = value.replacingOccurrences(of: from, with: to)
        }
        return value
    }

    static func finish(_ input: String) -> String {
        var value = input
        for (from, to) in finalPairs {
            value = value.replacingOccurrences(of: from, with: to)
        }
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func joinLines(_ lines: [String], keepLineBreaks: Bool) -> String {
        let cleaned = lines
            .map(normalizeLine)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let separator = keepLineBreaks ? "\n" : " "
        return finish(cleaned.joined(separator: separator))
    }

    static func finishVisionKitTranscript(_ transcript: String) -> String {
        finish(transcript.replacingOccurrences(of: "\n", with: " "))
    }
}
