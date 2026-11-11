import CoreGraphics

/// 누른 지점이 어느 낱말 상자인지 정한다.
/// 누르기 쉽게 상자를 키우면 줄 간격이 좁은 책에서 위아래 상자가 겹치므로,
/// 실제 글자 영역 안을 누른 상자를 먼저 고르고, 없으면 누른 지점과 가장 가까운 상자를 고른다.
enum WordHitTest {
    /// - Parameters:
    ///   - point: 누른 지점 (좌상단 원점 0~1)
    ///   - frames: 낱말 상자 (같은 좌표계)
    ///   - margin: 글자 영역 바깥으로 눌러도 인정하는 여유
    static func index(at point: CGPoint, in frames: [Int: CGRect], margin: CGSize) -> Int? {
        if let exact = frames
            .filter({ $0.value.contains(point) })
            .min(by: { distance(point, $0.value) < distance(point, $1.value) }) {
            return exact.key
        }

        return frames
            .filter { $0.value.insetBy(dx: -margin.width, dy: -margin.height).contains(point) }
            .min { distance(point, $0.value) < distance(point, $1.value) }?
            .key
    }

    private static func distance(_ point: CGPoint, _ frame: CGRect) -> CGFloat {
        hypot(point.x - frame.midX, point.y - frame.midY)
    }
}
