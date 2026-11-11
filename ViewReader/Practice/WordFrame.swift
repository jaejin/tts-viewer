import CoreGraphics

/// 찍은 사진 안에서 낱말이 있는 곳을 계산한다 (모두 좌상단 원점 0~1 좌표)
enum WordFrame {
    /// 상자에서 일부 글자만 골랐을 때 그 부분의 위치를 글자 수 비율로 어림한다.
    /// 한글은 글자 폭이 거의 같아 이 정도로도 표시 위치가 잘 맞는다.
    static func subFrame(of frame: CGRect, selecting range: ClosedRange<Int>, count: Int) -> CGRect {
        let lower = max(0, range.lowerBound)
        let upper = min(count - 1, range.upperBound)
        guard count > 0, lower <= upper else { return frame }

        let unit = frame.width / CGFloat(count)
        return CGRect(
            x: frame.minX + unit * CGFloat(lower),
            y: frame.minY,
            width: unit * CGFloat(upper - lower + 1),
            height: frame.height
        )
    }

    /// 낱말 앞뒤 줄까지 보이도록 사진을 띠로 자른다 — 어느 문장에서 나온 낱말인지 알 수 있게 하기 위해서다.
    /// 가로는 낱말을 가운데 두고 사진 폭의 일부만 잘라, 화면에 꽉 채웠을 때 사진 속 글자가 크게 보이게 한다.
    /// - Parameters:
    ///   - linesAround: 위아래로 더 보여 줄 줄 수 (낱말 높이 기준)
    ///   - minimumWidth: 앞뒤 문맥이 남도록 최소한 남길 사진 폭
    /// - Returns: band 는 사진에서 자를 띠, highlight 는 그 띠 안에서 낱말 위치
    static func sentenceBand(around frame: CGRect, linesAround: CGFloat = 1.5, minimumWidth: CGFloat = 0.6) -> (band: CGRect, highlight: CGRect) {
        let top = max(0, frame.minY - frame.height * linesAround)
        let bottom = min(1, frame.maxY + frame.height * linesAround)
        let height = bottom - top
        guard height > 0 else { return (VisibleArea.whole, frame) }

        let width = min(1, max(minimumWidth, frame.width * 3))
        // 낱말이 가장자리에 있으면 띠를 안쪽으로 밀어 사진 밖을 자르지 않는다
        let left = min(max(0, frame.midX - width / 2), 1 - width)

        let band = CGRect(x: left, y: top, width: width, height: height)
        let highlight = CGRect(
            x: (frame.minX - left) / width,
            y: (frame.minY - top) / height,
            width: frame.width / width,
            height: frame.height / height
        )
        return (band, highlight)
    }
}
