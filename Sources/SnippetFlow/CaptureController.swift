import AppKit
import UniformTypeIdentifiers

@MainActor
final class CaptureController {
    private let preferences = Preferences.shared
    private let overlay = SelectionOverlayController()
    private var isCapturing = false

    func captureText(forceLineBreaks: Bool? = nil, forceTTS: Bool = false) {
        guard beginCapture() else { return }
        guard PermissionManager.shared.ensureScreenRecordingPermission() else {
            isCapturing = false
            return
        }

        overlay.present { [weak self] rect in
            guard let self else { return }
            guard let rect else {
                self.isCapturing = false
                return
            }
            self.preferences.previousCaptureArea = rect
            let keepLineBreaks = forceLineBreaks ?? self.preferences.lineSettings
            self.runTextCapture(rect: rect, keepLineBreaks: keepLineBreaks, forceTTS: forceTTS)
        }
    }

    func capturePreviousArea() {
        guard beginCapture() else { return }
        guard PermissionManager.shared.ensureScreenRecordingPermission() else {
            isCapturing = false
            return
        }
        guard let rect = preferences.previousCaptureArea else {
            isCapturing = false
            NotificationPresenter.shared.show("No Previous Capture Area", force: true)
            return
        }
        runTextCapture(rect: rect, keepLineBreaks: preferences.lineSettings, forceTTS: false)
    }

    func captureBarcode() {
        guard beginCapture() else { return }
        guard PermissionManager.shared.ensureScreenRecordingPermission() else {
            isCapturing = false
            return
        }

        overlay.present { [weak self] rect in
            guard let self else { return }
            guard let rect else {
                self.isCapturing = false
                return
            }
            self.preferences.previousCaptureArea = rect
            self.runBarcodeCapture(rect: rect)
        }
    }

    func importImage() {
        NSApp.activate(ignoringOtherApps: true)
        let panel = NSOpenPanel()
        panel.title = "Take Photo"
        panel.message = "Choose an image to recognize."
        panel.prompt = "Recognize"
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard beginCapture() else { return }
        recognizeImage(at: url)
    }

    private func beginCapture() -> Bool {
        if isCapturing {
            return false
        }
        isCapturing = true
        return true
    }

    private func runTextCapture(rect: CGRect, keepLineBreaks: Bool, forceTTS: Bool) {
        let mute = preferences.disableSound
        let language = preferences.recognitionLanguage
        let detectLanguage = preferences.autoDetectLanguage
        let customWords = preferences.customWordList

        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.08) { [weak self] in
            do {
                let url = try ScreenCapturer.capture(rect: rect, mute: mute)
                OCRService.shared.recognize(
                    imageURL: url,
                    language: language,
                    automaticallyDetectLanguage: detectLanguage,
                    customWords: customWords,
                    keepLineBreaks: keepLineBreaks
                ) { [weak self] result in
                    ScreenCapturer.remove(url)
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        self.isCapturing = false
                        switch result {
                        case .success(let text):
                            self.handleText(text, forceTTS: forceTTS)
                        case .failure(let error):
                            self.handleFailure(error)
                        }
                    }
                }
            } catch {
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.isCapturing = false
                    self.handleFailure(error)
                }
            }
        }
    }

    private func runBarcodeCapture(rect: CGRect) {
        let mute = preferences.disableSound

        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.08) { [weak self] in
            do {
                let url = try ScreenCapturer.capture(rect: rect, mute: mute)
                OCRService.shared.recognizeBarcode(imageURL: url) { [weak self] result in
                    ScreenCapturer.remove(url)
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        self.isCapturing = false
                        switch result {
                        case .success(let text):
                            ClipboardManager.shared.copyBarcode(text)
                            NotificationPresenter.shared.show("Copied to Clipboard")
                            SpeechManager.shared.speakStatus("Text Copied to Clipboard")
                        case .failure(let error):
                            if case OCRError.noResult = error {
                                NotificationPresenter.shared.show("No Data Detected", force: true)
                                SpeechManager.shared.speakStatus("No Data Detected")
                            } else {
                                self.handleFailure(error)
                            }
                        }
                    }
                }
            } catch {
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.isCapturing = false
                    self.handleFailure(error)
                }
            }
        }
    }

    private func recognizeImage(at url: URL) {
        OCRService.shared.recognize(
            imageURL: url,
            language: preferences.recognitionLanguage,
            automaticallyDetectLanguage: preferences.autoDetectLanguage,
            customWords: preferences.customWordList,
            keepLineBreaks: preferences.lineSettings
        ) { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isCapturing = false
                switch result {
                case .success(let text):
                    self.handleText(text, forceTTS: false)
                case .failure(let error):
                    self.handleFailure(error)
                }
            }
        }
    }

    private func handleText(_ text: String, forceTTS: Bool) {
        guard !text.isEmpty else {
            handleFailure(OCRError.noResult)
            return
        }

        preferences.noTextCount = 0
        ClipboardManager.shared.copy(text)

        if preferences.textToSpeech || forceTTS {
            SpeechManager.shared.speak(text, rate: preferences.ttsSpeedRate)
            preferences.triggeredTTS = false
        }

        if preferences.openLinks {
            LinkOpener.shared.openLinks(in: text)
        }

        NotificationPresenter.shared.show("Copied to Clipboard")
        SpeechManager.shared.speakStatus("Text Copied to Clipboard")
    }

    private func handleFailure(_ error: Error) {
        if case OCRError.noResult = error {
            preferences.noTextCount += 1
            NotificationPresenter.shared.show("No Text Detected", force: true)
            SpeechManager.shared.speakStatus("No Text Detected")
            return
        }

        NotificationPresenter.shared.show("Something went Wrong", force: true)
        SpeechManager.shared.speakStatus("Something went Wrong")

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Something went Wrong"
        alert.informativeText = "Something went wrong: \(error.localizedDescription)"
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
