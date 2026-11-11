import Foundation

/// 카드 한 장을 읽어 주는 순서.
/// 낱말 전체 → (글자마다) 자음·모음 소리 → 그 글자 → 다시 낱말 전체 — 나눴다가 다시 합쳐 듣는 것을 반복하게 한다.
enum FlashcardScript {
    struct Cue: Equatable {
        /// 강조할 글자 위치. nil 이면 낱말 전체
        let syllableIndex: Int?
        /// 강조할 자음·모음 (Hangul.Step.id). nil 이면 글자 전체
        let stepID: Int?
        let sound: String
        /// 이 소리를 들려준 뒤 다음 소리까지 기다릴 시간(초)
        let pause: Double
    }

    static func cues(for word: String) -> [Cue] {
        var cues = [Cue(syllableIndex: nil, stepID: nil, sound: word, pause: 1.6)]

        for (index, character) in word.enumerated() {
            guard let syllable = Hangul.decompose(character) else {
                cues.append(Cue(syllableIndex: index, stepID: nil, sound: String(character), pause: 1.0))
                continue
            }
            for step in Hangul.steps(for: syllable) where step.kind != .combined {
                // 첫소리 ㅇ 처럼 소리가 없는 자리는 건너뛴다
                guard let sound = step.sound else { continue }
                cues.append(Cue(syllableIndex: index, stepID: step.id, sound: sound, pause: 1.0))
            }
            cues.append(Cue(syllableIndex: index, stepID: nil, sound: String(character), pause: 1.3))
        }

        cues.append(Cue(syllableIndex: nil, stepID: nil, sound: word, pause: 2.0))
        return cues
    }
}
