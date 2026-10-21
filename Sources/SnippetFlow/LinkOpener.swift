import AppKit

final class LinkOpener {
    static let shared = LinkOpener()

    private init() {}

    func openLinks(in text: String) {
        guard !text.isEmpty else { return }
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = detector.matches(in: text, options: [], range: range)

        var opened: Set<URL> = []
        for match in matches {
            guard let url = match.url, let scheme = url.scheme?.lowercased() else { continue }
            guard scheme == "http" || scheme == "https" else { continue }
            guard !opened.contains(url) else { continue }
            opened.insert(url)
            NSWorkspace.shared.open(url)
        }
    }
}
