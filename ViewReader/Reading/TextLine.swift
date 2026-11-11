import CoreGraphics

/// OCR 로 인식한 한 줄의 글자와 화면 위치.
/// 위치는 좌상단 원점, 0~1 정규화 좌표다 (Vision 은 좌하단 원점이라 변환해서 보관한다).
struct TextLine: Equatable, Sendable {
    let text: String
    let frame: CGRect

    init(text: String, frame: CGRect) {
        self.text = text
        self.frame = frame
    }

    /// Vision 의 boundingBox(좌하단 원점)를 받아 화면 읽기 순서 계산에 맞는 좌상단 원점으로 뒤집는다
    init(text: String, visionBoundingBox box: CGRect) {
        self.init(text: text, frame: CGRect(x: box.minX, y: 1 - box.maxY, width: box.width, height: box.height))
    }
}
