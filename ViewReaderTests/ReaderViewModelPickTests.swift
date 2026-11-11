import Testing
@testable import ViewReader

@MainActor
@Suite("찍은 화면에서 낱말 고르기")
struct ReaderViewModelPickTests {
    @Test("고른 낱말은 문장부호를 떼고 순서대로 쌓인다")
    func 고른_낱말이_쌓인다() {
        // given
        let model = ReaderViewModel()

        // when
        let actualFirst = model.pick("토끼!", fromBox: 0)
        let actualSecond = model.pick("호랑이", fromBox: 0)

        // then
        #expect(actualFirst)
        #expect(actualSecond)
        #expect(model.pickedWords.map(\.text) == ["토끼", "호랑이"])
        #expect(model.pickedWords.map(\.boxIndex) == [0, 0])
    }

    @Test("같은 낱말이나 빈 낱말은 고르지 않는다")
    func 중복과_빈_낱말은_고르지_않는다() {
        // given
        let model = ReaderViewModel()
        model.pick("토끼", fromBox: 0)

        // when
        let actualDuplicate = model.pick("토끼.", fromBox: 1)
        let actualEmpty = model.pick("…", fromBox: 2)

        // then
        #expect(!actualDuplicate)
        #expect(!actualEmpty)
        #expect(model.pickedWords.count == 1)
    }

    @Test("최대 개수까지만 고른다")
    func 최대_개수까지만_고른다() {
        // given
        let model = ReaderViewModel()
        for index in 0..<ReaderViewModel.maximumSelection {
            model.pick("낱말\(index)", fromBox: index)
        }

        // when
        let actual = model.pick("하나더", fromBox: 9)

        // then
        #expect(!actual)
        #expect(!model.canPickMore)
        #expect(model.pickedWords.count == ReaderViewModel.maximumSelection)
    }

    @Test("고른 낱말을 빼면 다시 고를 수 있다")
    func 빼면_다시_고를_수_있다() throws {
        // given
        let model = ReaderViewModel()
        model.pick("토끼", fromBox: 0)
        let word = try #require(model.pickedWords.first)

        // when
        model.unpick(word)
        let actual = model.pick("토끼", fromBox: 0)

        // then
        #expect(actual)
        #expect(model.pickedWords.map(\.text) == ["토끼"])
    }

    @Test("찍기를 닫으면 고른 낱말과 열린 창이 모두 비워진다")
    func 닫으면_모두_비워진다() {
        // given
        let model = ReaderViewModel()
        model.pick("토끼", fromBox: 0)
        model.pickingBoxIndex = 0

        // when
        model.closeCapture()

        // then
        #expect(model.pickedWords.isEmpty)
        #expect(model.pickingBoxIndex == nil)
        #expect(model.capturedPage == nil)
    }
}
