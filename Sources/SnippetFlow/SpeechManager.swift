import AppKit

final class SpeechManager {
    static let shared = SpeechManager()

    private let synthesizer = NSSpeechSynthesizer()

    private init() {}

    func speak(_ text: String, rate: Int) {
        guard !text.isEmpty else { return }
        stop()
        synthesizer.rate = Float(max(80, min(400, rate)))
        synthesizer.startSpeaking(text)
    }

    func speakStatus(_ text: String) {
        guard NSWorkspace.shared.isVoiceOverEnabled else { return }
        speak(text, rate: 180)
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking()
        }
    }
}
