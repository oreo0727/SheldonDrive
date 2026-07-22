import AVFoundation
import Foundation

final class VoicePlayback: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    private var onFinished: (() -> Void)?

    @Published private(set) var isSpeaking = false

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String, onFinished: (() -> Void)? = nil) {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        synthesizer.stopSpeaking(at: .immediate)
        self.onFinished = onFinished
        let utterance = AVSpeechUtterance(string: cleaned)
        utterance.rate = 0.52
        utterance.pitchMultiplier = 0.94
        utterance.volume = 1
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func stop() {
        onFinished = nil
        isSpeaking = false
        synthesizer.stopSpeaking(at: .immediate)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        finishSpeaking()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        finishSpeaking(runCompletion: false)
    }

    private func finishSpeaking(runCompletion: Bool = true) {
        let completion = onFinished
        onFinished = nil
        DispatchQueue.main.async { [weak self] in
            self?.isSpeaking = false
            if runCompletion {
                completion?()
            }
        }
    }
}
