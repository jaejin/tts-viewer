import Testing
@testable import ViewReader

@Suite("글 유사도")
struct TextSimilarityTests {
    @Test("같은 글은 유사도가 1이다")
    func 같은_글은_유사도_1() {
        // when
        let actualDice = TextSimilarity.dice("아기 곰이 잠을 자요", "아기 곰이 잠을 자요")
        let actualOverlap = TextSimilarity.overlap("아기 곰이 잠을 자요", "아기 곰이 잠을 자요")

        // then
        #expect(actualDice == 1)
        #expect(actualOverlap == 1)
    }

    @Test("겹치는 글자가 없으면 유사도가 0이다")
    func 전혀_다른_글은_유사도_0() {
        // when
        let actual = TextSimilarity.dice("가나다라", "마바사아")

        // then
        #expect(actual == 0)
    }

    @Test("띄어쓰기와 문장부호 차이는 무시한다")
    func 띄어쓰기와_문장부호는_무시한다() {
        // when
        let actual = TextSimilarity.dice("아기 곰이, 잠을 자요.", "아기곰이 잠을자요")

        // then
        #expect(actual == 1)
    }

    @Test("일부가 가려져 짧아진 글도 겹침 계수는 1이다")
    func 일부가_가려진_글은_겹침_계수_1() {
        // given
        let full = "옛날 옛적 깊은 산속에 호랑이가 살았어요"
        let covered = "깊은 산속에 호랑이가"

        // when
        let actualOverlap = TextSimilarity.overlap(full, covered)
        let actualDice = TextSimilarity.dice(full, covered)

        // then
        #expect(actualOverlap == 1)
        #expect(actualDice < 1)
    }

    @Test("둘 다 비어 있으면 같은 글로 본다")
    func 둘_다_비어_있으면_같다() {
        // when
        let actualDice = TextSimilarity.dice("", " ")
        let actualOverlap = TextSimilarity.overlap("", "")

        // then
        #expect(actualDice == 1)
        #expect(actualOverlap == 1)
    }

    @Test("한쪽만 비어 있으면 겹침 계수는 0이다")
    func 한쪽만_비어_있으면_겹침_0() {
        // when
        let actual = TextSimilarity.overlap("", "호랑이")

        // then
        #expect(actual == 0)
    }

    @Test("한 글자는 그 글자 하나를 2-gram 으로 쓴다")
    func 한_글자_2gram() {
        // when
        let actual = TextSimilarity.bigrams("응")

        // then
        #expect(actual == ["응"])
    }
}
