import Foundation

/// 한글 음절을 초성·중성·종성으로 나누고, 읽기 연습에 쓸 "소리" 를 만든다.
/// 읽기를 배울 때는 자음 이름(기역)보다 소리(그)로 익혀야 글자를 합쳐 읽기 쉬우므로 소리를 기준으로 한다.
enum Hangul {
    private static let syllableBase = 0xAC00
    private static let syllableLast = 0xD7A3
    private static let medialCount = 21
    private static let finalCount = 28

    private static let initialIeung = 11
    private static let medialEu = 18

    static let initials = ["ㄱ", "ㄲ", "ㄴ", "ㄷ", "ㄸ", "ㄹ", "ㅁ", "ㅂ", "ㅃ", "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅉ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"]
    static let initialNames = ["기역", "쌍기역", "니은", "디귿", "쌍디귿", "리을", "미음", "비읍", "쌍비읍", "시옷", "쌍시옷", "이응", "지읒", "쌍지읒", "치읓", "키읔", "티읕", "피읖", "히읗"]
    static let medials = ["ㅏ", "ㅐ", "ㅑ", "ㅒ", "ㅓ", "ㅔ", "ㅕ", "ㅖ", "ㅗ", "ㅘ", "ㅙ", "ㅚ", "ㅛ", "ㅜ", "ㅝ", "ㅞ", "ㅟ", "ㅠ", "ㅡ", "ㅢ", "ㅣ"]
    /// 인덱스 0 은 받침 없음
    static let finals = ["", "ㄱ", "ㄲ", "ㄳ", "ㄴ", "ㄵ", "ㄶ", "ㄷ", "ㄹ", "ㄺ", "ㄻ", "ㄼ", "ㄽ", "ㄾ", "ㄿ", "ㅀ", "ㅁ", "ㅂ", "ㅄ", "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"]

    /// 받침은 실제로 일곱 가지 소리(ㄱ ㄴ ㄷ ㄹ ㅁ ㅂ ㅇ)로만 나므로, 소리를 들려줄 때는 대표 받침으로 바꾼다
    private static let representativeFinal: [Int: Int] = [
        1: 1, 2: 1, 3: 1, 9: 1, 24: 1,
        4: 4, 5: 4, 6: 4,
        7: 7, 19: 7, 20: 7, 22: 7, 23: 7, 25: 7, 27: 7,
        8: 8, 11: 8, 12: 8, 13: 8, 15: 8,
        16: 16, 10: 16,
        17: 17, 14: 17, 18: 17, 26: 17,
        21: 21,
    ]

    struct Syllable: Equatable {
        let initial: Int
        let medial: Int
        let final: Int

        var hasFinal: Bool { final != 0 }
        var openSyllable: String { Hangul.compose(initial: initial, medial: medial) }
        var whole: String { Hangul.compose(initial: initial, medial: medial, final: final) }
    }

    struct Step: Equatable, Identifiable {
        enum Kind: Equatable {
            case consonant
            case vowel
            case combined
        }

        let id: Int
        let label: String
        let caption: String
        /// 소리 내어 읽을 글. ㅇ 초성처럼 소리가 없으면 nil
        let sound: String?
        let kind: Kind
    }

    static func decompose(_ character: Character) -> Syllable? {
        guard let scalar = character.unicodeScalars.first,
              character.unicodeScalars.count == 1,
              (syllableBase...syllableLast).contains(Int(scalar.value)) else { return nil }

        let offset = Int(scalar.value) - syllableBase
        return Syllable(
            initial: offset / (medialCount * finalCount),
            medial: (offset % (medialCount * finalCount)) / finalCount,
            final: offset % finalCount
        )
    }

    static func compose(initial: Int, medial: Int, final: Int = 0) -> String {
        let value = syllableBase + (initial * medialCount + medial) * finalCount + final
        return String(Character(UnicodeScalar(value)!))
    }

    /// 연습 순서: 초성 → 중성 → (초성+중성) → 받침 → 전체 글자
    static func steps(for syllable: Syllable) -> [Step] {
        let isSilentInitial = syllable.initial == initialIeung
        var steps = [
            Step(
                id: 0,
                label: initials[syllable.initial],
                caption: isSilentInitial ? "이응 · 소리 없음" : initialNames[syllable.initial],
                sound: isSilentInitial ? nil : compose(initial: syllable.initial, medial: medialEu),
                kind: .consonant
            ),
            Step(
                id: 1,
                label: medials[syllable.medial],
                caption: compose(initial: initialIeung, medial: syllable.medial),
                sound: compose(initial: initialIeung, medial: syllable.medial),
                kind: .vowel
            ),
            Step(id: 2, label: syllable.openSyllable, caption: "", sound: syllable.openSyllable, kind: .combined),
        ]

        guard syllable.hasFinal else { return steps }

        let finalJamo = finals[syllable.final]
        let finalName = initials.firstIndex(of: finalJamo).map { initialNames[$0] }
        let finalSound = compose(initial: initialIeung, medial: medialEu, final: representativeFinal[syllable.final] ?? syllable.final)
        steps.append(Step(id: 3, label: finalJamo, caption: "받침 " + (finalName ?? finalJamo), sound: finalSound, kind: .consonant))
        steps.append(Step(id: 4, label: syllable.whole, caption: "", sound: syllable.whole, kind: .combined))
        return steps
    }

    /// 단어장에 넣을 때 문장부호("엄마!")를 떼어 낸다
    static func cleanWord(_ text: String) -> String {
        text.filter { $0.isLetter || $0.isNumber }
    }
}
