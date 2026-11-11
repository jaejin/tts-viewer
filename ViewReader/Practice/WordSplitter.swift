import Foundation

/// OCR 한 줄을 낱말 단위로 나눈다.
/// 동화책은 글자 간격이 들쭉날쭉해 OCR 이 띄어쓰기를 자주 놓치므로, 문장부호에서도 끊어 한 덩어리가 되는 일을 줄인다.
enum WordSplitter {
    /// 낱말 사이를 끊는 문장부호. 영어 축약형(don't)이 갈라지지 않도록 ASCII 작은따옴표는 넣지 않는다
    private static let separators: Set<Character> = [
        ".", ",", "!", "?", "…", "·", "\"", "“", "”", "‘", "’", "(", ")", "「", "」", "『", "』", "~", ":", ";",
    ]

    static func ranges(in text: String) -> [Range<String.Index>] {
        var result: [Range<String.Index>] = []
        var start: String.Index?

        for index in text.indices {
            let character = text[index]
            if character.isWhitespace || separators.contains(character) {
                if let wordStart = start {
                    result.append(wordStart..<index)
                    start = nil
                }
            } else if start == nil {
                start = index
            }
        }
        if let wordStart = start {
            result.append(wordStart..<text.endIndex)
        }
        return result
    }
}
