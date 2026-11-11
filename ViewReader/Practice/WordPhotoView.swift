import SwiftUI

/// 낱말을 찍은 사진을 보여 주고 낱말 자리를 표시한다.
/// 그림책은 글씨 아래 그 낱말을 나타내는 그림이 있는 경우가 많아 기본은 사진 전체를 보여 주고,
/// 누르면 글씨 줄만 크게 확대해 보여 준다.
struct WordPhotoView: View {
    let url: URL
    let wordFrame: CGRect

    @State private var fullImage: CGImage?
    @State private var showsSentenceOnly = false

    var body: some View {
        // 빈 Group 에 붙인 .task 는 실행되지 않는다 — 불러오기 전에도 자리를 차지하는 뷰가 있어야 한다
        ZStack {
            if let fullImage, let shown = displayed(from: fullImage) {
                Image(decorative: shown.image, scale: 1)
                    .resizable()
                    .scaledToFit()
                    .overlay {
                        GeometryReader { geometry in
                            let size = geometry.size
                            let highlight = shown.highlight
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.yellow.opacity(0.3))
                                .strokeBorder(Color.orange, lineWidth: 3)
                                .frame(width: highlight.width * size.width + 6, height: highlight.height * size.height + 6)
                                .position(x: highlight.midX * size.width, y: highlight.midY * size.height)
                        }
                    }
                    .overlay(alignment: .bottomTrailing) {
                        Label(showsSentenceOnly ? "전체 보기" : "문장 크게", systemImage: showsSentenceOnly ? "arrow.down.right.and.arrow.up.left" : "plus.magnifyingglass")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding(6)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) { showsSentenceOnly.toggle() }
                    }
                    .accessibilityLabel("낱말을 찍은 책 사진")
                    .accessibilityHint(showsSentenceOnly ? "누르면 사진 전체를 봅니다" : "누르면 문장을 크게 봅니다")
            } else {
                Color.clear.frame(height: 1)
            }
        }
        .task(id: url) {
            fullImage = UIImage(contentsOfFile: url.path)?.cgImage
        }
    }

    /// 보여 줄 이미지와 그 안에서 낱말 위치
    private func displayed(from image: CGImage) -> (image: CGImage, highlight: CGRect)? {
        guard showsSentenceOnly else { return (image, wordFrame) }

        let (band, highlight) = WordFrame.sentenceBand(around: wordFrame)
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)
        let crop = CGRect(x: band.minX * width, y: band.minY * height, width: band.width * width, height: band.height * height).integral
        guard let cropped = image.cropping(to: crop) else { return (image, wordFrame) }
        return (cropped, highlight)
    }
}
