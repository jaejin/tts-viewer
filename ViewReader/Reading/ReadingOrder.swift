import CoreGraphics
import Foundation

/// OCR 줄들을 사람이 책을 읽는 순서(왼쪽 쪽 → 오른쪽 쪽, 위 → 아래, 왼쪽 → 오른쪽)로 이어 붙인다.
/// Vision 결과는 순서가 보장되지 않고, 펼친 책은 두 쪽이 한 화면에 섞여 들어오기 때문에 직접 정렬한다.
enum ReadingOrder {
    /// 가운데 접힌 선을 이만큼 넘어 걸친 줄이 있으면 펼친 두 쪽이 아니라 한 쪽짜리로 본다
    static let spineMargin: CGFloat = 0.05
    /// 줄 사이 빈 공간이 줄 높이보다 크면 문단이 바뀐 것으로 보고 끊어 읽는다
    static let paragraphGapRatio: CGFloat = 1.0

    static func compose(_ lines: [TextLine]) -> String {
        let content = lines.filter { !isNoise($0.text) }
        guard !content.isEmpty else { return "" }

        return columns(of: content)
            .map(composeColumn)
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    /// 쪽 번호("12", "- 12 -")나 장식 기호만 있는 줄은 소리 내어 읽을 필요가 없다
    static func isNoise(_ text: String) -> Bool {
        let meaningful = text.filter { $0.isLetter || $0.isNumber }
        return meaningful.isEmpty || meaningful.allSatisfy(\.isNumber)
    }

    static func columns(of lines: [TextLine]) -> [[TextLine]] {
        let crossesSpine = lines.contains {
            $0.frame.minX < 0.5 - spineMargin && $0.frame.maxX > 0.5 + spineMargin
        }
        let left = lines.filter { $0.frame.midX < 0.5 }
        let right = lines.filter { $0.frame.midX >= 0.5 }

        if crossesSpine || left.isEmpty || right.isEmpty {
            return [lines]
        }
        return [left, right]
    }

    private struct Row {
        var lines: [TextLine]
        var frame: CGRect

        var text: String {
            lines.sorted { $0.frame.minX < $1.frame.minX }
                .map { $0.text.trimmingCharacters(in: .whitespaces) }
                .joined(separator: " ")
        }
    }

    /// 높이가 같은 줄 조각(예: 그림 양옆으로 나뉜 글)은 한 줄로 묶는다
    private static func rows(of lines: [TextLine]) -> [Row] {
        var rows: [Row] = []
        for line in lines.sorted(by: { $0.frame.midY < $1.frame.midY }) {
            if let last = rows.last,
               abs(line.frame.midY - last.frame.midY) < min(line.frame.height, last.frame.height) * 0.5 {
                rows[rows.count - 1].lines.append(line)
                rows[rows.count - 1].frame = last.frame.union(line.frame)
            } else {
                rows.append(Row(lines: [line], frame: line.frame))
            }
        }
        return rows
    }

    private static func composeColumn(_ lines: [TextLine]) -> String {
        var result = ""
        var previous: Row?

        for row in rows(of: lines) {
            let text = row.text
            if let previous {
                let gap = row.frame.minY - previous.frame.maxY
                if gap > previous.frame.height * paragraphGapRatio {
                    result += "\n"
                } else if endsWithHyphenatedWord(result), text.first?.isLowercase == true {
                    // 영어 원서에서 줄 끝 하이픈으로 잘린 단어를 붙여야 TTS 가 한 단어로 읽는다
                    result.removeLast()
                } else {
                    result += " "
                }
            }
            result += text
            previous = row
        }
        return result
    }

    private static func endsWithHyphenatedWord(_ text: String) -> Bool {
        guard text.hasSuffix("-"), let beforeHyphen = text.dropLast().last else { return false }
        return beforeHyphen.isASCII && beforeHyphen.isLetter
    }
}
