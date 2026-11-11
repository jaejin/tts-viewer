import Foundation

/// 카메라에 비친 글을 계속 받아서 "새 쪽이 안정적으로 보이는 순간" 에만 읽을 글을 돌려준다.
/// 같은 쪽을 반복해서 읽거나, 책장을 넘기는 중의 흔들린 글을 읽는 일을 막는 역할이다.
struct PageChangeDetector {
    /// 연속 몇 번 비슷하게 인식되어야 흔들림이 아닌 실제 화면으로 볼지
    var requiredStableCount = 2
    /// 연속 프레임끼리 이 이상 비슷하면 같은 화면으로 본다
    var stableThreshold = 0.85
    /// 이미 읽은 쪽과 이 이상 겹치면 같은 쪽으로 본다
    var samePageThreshold = 0.7
    /// 2-gram 이 이보다 적은 짧은 글은 겹침 계수를 쓰지 않는다.
    /// "엄마!" 처럼 짧은 쪽은 앞 쪽 글에 대부분 포함되어 있어 겹침 계수로는 새 쪽을 놓치기 때문이다.
    var minimumBigramsForOverlap = 8
    var minimumLength = 2

    private(set) var lastRead: String?
    private var candidate: String?
    private var stableCount = 0

    /// - Returns: 새로 읽어야 할 쪽의 글. 읽을 것이 없으면 nil
    mutating func feed(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= minimumLength else {
            candidate = nil
            stableCount = 0
            return nil
        }

        if let candidate, TextSimilarity.dice(candidate, trimmed) >= stableThreshold {
            stableCount += 1
        } else {
            stableCount = 1
        }
        candidate = trimmed

        guard stableCount >= requiredStableCount else { return nil }
        if let lastRead, isSamePage(lastRead, trimmed) { return nil }

        lastRead = trimmed
        return trimmed
    }

    /// 지금 보이는 쪽을 처음부터 다시 읽게 할 때 쓴다
    mutating func reset() {
        lastRead = nil
        candidate = nil
        stableCount = 0
    }

    func isSamePage(_ lhs: String, _ rhs: String) -> Bool {
        let smaller = min(TextSimilarity.bigrams(lhs).count, TextSimilarity.bigrams(rhs).count)
        if smaller < minimumBigramsForOverlap {
            return TextSimilarity.dice(lhs, rhs) >= stableThreshold
        }
        return TextSimilarity.overlap(lhs, rhs) >= samePageThreshold
    }
}
