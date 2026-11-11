import SwiftUI

/// 모은 낱말을 카드로 넘겨 보며, 글자를 자음·모음으로 나눴다가 합쳐 읽기를 반복한다
struct FlashcardView: View {
    let wordBook: WordBook
    let speech: SpeechReader

    /// 자음·모음 소리는 짧아서 평소보다 천천히 들려줘야 구분된다
    private let practiceRate: Float = 0.33

    @State private var order: [WordBook.Entry] = []
    @State private var current = 0
    @State private var activeCue: FlashcardScript.Cue?
    @State private var isRepeating = false
    @State private var playTask: Task<Void, Never>?
    /// 자동으로 다음 카드로 넘길 때는 손으로 넘긴 것으로 보지 않기 위한 표시
    @State private var isAdvancingAutomatically = false

    var body: some View {
        VStack(spacing: 16) {
            if order.isEmpty {
                ContentUnavailableView("카드가 없어요", systemImage: "rectangle.on.rectangle.slash")
            } else {
                TabView(selection: $current) {
                    ForEach(order.indices, id: \.self) { index in
                        FlashcardCardView(
                            entry: order[index],
                            imageURL: wordBook.imageURL(for: order[index]),
                            activeCue: index == current ? activeCue : nil,
                            onTapWord: { playCurrentCard() }
                        )
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                Text("\(current + 1) / \(order.count)")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                controls
            }
        }
        .padding(.bottom, 16)
        .navigationTitle("카드 연습")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if order.isEmpty {
                order = wordBook.entries
            }
        }
        .onDisappear { stop() }
        .onChange(of: current) {
            if isAdvancingAutomatically {
                isAdvancingAutomatically = false
            } else if isRepeating {
                // 반복 중에 손으로 넘기면 넘긴 카드부터 이어서 반복한다
                startRepeating()
            } else {
                stop()
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 20) {
            Button {
                move(by: -1)
            } label: {
                Image(systemName: "chevron.left.circle.fill").font(.system(size: 40))
            }
            .accessibilityLabel("이전 카드")

            Button {
                isRepeating ? stop() : startRepeating()
            } label: {
                Label(isRepeating ? "멈추기" : "반복 재생", systemImage: isRepeating ? "stop.fill" : "repeat")
                    .font(.title3.weight(.semibold))
                    .frame(minWidth: 130, minHeight: 48)
            }
            .buttonStyle(.borderedProminent)

            Button {
                move(by: 1)
            } label: {
                Image(systemName: "chevron.right.circle.fill").font(.system(size: 40))
            }
            .accessibilityLabel("다음 카드")

            Button {
                stop()
                order.shuffle()
                current = 0
            } label: {
                Image(systemName: "shuffle").font(.title2)
            }
            .accessibilityLabel("카드 섞기")
        }
    }

    private func move(by offset: Int) {
        guard !order.isEmpty else { return }
        withAnimation {
            current = (current + offset + order.count) % order.count
        }
    }

    /// 낱말을 누르면 지금 카드만 한 번 읽어 준다
    private func playCurrentCard() {
        stop()
        play(repeating: false)
    }

    private func startRepeating() {
        stop()
        isRepeating = true
        play(repeating: true)
    }

    private func play(repeating: Bool) {
        playTask = Task {
            repeat {
                guard order.indices.contains(current) else { break }
                for cue in FlashcardScript.cues(for: order[current].text) {
                    activeCue = cue
                    speech.speak(cue.sound, rate: practiceRate)
                    try? await Task.sleep(for: .seconds(cue.pause))
                    if Task.isCancelled { return }
                }
                activeCue = nil
                guard repeating else { break }

                try? await Task.sleep(for: .seconds(0.8))
                if Task.isCancelled { return }
                // 마지막 카드 다음에는 처음으로 돌아가 계속 반복한다
                isAdvancingAutomatically = true
                withAnimation {
                    current = (current + 1) % order.count
                }
            } while !Task.isCancelled
        }
    }

    private func stop() {
        playTask?.cancel()
        playTask = nil
        activeCue = nil
        isRepeating = false
        speech.stop()
    }
}

/// 카드 한 장: 찍은 문장 사진, 큰 낱말, 글자마다 자음·모음
private struct FlashcardCardView: View {
    let entry: WordBook.Entry
    let imageURL: URL?
    let activeCue: FlashcardScript.Cue?
    let onTapWord: () -> Void

    private let columnSpacing: CGFloat = 8
    /// 사진이 남는 공간을 모두 쓰도록 글자 칸은 높이를 고정한다
    private let syllableRowHeight: CGFloat = 170

    var body: some View {
        VStack(spacing: 16) {
            if let imageURL, let wordFrame = entry.wordFrame {
                // 그림책은 글씨 아래 그림이 낱말 뜻을 보여 주므로 사진 전체가 들어가게 남는 공간을 다 쓴다
                WordPhotoView(url: imageURL, wordFrame: wordFrame)
                    .frame(maxHeight: .infinity)
            }

            Button(action: onTapWord) {
                Text(entry.text)
                    .font(.system(size: 72, weight: .heavy, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.3)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(isWholeWordActive ? Color.yellow.opacity(0.55) : .clear)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityHint("누르면 읽어 줍니다")

            // 글자 수에 맞춰 칸 폭을 나누고, 그 폭에 맞게 글자 크기를 정한다 — 짧은 낱말일수록 크게 보인다
            GeometryReader { geometry in
                let count = max(1, entry.text.count)
                let columnWidth = (geometry.size.width - columnSpacing * CGFloat(count - 1)) / CGFloat(count)
                HStack(alignment: .top, spacing: columnSpacing) {
                    ForEach(Array(entry.text.enumerated()), id: \.offset) { index, character in
                        syllableColumn(index: index, character: character, width: columnWidth)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .frame(height: syllableRowHeight)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
        )
    }

    private var isWholeWordActive: Bool {
        activeCue != nil && activeCue?.syllableIndex == nil
    }

    private func syllableColumn(index: Int, character: Character, width: CGFloat) -> some View {
        let isActive = activeCue?.syllableIndex == index
        let jamos = Hangul.decompose(character).map { Hangul.steps(for: $0).filter { $0.kind != .combined } } ?? []
        let syllableSize = min(76, width * 0.7)
        // 자음·모음은 최대 세 개가 한 줄에 놓이므로 칸 폭의 1/3 보다 조금 작게
        let jamoSize = min(46, width * 0.3)

        return VStack(spacing: 6) {
            Text(String(character))
                .font(.system(size: syllableSize, weight: .bold, design: .rounded))
            HStack(spacing: 2) {
                ForEach(jamos) { step in
                    let isJamoActive = isActive && activeCue?.stepID == step.id
                    Text(step.label)
                        .font(.system(size: jamoSize, weight: .bold, design: .rounded))
                        .foregroundStyle(step.kind == .vowel ? Color.red : Color.blue)
                        // 소리 없는 첫소리 ㅇ 은 흐리게 보여 준다
                        .opacity(step.sound == nil ? 0.35 : 1)
                        .padding(.horizontal, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isJamoActive ? Color.yellow : .clear)
                        )
                        .scaleEffect(isJamoActive ? 1.2 : 1)
                        .animation(.spring(duration: 0.25), value: isJamoActive)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.5)
        }
        .padding(.vertical, 10)
        .frame(width: width)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isActive ? Color.yellow.opacity(0.3) : Color(.tertiarySystemGroupedBackground))
        )
    }
}
