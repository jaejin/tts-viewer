import Testing
@testable import ViewReader

@Suite("한글 자음·모음 나누기")
struct HangulTests {
    @Test("받침 있는 글자는 초성·중성·종성으로 나눈다")
    func 받침_있는_글자를_나눈다() throws {
        // when
        let actual = try #require(Hangul.decompose("강"))

        // then
        #expect(Hangul.initials[actual.initial] == "ㄱ")
        #expect(Hangul.medials[actual.medial] == "ㅏ")
        #expect(Hangul.finals[actual.final] == "ㅇ")
        #expect(actual.openSyllable == "가")
        #expect(actual.whole == "강")
    }

    @Test("한글 음절이 아니면 나누지 않는다", arguments: ["A", "1", "ㄱ", "!", "😀"])
    func 한글_음절이_아니면_nil(text: String) {
        // when
        let actual = Hangul.decompose(Character(text))

        // then
        #expect(actual == nil)
    }

    @Test("한글 범위의 처음과 끝 글자도 나눈다")
    func 처음과_끝_글자() {
        // when
        let actualFirst = Hangul.decompose("가")
        let actualLast = Hangul.decompose("힣")

        // then
        #expect(actualFirst?.whole == "가")
        #expect(actualLast?.whole == "힣")
    }

    @Test("받침 있는 글자는 초성 → 중성 → 합친 소리 → 받침 → 전체 순서로 연습한다")
    func 받침_있는_글자의_연습_순서() throws {
        // given
        let syllable = try #require(Hangul.decompose("강"))

        // when
        let actual = Hangul.steps(for: syllable)

        // then
        #expect(actual.map(\.label) == ["ㄱ", "ㅏ", "가", "ㅇ", "강"])
        #expect(actual.map(\.sound) == ["그", "아", "가", "응", "강"])
        #expect(actual.map(\.caption) == ["기역", "아", "", "받침 이응", ""])
        #expect(actual.map(\.kind) == [.consonant, .vowel, .combined, .consonant, .combined])
    }

    @Test("받침 없는 글자는 세 단계로 끝난다")
    func 받침_없는_글자의_연습_순서() throws {
        // given
        let syllable = try #require(Hangul.decompose("호"))

        // when
        let actual = Hangul.steps(for: syllable)

        // then
        #expect(actual.map(\.sound) == ["흐", "오", "호"])
    }

    @Test("첫소리 ㅇ 은 소리가 없다고 알려 준다")
    func 첫소리_이응은_소리가_없다() throws {
        // given
        let syllable = try #require(Hangul.decompose("아"))

        // when
        let actual = Hangul.steps(for: syllable).first

        // then
        #expect(actual?.label == "ㅇ")
        #expect(actual?.sound == nil)
        #expect(actual?.caption == "이응 · 소리 없음")
    }

    @Test("받침 소리는 일곱 가지 대표 소리로 들려준다", arguments: [
        ("닭", "윽"),
        ("없", "읍"),
        ("옷", "읃"),
        ("밖", "윽"),
        ("앉", "은"),
        ("삶", "음"),
        ("잎", "읍"),
        ("곧", "읃"),
        ("말", "을"),
    ])
    func 받침_대표_소리(text: String, expected: String) throws {
        // given
        let syllable = try #require(Hangul.decompose(Character(text)))

        // when
        let actual = Hangul.steps(for: syllable)[3].sound

        // then
        #expect(actual == expected)
    }

    @Test("겹받침은 이름 대신 받침 모양을 보여 준다")
    func 겹받침_설명() throws {
        // given
        let syllable = try #require(Hangul.decompose("닭"))

        // when
        let actual = Hangul.steps(for: syllable)[3].caption

        // then
        #expect(actual == "받침 ㄺ")
    }

    @Test("단어장에 넣을 때 문장부호와 공백을 뗀다", arguments: [
        ("엄마!", "엄마"),
        ("\"토끼야,", "토끼야"),
        ("…", ""),
        ("3마리", "3마리"),
    ])
    func 문장부호를_뗀다(text: String, expected: String) {
        // when
        let actual = Hangul.cleanWord(text)

        // then
        #expect(actual == expected)
    }
}
