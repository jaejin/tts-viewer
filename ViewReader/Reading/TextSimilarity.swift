import Foundation

/// 두 OCR 결과가 같은 글인지 비교한다.
/// OCR 은 프레임마다 한두 글자씩 다르게 읽기 때문에 완전 일치가 아니라 글자 2-gram 집합으로 비교한다.
enum TextSimilarity {
    static func bigrams(_ text: String) -> Set<String> {
        let characters = Array(text.lowercased().filter { !$0.isWhitespace && !$0.isPunctuation })
        guard characters.count >= 2 else {
            return characters.isEmpty ? [] : [String(characters)]
        }
        return Set((0..<characters.count - 1).map { String(characters[$0...$0 + 1]) })
    }

    /// Dice 계수 — 양쪽 크기를 모두 반영하므로 "연속 프레임이 같은 화면인가" 를 엄격하게 볼 때 쓴다
    static func dice(_ lhs: String, _ rhs: String) -> Double {
        let left = bigrams(lhs)
        let right = bigrams(rhs)
        guard !(left.isEmpty && right.isEmpty) else { return 1 }
        return 2.0 * Double(left.intersection(right).count) / Double(left.count + right.count)
    }

    /// 겹침 계수 — 작은 쪽 기준이라 손가락이 글 일부를 가려도 같은 쪽으로 판단할 수 있다
    static func overlap(_ lhs: String, _ rhs: String) -> Double {
        let left = bigrams(lhs)
        let right = bigrams(rhs)
        guard !(left.isEmpty && right.isEmpty) else { return 1 }

        let smaller = min(left.count, right.count)
        guard smaller > 0 else { return 0 }
        return Double(left.intersection(right).count) / Double(smaller)
    }
}
