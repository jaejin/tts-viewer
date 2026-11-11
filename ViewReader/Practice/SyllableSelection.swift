import Foundation

/// 상자 안 글자 중 낱말로 쓸 부분을 고른다.
/// 첫 글자를 누르고 끝 글자를 누르면 그 사이가 골라진다 — 아이가 끌기보다 누르기를 더 정확하게 하기 때문이다.
struct SyllableSelection: Equatable {
    let characters: [Character]
    private(set) var range: ClosedRange<Int>
    /// 첫 글자를 누르고 끝 글자를 기다리는 중이면 그 첫 글자 위치
    private(set) var anchor: Int?

    init(text: String) {
        characters = Array(Hangul.cleanWord(text))
        range = 0...max(0, characters.count - 1)
    }

    var selectedText: String {
        characters.isEmpty ? "" : String(characters[range])
    }

    var isWaitingForEnd: Bool { anchor != nil }

    mutating func tap(_ index: Int) {
        guard characters.indices.contains(index) else { return }

        if let start = anchor {
            range = min(start, index)...max(start, index)
            anchor = nil
        } else {
            range = index...index
            anchor = index
        }
    }

    /// 다시 상자 전체를 고른다
    mutating func selectAll() {
        range = 0...max(0, characters.count - 1)
        anchor = nil
    }
}
