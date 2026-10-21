import Foundation
import Vision
import VisionKit

enum OCRError: LocalizedError {
    case analyzerUnavailable
    case noResult

    var errorDescription: String? {
        switch self {
        case .analyzerUnavailable: return "Text recognition is not available."
        case .noResult: return "No Text Detected"
        }
    }
}

final class OCRService {
    static let shared = OCRService()

    static let visionKitLanguages: Set<String> = [
        "zh-Hans", "zh-Hant", "yue-Hans", "yue-Hant", "ja-JP", "ko-KR"
    ]

    private init() {}

    func recognize(
        imageURL: URL,
        language: String,
        automaticallyDetectLanguage: Bool,
        customWords: [String],
        keepLineBreaks: Bool,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        if #available(macOS 14.0, *), Self.visionKitLanguages.contains(language), ImageAnalyzer.isSupported {
            recognizeWithVisionKit(
                imageURL: imageURL,
                language: language,
                automaticallyDetectLanguage: automaticallyDetectLanguage,
                customWords: customWords,
                keepLineBreaks: keepLineBreaks,
                completion: completion
            )
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let text = try self.recognizeWithVision(
                    imageURL: imageURL,
                    language: language,
                    automaticallyDetectLanguage: automaticallyDetectLanguage,
                    customWords: customWords,
                    keepLineBreaks: keepLineBreaks
                )
                DispatchQueue.main.async { completion(.success(text)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }

    private func recognizeWithVision(
        imageURL: URL,
        language: String,
        automaticallyDetectLanguage: Bool,
        customWords: [String],
        keepLineBreaks: Bool
    ) throws -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.customWords = customWords

        if #available(macOS 13.0, *) {
            request.automaticallyDetectsLanguage = automaticallyDetectLanguage
        }
        if !automaticallyDetectLanguage {
            request.recognitionLanguages = [language]
        }

        let handler = VNImageRequestHandler(url: imageURL, options: [:])
        try handler.perform([request])

        let observations = request.results ?? []
        let sorted = observations.sorted { lhs, rhs in
            let lhsBox = lhs.boundingBox
            let rhsBox = rhs.boundingBox
            if abs(lhsBox.maxY - rhsBox.maxY) > 0.01 {
                return lhsBox.maxY > rhsBox.maxY
            }
            return lhsBox.minX < rhsBox.minX
        }

        let lines: [String] = sorted.compactMap { observation in
            observation.topCandidates(1).first?.string
        }

        let text = TextProcessor.joinLines(lines, keepLineBreaks: keepLineBreaks)
        guard !text.isEmpty else { throw OCRError.noResult }
        return text
    }

    @available(macOS 14.0, *)
    private func recognizeWithVisionKit(
        imageURL: URL,
        language: String,
        automaticallyDetectLanguage: Bool,
        customWords: [String],
        keepLineBreaks: Bool,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        Task {
            do {
                let analyzer = ImageAnalyzer()
                var configuration = ImageAnalyzer.Configuration(.text)
                configuration.locales = [language]
                let analysis = try await analyzer.analyze(
                    imageAt: imageURL,
                    orientation: .up,
                    configuration: configuration
                )
                let text = keepLineBreaks
                    ? TextProcessor.finish(analysis.transcript)
                    : TextProcessor.finishVisionKitTranscript(analysis.transcript)
                if text.isEmpty {
                    try await fallBackToVision(
                        imageURL: imageURL,
                        language: language,
                        automaticallyDetectLanguage: automaticallyDetectLanguage,
                        customWords: customWords,
                        keepLineBreaks: keepLineBreaks,
                        completion: completion
                    )
                } else {
                    await MainActor.run { completion(.success(text)) }
                }
            } catch {
                do {
                    try await fallBackToVision(
                        imageURL: imageURL,
                        language: language,
                        automaticallyDetectLanguage: automaticallyDetectLanguage,
                        customWords: customWords,
                        keepLineBreaks: keepLineBreaks,
                        completion: completion
                    )
                } catch {
                    await MainActor.run { completion(.failure(error)) }
                }
            }
        }
    }

    @available(macOS 14.0, *)
    private func fallBackToVision(
        imageURL: URL,
        language: String,
        automaticallyDetectLanguage: Bool,
        customWords: [String],
        keepLineBreaks: Bool,
        completion: @escaping (Result<String, Error>) -> Void
    ) async throws {
        let text = try await Task.detached(priority: .userInitiated) {
            try self.recognizeWithVision(
                imageURL: imageURL,
                language: language,
                automaticallyDetectLanguage: automaticallyDetectLanguage,
                customWords: customWords,
                keepLineBreaks: keepLineBreaks
            )
        }.value
        await MainActor.run { completion(.success(text)) }
    }

    func recognizeBarcode(imageURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let request = VNDetectBarcodesRequest()
                let handler = VNImageRequestHandler(url: imageURL, options: [:])
                try handler.perform([request])
                let observations = request.results ?? []
                let payloads = observations.compactMap { $0.payloadStringValue }.filter { !$0.isEmpty }
                guard !payloads.isEmpty else {
                    DispatchQueue.main.async { completion(.failure(OCRError.noResult)) }
                    return
                }
                let text = payloads.joined(separator: "\n")
                DispatchQueue.main.async { completion(.success(text)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }
}
