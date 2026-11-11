import Testing
@testable import ViewReader

@Suite("낱말 나누기")
struct WordSplitterTests {
    private func split(_ text: String) -> [String] {
        WordSplitter.ranges(in: text).map { String(text[$0]) }
    }

    @Test("띄어쓰기로 나눈다")
    func 띄어쓰기로_나눈다() {
        // when
        let actual = split("토끼가  깡충 뛰었어요")

        // then
        #expect(actual == ["토끼가", "깡충", "뛰었어요"])
    }

    @Test("띄어쓰기를 놓쳐도 문장부호에서 나눈다", arguments: [
        ("말했어요.토끼가", ["말했어요", "토끼가"]),
        ("\"안녕?\"하고", ["안녕", "하고"]),
        ("사과,배,감", ["사과", "배", "감"]),
        ("어흥…무서워!", ["어흥", "무서워"]),
    ])
    func 문장부호에서_나눈다(text: String, expected: [String]) {
        // when
        let actual = split(text)

        // then
        #expect(actual == expected)
    }

    @Test("영어 축약형의 작은따옴표에서는 나누지 않는다")
    func 영어_축약형은_나누지_않는다() {
        // when
        let actual = split("I don't know")

        // then
        #expect(actual == ["I", "don't", "know"])
    }

    @Test("낱말이 없으면 빈 목록이다", arguments: ["", "   ", "…!?"])
    func 낱말이_없으면_빈_목록(text: String) {
        // when
        let actual = split(text)

        // then
        #expect(actual.isEmpty)
    }
}
