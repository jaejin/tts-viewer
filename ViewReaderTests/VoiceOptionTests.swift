import Testing
@testable import ViewReader

@Suite("목소리 목록")
struct VoiceOptionTests {
    @Test("품질이 높은 목소리가 먼저 오고, 같은 품질은 이름 순으로 정렬한다")
    func 품질_높은_순_같으면_이름_순() {
        // given
        let options = [
            VoiceOption(id: "a", name: "유나", quality: .standard),
            VoiceOption(id: "b", name: "민수", quality: .premium),
            VoiceOption(id: "c", name: "나리", quality: .standard),
            VoiceOption(id: "d", name: "유나", quality: .enhanced),
        ]

        // when
        let actual = VoiceOption.sorted(options).map(\.id)

        // then
        let expected = ["b", "d", "c", "a"]
        #expect(actual == expected)
    }

    @Test("품질 이름", arguments: [
        (VoiceOption.Quality.standard, "기본"),
        (.enhanced, "고품질"),
        (.premium, "프리미엄"),
    ])
    func 품질_이름(quality: VoiceOption.Quality, expected: String) {
        // when
        let actual = quality.label

        // then
        #expect(actual == expected)
    }
}
