import SwiftUI

/// 누른 상자의 글자를 크게 펼쳐 놓고, 그중 낱말로 쓸 부분을 고르는 창.
/// OCR 이 글자를 붙여 읽었거나 조사까지 붙은 경우(토끼가 → 토끼)에 원하는 부분만 골라낼 수 있다.
struct WordPickerView: View {
    let model: ReaderViewModel
    let boxIndex: Int
    let boxFrame: CGRect

    @State private var selection: SyllableSelection
    @State private var message: String?
    @Environment(\.dismiss) private var dismiss

    init(model: ReaderViewModel, boxIndex: Int, boxText: String, boxFrame: CGRect) {
        self.model = model
        self.boxIndex = boxIndex
        self.boxFrame = boxFrame
        _selection = State(initialValue: SyllableSelection(text: boxText))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text(selection.isWaitingForEnd ? "끝 글자를 눌러 주세요" : "첫 글자와 끝 글자를 차례로 누르면\n그 사이만 고를 수 있어요")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)

                    tiles

                    Text(selection.selectedText.isEmpty ? " " : selection.selectedText)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)

                    HStack(spacing: 12) {
                        Button {
                            model.speech.speak(selection.selectedText)
                        } label: {
                            Label("듣기", systemImage: "speaker.wave.2.fill")
                        }
                        .buttonStyle(.bordered)

                        Button {
                            selection.selectAll()
                        } label: {
                            Label("전체", systemImage: "arrow.left.and.right")
                        }
                        .buttonStyle(.bordered)
                    }

                    Button {
                        pick()
                    } label: {
                        Text("이 낱말 고르기")
                            .font(.title3.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 48)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selection.selectedText.isEmpty || !model.canPickMore)

                    if let message {
                        Text(message).foregroundStyle(.orange)
                    } else if !model.canPickMore {
                        Text("한 번에 \(ReaderViewModel.maximumSelection)개까지 고를 수 있어요").foregroundStyle(.orange)
                    }
                }
                .padding(20)
            }
            .navigationTitle("낱말 고르기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }

    private var tiles: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 8)], spacing: 8) {
            ForEach(selection.characters.indices, id: \.self) { index in
                let isSelected = selection.range.contains(index)
                Button {
                    selection.tap(index)
                    message = nil
                    model.speech.speak(selection.selectedText)
                } label: {
                    Text(String(selection.characters[index]))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity, minHeight: 72)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isSelected ? Color.yellow.opacity(0.55) : Color(.secondarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(selection.anchor == index ? Color.orange : .clear, lineWidth: 3)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func pick() {
        let word = selection.selectedText
        if model.pickedWords.contains(where: { $0.text == word }) {
            message = "이미 고른 낱말이에요"
            return
        }
        let frame = WordFrame.subFrame(of: boxFrame, selecting: selection.range, count: selection.characters.count)
        if model.pick(word, fromBox: boxIndex, frame: frame) {
            dismiss()
        }
    }
}
