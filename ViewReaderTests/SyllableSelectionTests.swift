import Testing
@testable import ViewReader

@Suite("상자 안 글자 고르기")
struct SyllableSelectionTests {
    @Test("처음에는 문장부호를 뺀 상자 전체가 골라져 있다")
    func 처음에는_전체가_골라져_있다() {
        // when
        let actual = SyllableSelection(text: "토끼가!")

        // then
        #expect(actual.characters == ["토", "끼", "가"])
        #expect(actual.selectedText == "토끼가")
        #expect(!actual.isWaitingForEnd)
    }

    @Test("첫 글자와 끝 글자를 누르면 그 사이를 고른다")
    func 첫_글자와_끝_글자_사이를_고른다() {
        // given
        var selection = SyllableSelection(text: "말했어요토끼가")

        // when
        selection.tap(4)
        let actualAfterFirst = selection.selectedText
        let actualWaiting = selection.isWaitingForEnd
        selection.tap(5)

        // then
        #expect(actualAfterFirst == "토")
        #expect(actualWaiting)
        #expect(selection.selectedText == "토끼")
        #expect(!selection.isWaitingForEnd)
    }

    @Test("끝 글자를 첫 글자보다 앞에서 눌러도 사이를 고른다")
    func 거꾸로_눌러도_사이를_고른다() {
        // given
        var selection = SyllableSelection(text: "말했어요토끼가")

        // when
        selection.tap(3)
        selection.tap(0)

        // then
        #expect(selection.selectedText == "말했어요")
    }

    @Test("고른 뒤 다시 누르면 새로 고르기를 시작한다")
    func 다시_누르면_새로_시작한다() {
        // given
        var selection = SyllableSelection(text: "말했어요토끼가")
        selection.tap(0)
        selection.tap(3)

        // when
        selection.tap(6)

        // then
        #expect(selection.selectedText == "가")
        #expect(selection.isWaitingForEnd)
    }

    @Test("전체 고르기로 되돌린다")
    func 전체_고르기로_되돌린다() {
        // given
        var selection = SyllableSelection(text: "토끼가")
        selection.tap(1)

        // when
        selection.selectAll()

        // then
        #expect(selection.selectedText == "토끼가")
        #expect(!selection.isWaitingForEnd)
    }

    @Test("범위 밖을 누르면 아무것도 바뀌지 않는다")
    func 범위_밖은_무시한다() {
        // given
        var selection = SyllableSelection(text: "토끼")
        let expected = selection

        // when
        selection.tap(5)
        selection.tap(-1)

        // then
        #expect(selection == expected)
    }

    @Test("글자가 없으면 빈 낱말이다")
    func 글자가_없으면_빈_낱말() {
        // when
        let actual = SyllableSelection(text: "…")

        // then
        #expect(actual.selectedText == "")
    }
}
