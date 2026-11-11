import SwiftUI

/// 낱말을 크게 보여 주고, 글자 하나를 자음·모음으로 나눠 소리를 합쳐 읽어 보는 화면
struct PracticeView: View {
    let entry: WordBook.Entry
    let wordBook: WordBook
    let speech: SpeechReader

    private var word: String { entry.text }

    /// 자음·모음 소리는 짧아서 평소보다 천천히 들려줘야 구분된다
    private let practiceRate: Float = 0.33

    @State private var selectedIndex = 0
    @State private var playingStepID: Int?
    @State private var playTask: Task<Void, Never>?
    @State private var isDeleteConfirmationPresented = false
    @Environment(\.dismiss) private var dismiss

    private var characters: [Character] { Array(word) }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                if let imageURL = wordBook.imageURL(for: entry), let wordFrame = entry.wordFrame {
                    WordPhotoView(url: imageURL, wordFrame: wordFrame)
                        .frame(maxHeight: 260)
                }
                wordRow
                Button {
                    stopPlaying()
                    speech.speak(word, rate: practiceRate)
                } label: {
                    Label("낱말 듣기", systemImage: "speaker.wave.2.fill")
                        .font(.title3.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)

                Divider()

                if let syllable = selectedSyllable {
                    decomposition(Hangul.steps(for: syllable))
                } else {
                    Text("한글 글자를 누르면\n자음과 모음으로 나눠 볼 수 있어요.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(20)
        }
        .navigationTitle(word)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { stopPlaying() }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("지우기", systemImage: "trash", role: .destructive) {
                    isDeleteConfirmationPresented = true
                }
            }
        }
        .confirmationDialog("'\(word)' 를 단어장에서 지울까요?", isPresented: $isDeleteConfirmationPresented, titleVisibility: .visible) {
            Button("지우기", role: .destructive) {
                stopPlaying()
                wordBook.remove(ids: [entry.id])
                dismiss()
            }
        }
    }

    private var selectedSyllable: Hangul.Syllable? {
        characters.indices.contains(selectedIndex) ? Hangul.decompose(characters[selectedIndex]) : nil
    }

    /// 낱말의 글자 하나하나를 버튼으로 — 누르면 그 글자를 나눠 본다
    private var wordRow: some View {
        HStack(spacing: 6) {
            ForEach(characters.indices, id: \.self) { index in
                Button {
                    stopPlaying()
                    selectedIndex = index
                    speech.speak(String(characters[index]), rate: practiceRate)
                } label: {
                    Text(String(characters[index]))
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.4)
                        .lineLimit(1)
                        .frame(minWidth: 64, minHeight: 84)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(index == selectedIndex ? Color.yellow.opacity(0.5) : Color(.secondarySystemBackground))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// 두 단계로 합친다: [ㄱ] + [ㅏ] = [가], [가] + [ㅇ] = [강]
    private func decomposition(_ steps: [Hangul.Step]) -> some View {
        VStack(spacing: 20) {
            equationRow(steps[0], steps[1], steps[2])
            if steps.count == 5 {
                equationRow(steps[2], steps[3], steps[4])
            }

            Button {
                play(steps)
            } label: {
                Label(playingStepID == nil ? "차례로 들어 보기" : "멈추기",
                      systemImage: playingStepID == nil ? "play.circle.fill" : "stop.circle.fill")
                    .font(.title3.weight(.semibold))
            }
            .buttonStyle(.bordered)

            Text("카드를 누르면 그 소리만 들을 수 있어요")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func equationRow(_ lhs: Hangul.Step, _ rhs: Hangul.Step, _ result: Hangul.Step) -> some View {
        HStack(spacing: 8) {
            card(lhs)
            Text("+").font(.title.bold()).foregroundStyle(.secondary)
            card(rhs)
            Text("=").font(.title.bold()).foregroundStyle(.secondary)
            card(result)
        }
    }

    private func card(_ step: Hangul.Step) -> some View {
        let isPlaying = playingStepID == step.id
        return Button {
            stopPlaying()
            if let sound = step.sound {
                speech.speak(sound, rate: practiceRate)
            }
        } label: {
            VStack(spacing: 4) {
                Text(step.label)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(color(for: step.kind))
                Text(step.caption.isEmpty ? " " : step.caption)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(width: 84, height: 96)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isPlaying ? Color.yellow.opacity(0.55) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(color(for: step.kind).opacity(0.5), lineWidth: 2)
            )
            .scaleEffect(isPlaying ? 1.08 : 1)
            .animation(.spring(duration: 0.25), value: isPlaying)
        }
        .buttonStyle(.plain)
    }

    /// 자음과 모음을 색으로 구분하면 글자 안의 자리를 익히기 쉽다
    private func color(for kind: Hangul.Step.Kind) -> Color {
        switch kind {
        case .consonant: .blue
        case .vowel: .red
        case .combined: .primary
        }
    }

    private func play(_ steps: [Hangul.Step]) {
        if playingStepID != nil {
            stopPlaying()
            return
        }
        playTask = Task {
            for step in steps {
                playingStepID = step.id
                if let sound = step.sound {
                    speech.speak(sound, rate: practiceRate)
                }
                try? await Task.sleep(for: .seconds(1.3))
                if Task.isCancelled { return }
            }
            playingStepID = nil
        }
    }

    private func stopPlaying() {
        playTask?.cancel()
        playTask = nil
        playingStepID = nil
    }
}
