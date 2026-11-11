import SwiftUI

/// 찍은 화면 위에 낱말마다 누를 수 있는 상자를 그린다
struct CapturedPageView: View {
    let page: CapturedPage
    /// 낱말을 골라낸 상자 — 표시만 하고, 같은 상자에서 더 골라낼 수 있게 다시 누를 수 있다
    let pickedBoxIndices: Set<Int>
    let onTapWord: (Int) -> Void

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            ZStack(alignment: .topLeading) {
                // 찍을 때 미리보기와 같은 비율로 잘랐으므로 꽉 채워도 화면과 어긋나지 않는다
                Image(decorative: page.image, scale: 1)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()

                ForEach(tappableIndices, id: \.self) { index in
                    let frame = page.words[index].frame
                    let isSelected = pickedBoxIndices.contains(index)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? Color.yellow.opacity(0.45) : Color.white.opacity(0.12))
                        .strokeBorder(isSelected ? Color.orange : Color.white.opacity(0.9), lineWidth: isSelected ? 3 : 1.5)
                        .frame(width: frame.width * size.width + 6, height: frame.height * size.height + 6)
                        .position(x: frame.midX * size.width, y: frame.midY * size.height)
                        // 누르기는 아래의 한 장짜리 영역이 맡는다 — 상자마다 받으면 겹친 곳에서 나중 상자가 이긴다
                        .allowsHitTesting(false)
                        .accessibilityElement()
                        .accessibilityLabel(page.words[index].text)
                        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
                        .accessibilityAction { onTapWord(index) }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { location in
                let point = CGPoint(x: location.x / size.width, y: location.y / size.height)
                // 아이 손가락으로도 누르기 쉽게 글자 바깥 12pt 까지는 그 상자로 인정한다
                let margin = CGSize(width: 12 / size.width, height: 12 / size.height)
                if let index = WordHitTest.index(at: point, in: tappableFrames, margin: margin) {
                    onTapWord(index)
                }
            }
        }
    }

    private var tappableFrames: [Int: CGRect] {
        Dictionary(uniqueKeysWithValues: tappableIndices.map { ($0, page.words[$0].frame) })
    }

    /// 쪽 번호나 문장부호만 있는 상자는 고를 필요가 없다
    private var tappableIndices: [Int] {
        page.words.indices.filter { !ReadingOrder.isNoise(page.words[$0].text) }
    }
}
