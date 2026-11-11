import AVFoundation
import Observation

/// 한국어 음성으로 글을 읽고, 지금 읽는 단어 위치를 화면에 알려준다
@MainActor
@Observable
final class SpeechReader: NSObject {
    static let defaultRate: Float = 0.42

    private(set) var isSpeaking = false
    private(set) var isPaused = false
    /// 지금 읽고 있는 글 — 화면 강조가 다른 글(목소리 미리 듣기 등)의 위치를 잘못 칠하지 않게 함께 둔다
    private(set) var spokenText: String?
    /// 지금 읽고 있는 단어의 위치 (UTF-16 기준, spokenText 안에서의 범위)
    private(set) var spokenRange: NSRange?
    /// 아이가 따라오기 쉽도록 기본값을 보통 속도(0.5)보다 조금 느리게 둔다
    var rate: Float {
        didSet { defaults.set(rate, forKey: Keys.rate) }
    }
    /// 선택한 목소리. nil 이면 기기의 기본 한국어 음성을 쓴다
    var voiceIdentifier: String? {
        didSet { defaults.set(voiceIdentifier, forKey: Keys.voice) }
    }

    @ObservationIgnored private let defaults: UserDefaults

    @ObservationIgnored private let synthesizer = AVSpeechSynthesizer()
    /// 이전 글을 끊고 새 글을 읽을 때, 늦게 도착한 이전 글의 콜백이 상태를 덮어쓰지 않게 구분한다
    @ObservationIgnored private var currentUtteranceID: ObjectIdentifier?

    private enum Keys {
        static let rate = "speech.rate"
        static let voice = "speech.voiceIdentifier"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // 저장된 적이 없으면 float(forKey:) 가 0 을 돌려주므로 존재 여부를 먼저 본다
        self.rate = defaults.object(forKey: Keys.rate) == nil ? Self.defaultRate : defaults.float(forKey: Keys.rate)
        self.voiceIdentifier = defaults.string(forKey: Keys.voice)
        super.init()
        synthesizer.delegate = self
    }

    /// 기기에 설치된 한국어 음성. 품질이 좋은 순서로 정렬한다
    static func koreanVoices() -> [VoiceOption] {
        VoiceOption.sorted(
            AVSpeechSynthesisVoice.speechVoices()
                .filter { $0.language.hasPrefix("ko") }
                .map(VoiceOption.init(voice:))
        )
    }

    /// - Parameter rate: 지정하면 이번 한 번만 그 속도로 읽는다 (자음·모음 연습처럼 더 천천히 들려줄 때)
    func speak(_ text: String, rate: Float? = nil) {
        synthesizer.stopSpeaking(at: .immediate)

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voiceIdentifier.flatMap(AVSpeechSynthesisVoice.init(identifier:))
            ?? AVSpeechSynthesisVoice(language: "ko-KR")
        utterance.rate = rate ?? self.rate
        currentUtteranceID = ObjectIdentifier(utterance)
        spokenText = text
        spokenRange = nil
        isPaused = false
        synthesizer.speak(utterance)
    }

    func pause() {
        synthesizer.pauseSpeaking(at: .word)
    }

    func resume() {
        synthesizer.continueSpeaking()
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func update(_ id: ObjectIdentifier, _ change: (SpeechReader) -> Void) {
        guard id == currentUtteranceID else { return }
        change(self)
    }
}

extension SpeechReader: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in
            self.update(id) { $0.isSpeaking = true; $0.isPaused = false }
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in
            self.update(id) { $0.spokenRange = characterRange }
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in
            self.update(id) { $0.isPaused = true }
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in
            self.update(id) { $0.isPaused = false }
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in
            self.update(id) { $0.finish() }
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in
            self.update(id) { $0.finish() }
        }
    }

    private func finish() {
        isSpeaking = false
        isPaused = false
        spokenText = nil
        spokenRange = nil
    }
}
