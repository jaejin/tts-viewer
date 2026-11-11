import Testing
@testable import ViewReader

@Suite("카드 읽기 순서")
struct FlashcardScriptTests {
    @Test("낱말 → 글자마다 자음·모음 → 글자 → 낱말 순서로 읽는다")
    func 나눴다가_합쳐_읽는다() {
        // when
        let actual = FlashcardScript.cues(for: "토끼")

        // then
        #expect(actual.map(\.sound) == ["토끼", "트", "오", "토", "끄", "이", "끼", "토끼"])
        #expect(actual.map(\.syllableIndex) == [nil, 0, 0, 0, 1, 1, 1, nil])
        #expect(actual.map(\.stepID) == [nil, 0, 1, nil, 0, 1, nil, nil])
    }

    @Test("받침도 소리로 읽는다")
    func 받침도_읽는다() {
        // when
        let actual = FlashcardScript.cues(for: "강")

        // then
        #expect(actual.map(\.sound) == ["강", "그", "아", "응", "강", "강"])
        #expect(actual.map(\.stepID) == [nil, 0, 1, 3, nil, nil])
    }

    @Test("소리 없는 첫소리 ㅇ 은 건너뛴다")
    func 첫소리_이응은_건너뛴다() {
        // when
        let actual = FlashcardScript.cues(for: "오리")

        // then
        #expect(actual.map(\.sound) == ["오리", "오", "오", "르", "이", "리", "오리"])
    }

    @Test("한글이 아닌 글자는 그대로 읽는다")
    func 한글이_아닌_글자는_그대로() {
        // when
        let actual = FlashcardScript.cues(for: "A1")

        // then
        #expect(actual.map(\.sound) == ["A1", "A", "1", "A1"])
        #expect(actual.map(\.syllableIndex) == [nil, 0, 1, nil])
    }

    @Test("마지막에 낱말 전체를 듣고 조금 더 오래 쉰다")
    func 마지막은_더_오래_쉰다() {
        // when
        let actual = FlashcardScript.cues(for: "나무")

        // then
        #expect(actual.first?.pause == 1.6)
        #expect(actual.last?.pause == 2.0)
    }
}
