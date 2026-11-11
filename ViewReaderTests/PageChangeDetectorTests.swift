import Testing
@testable import ViewReader

@Suite("쪽 넘김 판단")
struct PageChangeDetectorTests {
    private let firstPage = "옛날 옛적 깊은 산속에 호랑이 한 마리가 살았어요. 호랑이는 엄마를 찾고 있었어요."
    private let secondPage = "어느 날 토끼가 찾아와 말했어요. 나랑 같이 놀러 가지 않을래?"

    @Test("한 번만 보인 글은 흔들림일 수 있어 읽지 않는다")
    func 한_번만_보인_글은_읽지_않는다() {
        // given
        var detector = PageChangeDetector()

        // when
        let actual = detector.feed(firstPage)

        // then
        #expect(actual == nil)
    }

    @Test("연속으로 비슷하게 보이면 그 쪽을 읽는다")
    func 연속으로_보이면_읽는다() {
        // given
        var detector = PageChangeDetector()
        _ = detector.feed(firstPage)

        // when
        let actual = detector.feed(firstPage)

        // then
        #expect(actual == firstPage)
        #expect(detector.lastRead == firstPage)
    }

    @Test("이미 읽은 쪽은 계속 보여도 다시 읽지 않는다")
    func 읽은_쪽은_다시_읽지_않는다() {
        // given
        var detector = PageChangeDetector()
        _ = detector.feed(firstPage)
        _ = detector.feed(firstPage)

        // when
        let actual = detector.feed(firstPage)

        // then
        #expect(actual == nil)
    }

    @Test("손가락으로 일부가 가려져도 같은 쪽으로 본다")
    func 일부가_가려져도_같은_쪽으로_본다() {
        // given
        var detector = PageChangeDetector()
        _ = detector.feed(firstPage)
        _ = detector.feed(firstPage)
        let covered = "깊은 산속에 호랑이 한 마리가 살았어요."

        // when
        _ = detector.feed(covered)
        let actual = detector.feed(covered)

        // then
        #expect(actual == nil)
    }

    @Test("책장을 넘겨 새 쪽이 안정되면 새 쪽을 읽는다")
    func 새_쪽이_안정되면_읽는다() {
        // given
        var detector = PageChangeDetector()
        _ = detector.feed(firstPage)
        _ = detector.feed(firstPage)

        // when
        let actualFirst = detector.feed(secondPage)
        let actualSecond = detector.feed(secondPage)

        // then
        #expect(actualFirst == nil)
        #expect(actualSecond == secondPage)
    }

    @Test("앞 쪽 글에 들어 있는 짧은 글도 새 쪽이면 읽는다")
    func 짧은_새_쪽도_읽는다() {
        // given
        var detector = PageChangeDetector()
        _ = detector.feed(firstPage)
        _ = detector.feed(firstPage)

        // when
        _ = detector.feed("엄마!")
        let actual = detector.feed("엄마!")

        // then
        #expect(actual == "엄마!")
    }

    @Test("너무 짧은 글은 무시하고 안정 횟수도 처음부터 다시 센다")
    func 너무_짧은_글은_무시하고_안정_횟수를_초기화한다() {
        // given
        var detector = PageChangeDetector()
        _ = detector.feed(firstPage)

        // when
        let actualShort = detector.feed("가")
        let actualAfterShort = detector.feed(firstPage)

        // then
        #expect(actualShort == nil)
        #expect(actualAfterShort == nil)
    }

    @Test("초기화하면 같은 쪽을 다시 읽는다")
    func 초기화하면_같은_쪽을_다시_읽는다() {
        // given
        var detector = PageChangeDetector()
        _ = detector.feed(firstPage)
        _ = detector.feed(firstPage)
        detector.reset()

        // when
        _ = detector.feed(firstPage)
        let actual = detector.feed(firstPage)

        // then
        #expect(actual == firstPage)
    }
}
