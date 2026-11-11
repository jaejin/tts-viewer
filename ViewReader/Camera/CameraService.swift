import AVFoundation
import CoreImage
import os
import Vision

/// 찍은 화면과 그 안의 낱말 위치. 낱말 위치는 사진 기준 좌상단 원점 0~1 좌표다
struct CapturedPage: @unchecked Sendable {
    let image: CGImage
    let words: [TextLine]
}

/// 카메라 프레임을 받아 일정 간격으로 OCR 을 돌리고 인식한 줄을 넘겨준다.
/// 프레임 처리는 전용 큐에서 동기로 하며, 처리 중 들어온 프레임은 버려서 지연이 쌓이지 않게 한다.
final class CameraService: NSObject, @unchecked Sendable {
    let session = AVCaptureSession()

    /// 시작 전에 한 번만 설정한다 (비디오 큐에서 읽기 때문에 실행 중 변경 금지)
    var onLines: (@Sendable ([TextLine]) -> Void)?

    /// 모든 프레임을 OCR 하면 발열·배터리 소모가 커서 간격을 둔다
    private let analysisInterval: TimeInterval = 0.4
    private let minimumConfidence: Float = 0.4

    private let sessionQueue = DispatchQueue(label: "viewreader.camera.session")
    private let videoQueue = DispatchQueue(label: "viewreader.camera.video")
    private var isConfigured = false
    private var lastAnalysis = Date.distantPast
    /// 화면의 미리보기 크기 — 메인 스레드에서 바뀌고 비디오 큐에서 읽으므로 잠금으로 보호한다
    private let previewSize = OSAllocatedUnfairLock(initialState: CGSize.zero)
    /// 찍기 요청 — 다음 프레임에서 처리하고 결과를 돌려준다
    private let pendingCapture = OSAllocatedUnfairLock<CheckedContinuation<CapturedPage?, Never>?>(initialState: nil)
    private let ciContext = CIContext()

    /// 지금 화면에 보이는 부분을 찍어 낱말 단위로 인식한다
    func capture() async -> CapturedPage? {
        await withCheckedContinuation { continuation in
            let previous = pendingCapture.withLock { pending in
                defer { pending = continuation }
                return pending
            }
            previous?.resume(returning: nil)
        }
    }

    /// 화면에 보이는 부분의 글만 읽도록 미리보기 크기를 알려준다
    func updatePreviewSize(_ size: CGSize) {
        previewSize.withLock { $0 = size }
    }

    func start() {
        sessionQueue.async { [self] in
            configureIfNeeded()
            if isConfigured, !session.isRunning {
                session.startRunning()
            }
        }
    }

    func stop() {
        // 카메라가 멈추면 다음 프레임이 오지 않으므로 기다리던 찍기 요청을 끝내 준다
        takePendingCapture()?.resume(returning: nil)
        sessionQueue.async { [self] in
            if session.isRunning {
                session.stopRunning()
            }
        }
    }

    private func takePendingCapture() -> CheckedContinuation<CapturedPage?, Never>? {
        pendingCapture.withLock { pending in
            defer { pending = nil }
            return pending
        }
    }

    private func configureIfNeeded() {
        guard !isConfigured else { return }

        session.beginConfiguration()
        defer { session.commitConfiguration() }

        // 작은 글씨까지 읽으려면 해상도가 충분해야 한다
        if session.canSetSessionPreset(.hd1920x1080) {
            session.sessionPreset = .hd1920x1080
        }

        guard let device = Self.bestCamera(),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }
        session.addInput(input)
        Self.configureFocus(device)

        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: videoQueue)
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)

        // 프레임을 세로 화면 방향으로 받아야 OCR 좌표의 위/아래가 책의 위/아래와 일치한다
        if let connection = output.connection(with: .video), connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
        isConfigured = true
    }

    /// 책을 가까이 대도 초점이 맞도록, 매크로(초광각) 자동 전환이 되는 가상 카메라를 먼저 고른다
    private static func bestCamera() -> AVCaptureDevice? {
        let preferred: [AVCaptureDevice.DeviceType] = [.builtInTripleCamera, .builtInDualWideCamera, .builtInWideAngleCamera]
        let devices = AVCaptureDevice.DiscoverySession(deviceTypes: preferred, mediaType: .video, position: .back).devices
        for type in preferred {
            if let device = devices.first(where: { $0.deviceType == type }) {
                return device
            }
        }
        return nil
    }

    private static func configureFocus(_ device: AVCaptureDevice) {
        guard (try? device.lockForConfiguration()) != nil else { return }
        defer { device.unlockForConfiguration() }

        if device.isFocusModeSupported(.continuousAutoFocus) {
            device.focusMode = .continuousAutoFocus
        }
        // 책은 항상 가까이 있으므로 근거리 위주로 초점을 잡으면 더 빨리 맞는다
        if device.isAutoFocusRangeRestrictionSupported {
            device.autoFocusRangeRestriction = .near
        }
    }

    private func recognize(_ pixelBuffer: CVPixelBuffer) -> [TextLine] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["ko-KR", "en-US"]
        request.usesLanguageCorrection = true

        do {
            try VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up).perform([request])
        } catch {
            return []
        }

        return (request.results ?? []).compactMap { observation in
            guard let candidate = observation.topCandidates(1).first,
                  candidate.confidence >= minimumConfidence else { return nil }
            return TextLine(text: candidate.string, visionBoundingBox: observation.boundingBox)
        }
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let imageSize = CGSize(width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
        let area = VisibleArea.rect(viewSize: previewSize.withLock { $0 }, imageSize: imageSize)

        if let continuation = takePendingCapture() {
            continuation.resume(returning: capturePage(pixelBuffer, visibleArea: area))
            return
        }

        let now = Date()
        guard now.timeIntervalSince(lastAnalysis) >= analysisInterval else { return }
        lastAnalysis = now

        onLines?(VisibleArea.filter(recognize(pixelBuffer), in: area))
    }

    /// 화면에 보이는 부분만 잘라 찍는다 — 아이가 본 화면과 찍힌 사진이 같아야 낱말을 정확히 누를 수 있다
    private func capturePage(_ pixelBuffer: CVPixelBuffer, visibleArea area: CGRect) -> CapturedPage? {
        let image = CIImage(cvPixelBuffer: pixelBuffer)
        let width = image.extent.width
        let height = image.extent.height
        // CIImage 는 좌하단 원점이라 위아래를 뒤집어 자른다
        let crop = CGRect(x: area.minX * width, y: (1 - area.maxY) * height, width: area.width * width, height: area.height * height)
        guard let cgImage = ciContext.createCGImage(image, from: crop) else { return nil }
        return CapturedPage(image: cgImage, words: recognizeWords(in: cgImage))
    }

    private func recognizeWords(in image: CGImage) -> [TextLine] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["ko-KR", "en-US"]
        request.usesLanguageCorrection = true

        do {
            try VNImageRequestHandler(cgImage: image, orientation: .up).perform([request])
        } catch {
            return []
        }

        return (request.results ?? []).flatMap { observation -> [TextLine] in
            guard let candidate = observation.topCandidates(1).first,
                  candidate.confidence >= minimumConfidence else { return [] }
            let line = candidate.string
            // 줄 단위 결과를 낱말로 나눠 낱말마다 위치를 얻는다
            return WordSplitter.ranges(in: line).compactMap { range in
                guard let box = try? candidate.boundingBox(for: range)?.boundingBox else { return nil }
                return TextLine(text: String(line[range]), visionBoundingBox: box)
            }
        }
    }
}
