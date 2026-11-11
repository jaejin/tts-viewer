import CoreGraphics
import Testing
@testable import ViewReader

@Suite("사진 속 낱말 위치")
struct WordFrameTests {
    private let box = CGRect(x: 0.1, y: 0.4, width: 0.7, height: 0.05)

    @Test("상자 일부를 고르면 글자 수 비율로 위치를 나눈다")
    func 일부를_고르면_비율로_나눈다() {
        // given — 7글자 중 5~6번째(토끼)
        let range = 4...5

        // when
        let actual = WordFrame.subFrame(of: box, selecting: range, count: 7)

        // then
        #expect(abs(actual.minX - 0.5) < 0.0001)
        #expect(abs(actual.width - 0.2) < 0.0001)
        #expect(actual.minY == box.minY)
        #expect(actual.height == box.height)
    }

    @Test("전체를 고르면 상자 그대로다")
    func 전체를_고르면_그대로() {
        // when
        let actual = WordFrame.subFrame(of: box, selecting: 0...6, count: 7)

        // then
        #expect(abs(actual.minX - box.minX) < 0.0001)
        #expect(abs(actual.width - box.width) < 0.0001)
    }

    @Test("글자 수가 없거나 범위가 어긋나면 상자 그대로다")
    func 잘못된_범위는_상자_그대로() {
        // when
        let actualNoCount = WordFrame.subFrame(of: box, selecting: 0...0, count: 0)
        let actualOutOfRange = WordFrame.subFrame(of: box, selecting: 8...9, count: 7)

        // then
        #expect(actualNoCount == box)
        #expect(actualOutOfRange == box)
    }

    @Test("문장 띠는 낱말 위아래로 줄 높이의 1.5배씩 넓힌다")
    func 문장_띠는_위아래로_넓힌다() {
        // when
        let actual = WordFrame.sentenceBand(around: box)

        // then — 띠는 0.325~0.525, 낱말은 띠 안에서 0.375 위치
        #expect(abs(actual.band.minY - 0.325) < 0.0001)
        #expect(abs(actual.band.height - 0.2) < 0.0001)
        #expect(abs(actual.highlight.minY - 0.375) < 0.0001)
        #expect(abs(actual.highlight.height - 0.25) < 0.0001)
    }

    @Test("가로는 낱말을 가운데 두고 사진 폭의 일부만 잘라 글자를 크게 보여 준다")
    func 가로는_낱말_주변만_자른다() {
        // given — 사진 가운데의 짧은 낱말
        let word = CGRect(x: 0.45, y: 0.4, width: 0.1, height: 0.05)

        // when
        let actual = WordFrame.sentenceBand(around: word)

        // then — 최소 폭 0.6 을 낱말 가운데(0.5)에 맞춰 0.2~0.8
        #expect(abs(actual.band.minX - 0.2) < 0.0001)
        #expect(abs(actual.band.width - 0.6) < 0.0001)
        #expect(abs(actual.highlight.midX - 0.5) < 0.0001)
        #expect(abs(actual.highlight.width - 0.1 / 0.6) < 0.0001)
    }

    @Test("긴 낱말은 낱말 폭의 3배까지 넓히되 사진 폭을 넘지 않는다")
    func 긴_낱말은_사진_폭까지만() {
        // when
        let actual = WordFrame.sentenceBand(around: box)

        // then — 0.7 의 3배는 사진 폭을 넘으므로 전체 폭
        #expect(actual.band.minX == 0)
        #expect(actual.band.width == 1)
        #expect(abs(actual.highlight.minX - box.minX) < 0.0001)
    }

    @Test("가장자리 낱말은 띠를 안쪽으로 밀어 사진 밖을 자르지 않는다")
    func 가장자리_낱말은_띠를_안쪽으로_민다() {
        // given
        let leftWord = CGRect(x: 0.02, y: 0.4, width: 0.1, height: 0.05)
        let rightWord = CGRect(x: 0.88, y: 0.4, width: 0.1, height: 0.05)

        // when
        let actualLeft = WordFrame.sentenceBand(around: leftWord)
        let actualRight = WordFrame.sentenceBand(around: rightWord)

        // then
        #expect(actualLeft.band.minX == 0)
        #expect(abs(actualLeft.highlight.minX - 0.02 / 0.6) < 0.0001)
        #expect(abs(actualRight.band.maxX - 1) < 0.0001)
        #expect(abs(actualRight.highlight.maxX - (0.98 - 0.4) / 0.6) < 0.0001)
    }

    @Test("사진 위쪽 가장자리를 넘지 않게 띠를 자른다")
    func 위쪽_가장자리를_넘지_않는다() {
        // given
        let topWord = CGRect(x: 0.1, y: 0.01, width: 0.3, height: 0.05)

        // when
        let actual = WordFrame.sentenceBand(around: topWord)

        // then
        #expect(actual.band.minY == 0)
        #expect(abs(actual.highlight.minY - 0.01 / actual.band.height) < 0.0001)
    }

    @Test("높이가 없는 낱말이면 사진 전체를 쓴다")
    func 높이가_없으면_전체() {
        // when
        let actual = WordFrame.sentenceBand(around: CGRect(x: 0.1, y: 0.5, width: 0.3, height: 0))

        // then
        #expect(actual.band == VisibleArea.whole)
    }
}
