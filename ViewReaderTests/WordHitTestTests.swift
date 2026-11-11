import CoreGraphics
import Testing
@testable import ViewReader

@Suite("누른 낱말 찾기")
struct WordHitTestTests {
    private let margin = CGSize(width: 0.02, height: 0.02)
    // 줄 간격이 좁아 여유 영역끼리 겹치는 두 줄
    private let frames: [Int: CGRect] = [
        0: CGRect(x: 0.1, y: 0.10, width: 0.3, height: 0.05),
        1: CGRect(x: 0.1, y: 0.16, width: 0.3, height: 0.05),
        2: CGRect(x: 0.5, y: 0.10, width: 0.3, height: 0.05),
    ]

    @Test("글자 영역 안을 누르면 그 상자를 고른다")
    func 글자_영역_안을_누르면_그_상자() {
        // when
        let actual = WordHitTest.index(at: CGPoint(x: 0.2, y: 0.17), in: frames, margin: margin)

        // then
        #expect(actual == 1)
    }

    @Test("여유 영역이 겹치는 곳을 누르면 더 가까운 상자를 고른다")
    func 겹치는_여유_영역은_가까운_상자() {
        // given — 두 줄 사이 틈(0.15~0.16)에서 아래 줄 쪽에 더 가까운 지점
        let point = CGPoint(x: 0.2, y: 0.158)

        // when
        let actual = WordHitTest.index(at: point, in: frames, margin: margin)

        // then
        #expect(actual == 1)
    }

    @Test("글자 영역이 직접 겹치면 가운데가 더 가까운 상자를 고른다")
    func 글자_영역이_겹치면_가운데가_가까운_상자() {
        // given
        let overlapping: [Int: CGRect] = [
            0: CGRect(x: 0.1, y: 0.10, width: 0.3, height: 0.06),
            1: CGRect(x: 0.1, y: 0.14, width: 0.3, height: 0.06),
        ]

        // when
        let actualUpper = WordHitTest.index(at: CGPoint(x: 0.2, y: 0.145), in: overlapping, margin: margin)
        let actualLower = WordHitTest.index(at: CGPoint(x: 0.2, y: 0.155), in: overlapping, margin: margin)

        // then
        #expect(actualUpper == 0)
        #expect(actualLower == 1)
    }

    @Test("어느 상자에서도 멀면 고르지 않는다")
    func 멀면_고르지_않는다() {
        // when
        let actual = WordHitTest.index(at: CGPoint(x: 0.9, y: 0.9), in: frames, margin: margin)

        // then
        #expect(actual == nil)
    }

    @Test("상자가 없으면 고르지 않는다")
    func 상자가_없으면_고르지_않는다() {
        // when
        let actual = WordHitTest.index(at: CGPoint(x: 0.5, y: 0.5), in: [:], margin: margin)

        // then
        #expect(actual == nil)
    }
}
