import AVFoundation
import Observation
import UIKit

/// 카메라 OCR → 쪽 넘김 판단 → 음성 읽기를 이어 주는 화면 상태
@MainActor
@Observable
final class ReaderViewModel {
    enum CameraAccess {
        case unknown
        case granted
        case denied
    }

    private(set) var cameraAccess: CameraAccess = .unknown
    /// 마지막으로 읽기 시작한 쪽의 글
    private(set) var pageText = ""
    private(set) var isAutoReadOn = true
    let speech = SpeechReader()
    let wordBook = WordBook()

    /// 찍기 모드 — 화면이 멈춰 있는 동안에는 자동 읽기를 하지 않는다
    private(set) var capturedPage: CapturedPage?
    private(set) var isCapturing = false
    /// 상자에서 골라낸 낱말 — 붙어 인식된 상자 하나에서 여러 낱말을 골라낼 수도 있다
    private(set) var pickedWords: [PickedWord] = []
    /// 글자 고르기 창에 띄운 상자
    var pickingBoxIndex: Int?
    /// 한 번에 너무 많이 고르면 연습이 부담스러워지므로 개수를 제한한다
    static let maximumSelection = 5

    @ObservationIgnored let camera = CameraService()
    @ObservationIgnored private var detector = PageChangeDetector()

    func start() async {
        cameraAccess = await AVCaptureDevice.requestAccess(for: .video) ? .granted : .denied
        guard cameraAccess == .granted else { return }

        camera.onLines = { [weak self] lines in
            // 줄 정렬은 비디오 큐에서 끝내고, 상태 변경만 메인으로 넘긴다
            let text = ReadingOrder.compose(lines)
            Task { @MainActor in
                self?.receive(text)
            }
        }
        camera.start()
    }

    func resumeCamera() {
        guard cameraAccess == .granted else { return }
        camera.start()
    }

    func suspendCamera() {
        camera.stop()
        speech.stop()
    }

    func updatePreviewSize(_ size: CGSize) {
        camera.updatePreviewSize(size)
    }

    func selectVoice(_ identifier: String) {
        speech.voiceIdentifier = identifier
        speech.speak("안녕하세요. 이 목소리로 책을 읽어 드릴게요.")
    }

    func readAgain() {
        guard !pageText.isEmpty else { return }
        speech.speak(pageText)
    }

    func togglePause() {
        if speech.isPaused {
            speech.resume()
        } else if speech.isSpeaking {
            speech.pause()
        }
    }

    func toggleAutoRead() {
        isAutoReadOn.toggle()
        if isAutoReadOn {
            // 다시 켰을 때 지금 보이는 쪽부터 읽어 주기 위해 읽은 기록을 지운다
            detector.reset()
        } else {
            speech.stop()
        }
    }

    var isInCaptureMode: Bool { capturedPage != nil || isCapturing }

    struct PickedWord: Equatable, Identifiable {
        let boxIndex: Int
        let text: String
        /// 찍은 사진 안에서 낱말 위치 — 단어장에서 어느 문장의 낱말인지 표시할 때 쓴다
        var frame: CGRect?
        var id: String { text }
    }

    var canPickMore: Bool { pickedWords.count < Self.maximumSelection }

    func capturePage() async {
        guard !isInCaptureMode else { return }
        speech.stop()
        isCapturing = true
        let page = await camera.capture()
        isCapturing = false
        pickedWords = []
        capturedPage = page
    }

    /// 상자를 누르면 소리로 들려주고, 그 안에서 낱말을 골라낼 창을 연다
    func openBox(at index: Int) {
        guard let page = capturedPage, page.words.indices.contains(index) else { return }
        speech.speak(Hangul.cleanWord(page.words[index].text))
        pickingBoxIndex = index
    }

    /// - Returns: 넣었으면 true. 이미 고른 낱말이거나 개수가 꽉 찼으면 false
    @discardableResult
    func pick(_ text: String, fromBox boxIndex: Int, frame: CGRect? = nil) -> Bool {
        let word = Hangul.cleanWord(text)
        guard !word.isEmpty, canPickMore, !pickedWords.contains(where: { $0.text == word }) else { return false }
        pickedWords.append(PickedWord(boxIndex: boxIndex, text: word, frame: frame))
        return true
    }

    func unpick(_ word: PickedWord) {
        pickedWords.removeAll { $0 == word }
    }

    /// - Returns: 단어장에 들어간 낱말 수
    @discardableResult
    func savePickedWords() -> Int {
        let words = pickedWords.map { WordBook.NewWord(text: $0.text, frame: $0.frame) }
        let imageData = capturedPage.flatMap { UIImage(cgImage: $0.image).jpegData(compressionQuality: 0.7) }
        closeCapture()
        return wordBook.add(words, imageData: imageData)
    }

    func closeCapture() {
        capturedPage = nil
        pickedWords = []
        pickingBoxIndex = nil
    }

    func receive(_ text: String) {
        guard isAutoReadOn, !isInCaptureMode, let page = detector.feed(text) else { return }
        pageText = page
        speech.speak(page)
    }
}
