import CoreGraphics
import Testing
@testable import ViewReader

@Suite("읽는 순서 정렬")
struct ReadingOrderTests {
    private func line(_ text: String, x: CGFloat, y: CGFloat, width: CGFloat = 0.3, height: CGFloat = 0.04) -> TextLine {
        TextLine(text: text, frame: CGRect(x: x, y: y, width: width, height: height))
    }

    @Test("한 쪽의 여러 줄은 순서가 섞여 들어와도 위에서 아래로 잇는다")
    func 한_쪽의_줄을_위에서_아래로_잇는다() {
        // given
        let lines = [
            line("셋째 줄", x: 0.1, y: 0.30, width: 0.8),
            line("첫째 줄", x: 0.1, y: 0.10, width: 0.8),
            line("둘째 줄", x: 0.1, y: 0.15, width: 0.8),
        ]

        // when
        let actual = ReadingOrder.compose(lines)

        // then
        let expected = "첫째 줄 둘째 줄\n셋째 줄"
        #expect(actual == expected)
    }

    @Test("같은 높이로 나뉜 줄 조각은 왼쪽부터 한 줄로 잇는다")
    func 같은_높이의_조각은_왼쪽부터_잇는다() {
        // given
        let lines = [
            line("토끼가", x: 0.6, y: 0.11, width: 0.3),
            line("숲 속에서", x: 0.05, y: 0.10, width: 0.3),
            line("살았어요", x: 0.3, y: 0.30, width: 0.4),
        ]

        // when
        let actual = ReadingOrder.compose(lines)

        // then
        #expect(actual.hasPrefix("숲 속에서 토끼가"))
    }

    @Test("펼친 두 쪽은 왼쪽 쪽을 끝까지 읽고 오른쪽 쪽을 읽는다")
    func 펼친_두_쪽은_왼쪽_쪽부터_읽는다() {
        // given
        let lines = [
            line("오른쪽 첫 줄", x: 0.55, y: 0.10),
            line("왼쪽 첫 줄", x: 0.05, y: 0.10),
            line("왼쪽 둘째 줄", x: 0.05, y: 0.15),
            line("오른쪽 둘째 줄", x: 0.55, y: 0.15),
        ]

        // when
        let actual = ReadingOrder.compose(lines)

        // then
        let expected = "왼쪽 첫 줄 왼쪽 둘째 줄\n오른쪽 첫 줄 오른쪽 둘째 줄"
        #expect(actual == expected)
    }

    @Test("가운데를 가로지르는 줄이 있으면 두 쪽으로 나누지 않는다")
    func 가운데를_가로지르는_줄이_있으면_한_쪽으로_본다() {
        // given
        let lines = [
            line("오른쪽 짧은 글", x: 0.6, y: 0.10),
            line("가운데를 가로지르는 긴 줄", x: 0.1, y: 0.15, width: 0.8),
        ]

        // when
        let actual = ReadingOrder.columns(of: lines)

        // then
        #expect(actual.count == 1)
    }

    @Test("한쪽에만 글이 있으면 한 쪽으로 본다")
    func 한쪽에만_글이_있으면_한_쪽으로_본다() {
        // given
        let lines = [line("왼쪽 글", x: 0.05, y: 0.1), line("왼쪽 글 둘", x: 0.05, y: 0.2)]

        // when
        let actual = ReadingOrder.columns(of: lines)

        // then
        #expect(actual.count == 1)
    }

    @Test("쪽 번호와 기호만 있는 줄은 읽지 않는다")
    func 쪽_번호는_읽지_않는다() {
        // given
        let lines = [
            line("옛날 옛적에", x: 0.1, y: 0.10, width: 0.8),
            line("- 12 -", x: 0.45, y: 0.95, width: 0.1),
        ]

        // when
        let actual = ReadingOrder.compose(lines)

        // then
        #expect(actual == "옛날 옛적에")
    }

    @Test("잡음 판단", arguments: [
        ("12", true),
        ("- 12 -", true),
        ("***", true),
        ("", true),
        ("1장", false),
        ("Chapter 1", false),
    ])
    func 잡음_판단(text: String, expected: Bool) {
        // when
        let actual = ReadingOrder.isNoise(text)

        // then
        #expect(actual == expected)
    }

    @Test("영어 줄 끝 하이픈으로 잘린 단어는 붙여 읽는다")
    func 하이픈으로_잘린_단어를_붙인다() {
        // given
        let lines = [
            line("a beauti-", x: 0.1, y: 0.10, width: 0.8),
            line("ful day", x: 0.1, y: 0.15, width: 0.8),
        ]

        // when
        let actual = ReadingOrder.compose(lines)

        // then
        #expect(actual == "a beautiful day")
    }

    @Test("하이픈 뒤가 대문자면 단어를 붙이지 않는다")
    func 하이픈_뒤가_대문자면_붙이지_않는다() {
        // given
        let lines = [
            line("Jean-", x: 0.1, y: 0.10, width: 0.8),
            line("Paul came", x: 0.1, y: 0.15, width: 0.8),
        ]

        // when
        let actual = ReadingOrder.compose(lines)

        // then
        #expect(actual == "Jean- Paul came")
    }

    @Test("남는 글이 없으면 빈 문자열을 돌려준다")
    func 남는_글이_없으면_빈_문자열() {
        // when
        let actualEmpty = ReadingOrder.compose([])
        let actualNoiseOnly = ReadingOrder.compose([line("3", x: 0.5, y: 0.9)])

        // then
        #expect(actualEmpty == "")
        #expect(actualNoiseOnly == "")
    }

    @Test("Vision 좌표(좌하단 원점)를 좌상단 원점으로 뒤집는다")
    func Vision_좌표를_좌상단_원점으로_뒤집는다() {
        // given
        let visionBox = CGRect(x: 0.1, y: 0.7, width: 0.3, height: 0.1)

        // when
        let actual = TextLine(text: "글", visionBoundingBox: visionBox)

        // then
        #expect(abs(actual.frame.minY - 0.2) < 0.0001)
        #expect(actual.frame.minX == 0.1)
        #expect(actual.frame.height == 0.1)
    }
}
