import CoreGraphics
import Testing
@testable import ViewReader

@Suite("보이는 영역 계산")
struct VisibleAreaTests {
    @Test("화면이 이미지보다 납작하면 위아래가 잘린 가운데 부분만 보인다")
    func 납작한_화면은_위아래가_잘린다() {
        // given — 세로 이미지(9:16)를 가로로 긴 위쪽 영역(1:1)에 채움
        let imageSize = CGSize(width: 1080, height: 1920)
        let viewSize = CGSize(width: 400, height: 400)

        // when
        let actual = VisibleArea.rect(viewSize: viewSize, imageSize: imageSize)

        // then — 폭은 전부, 높이는 1080/1920 만큼만 보임
        let expectedHeight = 1080.0 / 1920.0
        #expect(actual.minX == 0)
        #expect(actual.width == 1)
        #expect(abs(actual.height - expectedHeight) < 0.0001)
        #expect(abs(actual.minY - (1 - expectedHeight) / 2) < 0.0001)
    }

    @Test("화면이 이미지보다 길쭉하면 좌우가 잘린다")
    func 길쭉한_화면은_좌우가_잘린다() {
        // given
        let imageSize = CGSize(width: 1080, height: 1920)
        let viewSize = CGSize(width: 100, height: 400)

        // when
        let actual = VisibleArea.rect(viewSize: viewSize, imageSize: imageSize)

        // then
        let expectedWidth = (100.0 / 400.0) / (1080.0 / 1920.0)
        #expect(actual.height == 1)
        #expect(abs(actual.width - expectedWidth) < 0.0001)
        #expect(abs(actual.midX - 0.5) < 0.0001)
    }

    @Test("크기를 아직 모르면 이미지 전체를 쓴다")
    func 크기를_모르면_전체() {
        // when
        let actualNoView = VisibleArea.rect(viewSize: .zero, imageSize: CGSize(width: 1080, height: 1920))
        let actualNoImage = VisibleArea.rect(viewSize: CGSize(width: 100, height: 100), imageSize: .zero)

        // then
        #expect(actualNoView == VisibleArea.whole)
        #expect(actualNoImage == VisibleArea.whole)
    }

    @Test("가운데가 보이는 영역 안에 있는 줄만 남긴다")
    func 보이는_영역의_줄만_남긴다() {
        // given
        let area = CGRect(x: 0, y: 0.2, width: 1, height: 0.5)
        let inside = TextLine(text: "보이는 줄", frame: CGRect(x: 0.1, y: 0.3, width: 0.8, height: 0.04))
        // 영역 아래 경계(0.7)에 걸친 두 줄 — 가운데가 안쪽(0.69)이면 남기고, 바깥(0.72)이면 뺀다
        let onEdge = TextLine(text: "경계에 걸쳤지만 가운데는 안", frame: CGRect(x: 0.1, y: 0.65, width: 0.8, height: 0.08))
        let peeking = TextLine(text: "경계에 걸쳤고 가운데는 밖", frame: CGRect(x: 0.1, y: 0.68, width: 0.8, height: 0.08))
        let below = TextLine(text: "아래쪽 줄", frame: CGRect(x: 0.1, y: 0.9, width: 0.8, height: 0.04))

        // when
        let actual = VisibleArea.filter([inside, onEdge, peeking, below], in: area)

        // then
        #expect(actual == [inside, onEdge])
    }
}
