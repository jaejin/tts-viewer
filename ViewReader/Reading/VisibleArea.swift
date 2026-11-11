import CoreGraphics

/// 화면에 보이는 카메라 영역 안의 글만 읽기 위한 계산.
/// 미리보기는 aspectFill 이라 카메라 이미지의 가장자리가 잘려 보이므로, 그 잘린 범위를 이미지 좌표로 구한다.
enum VisibleArea {
    static let whole = CGRect(x: 0, y: 0, width: 1, height: 1)

    /// - Returns: 미리보기에 실제로 보이는 이미지 범위 (좌상단 원점, 0~1 정규화 좌표)
    static func rect(viewSize: CGSize, imageSize: CGSize) -> CGRect {
        guard viewSize.width > 0, viewSize.height > 0, imageSize.width > 0, imageSize.height > 0 else {
            return whole
        }

        let scale = max(viewSize.width / imageSize.width, viewSize.height / imageSize.height)
        let width = min(1, viewSize.width / (imageSize.width * scale))
        let height = min(1, viewSize.height / (imageSize.height * scale))
        return CGRect(x: (1 - width) / 2, y: (1 - height) / 2, width: width, height: height)
    }

    /// 줄의 가운데가 보이는 영역 안에 있는 줄만 남긴다.
    /// OCR 영역 자체를 잘라 버리면 경계에 걸친 줄이 반쪽만 읽히므로 줄 단위로 거른다.
    static func filter(_ lines: [TextLine], in area: CGRect) -> [TextLine] {
        lines.filter { area.contains(CGPoint(x: $0.frame.midX, y: $0.frame.midY)) }
    }
}
