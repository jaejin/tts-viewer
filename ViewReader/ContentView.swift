import SwiftUI

struct ContentView: View {
    @State private var model = ReaderViewModel()
    @State private var isVoiceSettingsPresented = false
    @State private var isWordBookPresented = false
    @State private var toastMessage: String?
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 12) {
            readingArea
            pageTextPanel
            controls
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .background(Color(.systemGroupedBackground))
        .task { await model.start() }
        .onAppear {
            // 책을 읽어 주는 동안 화면이 꺼지면 카메라도 멈추므로 자동 잠금을 끈다
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                model.resumeCamera()
            } else {
                model.suspendCamera()
            }
        }
        .sheet(isPresented: $isVoiceSettingsPresented) {
            VoiceSettingsView(model: model)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: Binding(
            get: { model.pickingBoxIndex != nil },
            set: { if !$0 { model.pickingBoxIndex = nil } }
        )) {
            if let index = model.pickingBoxIndex, let page = model.capturedPage, page.words.indices.contains(index) {
                WordPickerView(model: model, boxIndex: index, boxText: page.words[index].text, boxFrame: page.words[index].frame)
                    .id(index)
                    .presentationDetents([.medium, .large])
            }
        }
        .sheet(isPresented: $isWordBookPresented) {
            WordBookView(wordBook: model.wordBook, speech: model.speech)
        }
        .overlay(alignment: .top) {
            if let toastMessage {
                Text(toastMessage)
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.regularMaterial, in: Capsule())
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.default, value: toastMessage)
    }

    /// 카메라는 이 영역에만 보이고, 여기 보이는 글만 읽는다 — 보이는 글과 읽는 글이 같아야 아이가 헷갈리지 않는다
    private var readingArea: some View {
        CameraPreview(session: model.camera.session)
            .onGeometryChange(for: CGSize.self) { $0.size } action: { size in
                model.updatePreviewSize(size)
            }
            .overlay {
                if let page = model.capturedPage {
                    CapturedPageView(page: page, pickedBoxIndices: Set(model.pickedWords.map(\.boxIndex))) { index in
                        model.openBox(at: index)
                    }
                }
            }
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.accentColor, lineWidth: 3)
            }
            .overlay(alignment: .top) {
                Label(areaTitle, systemImage: model.capturedPage == nil ? "text.viewfinder" : "hand.tap.fill")
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.top, 10)
            }
            .overlay(alignment: .topTrailing) {
                if !model.isInCaptureMode {
                    Button {
                        isVoiceSettingsPresented = true
                    } label: {
                        Image(systemName: "person.wave.2.fill")
                            .font(.title3)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .accessibilityLabel("목소리 바꾸기")
                    .padding(8)
                }
            }
            .overlay(alignment: .bottom) {
                captureControls.padding(14)
            }
            .overlay {
                if model.cameraAccess == .denied {
                    deniedMessage
                } else if model.isCapturing {
                    ProgressView("글자를 찾고 있어요")
                        .padding(20)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                } else if let page = model.capturedPage, page.words.isEmpty {
                    Text("글자를 찾지 못했어요.\n다시 찍어 보세요.")
                        .multilineTextAlignment(.center)
                        .padding(20)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
            }
            .frame(maxHeight: .infinity)
    }

    private var areaTitle: String {
        guard model.capturedPage != nil else { return "이 안의 글을 읽어요" }
        return "모을 낱말을 눌러 보세요 (\(model.pickedWords.count)/\(ReaderViewModel.maximumSelection))"
    }

    /// 아이가 직접 누르는 큰 셔터 — 찍은 뒤에는 "다시 찍기 / 단어장에 넣기" 로 바뀐다
    @ViewBuilder
    private var captureControls: some View {
        if model.capturedPage != nil {
            VStack(spacing: 10) {
                if !model.pickedWords.isEmpty {
                    pickedWordChips
                }
                HStack(spacing: 12) {
                Button {
                    model.closeCapture()
                } label: {
                    Label("돌아가기", systemImage: "xmark")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                Button {
                    let count = model.savePickedWords()
                    showToast("단어장에 \(count)개 넣었어요")
                } label: {
                    Label("단어장에 넣기", systemImage: "tray.and.arrow.down.fill")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.pickedWords.isEmpty)
                }
            }
            .font(.headline)
        } else if model.cameraAccess == .granted {
            Button {
                Task { await model.capturePage() }
            } label: {
                ZStack {
                    Circle().fill(.white).frame(width: 64, height: 64)
                    Circle().strokeBorder(.white, lineWidth: 4).frame(width: 78, height: 78)
                    Image(systemName: "camera.fill").font(.title2).foregroundStyle(.black)
                }
            }
            .disabled(model.isCapturing)
            .accessibilityLabel("글자 찍기")
        }
    }

    /// 고른 낱말 — 누르면 빼낸다
    private var pickedWordChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(model.pickedWords) { word in
                    Button {
                        model.unpick(word)
                    } label: {
                        HStack(spacing: 4) {
                            Text(word.text).font(.headline)
                            Image(systemName: "xmark.circle.fill").font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.yellow, in: Capsule())
                        .foregroundStyle(.black)
                    }
                    .accessibilityLabel("\(word.text) 빼기")
                }
            }
        }
    }

    private func showToast(_ message: String) {
        toastMessage = message
        Task {
            try? await Task.sleep(for: .seconds(2))
            if toastMessage == message {
                toastMessage = nil
            }
        }
    }

    private var pageTextPanel: some View {
        ScrollView {
            Group {
                if model.pageText.isEmpty {
                    Text("위 화면에 책을 비춰 주세요.")
                        .foregroundStyle(.secondary)
                } else {
                    Text(highlightedPageText)
                }
            }
            .font(.title3)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 130)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    /// 읽고 있는 단어를 강조해 아이가 글자와 소리를 맞춰 볼 수 있게 한다
    private var highlightedPageText: AttributedString {
        let text = model.pageText
        var attributed = AttributedString(text)
        if model.speech.spokenText == text,
           let range = model.speech.spokenRange,
           let stringRange = Range(range, in: text),
           let attributedRange = Range(stringRange, in: attributed) {
            attributed[attributedRange].backgroundColor = .yellow
            attributed[attributedRange].foregroundColor = .black
        }
        return attributed
    }

    private var controls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ControlButton(title: "다시 읽기", systemImage: "arrow.counterclockwise") {
                    model.readAgain()
                }
                .disabled(model.pageText.isEmpty)

                ControlButton(
                    title: model.speech.isPaused ? "계속" : "잠깐 멈춤",
                    systemImage: model.speech.isPaused ? "play.fill" : "pause.fill"
                ) {
                    model.togglePause()
                }
                .disabled(!model.speech.isSpeaking)

                ControlButton(
                    title: model.isAutoReadOn ? "자동 읽기 끄기" : "자동 읽기 켜기",
                    systemImage: model.isAutoReadOn ? "speaker.wave.2.fill" : "speaker.slash.fill"
                ) {
                    model.toggleAutoRead()
                }

                ControlButton(title: "단어장", systemImage: "character.book.closed.fill") {
                    isWordBookPresented = true
                }
            }

            HStack {
                Image(systemName: "tortoise.fill")
                Slider(
                    value: Binding(get: { model.speech.rate }, set: { model.speech.rate = $0 }),
                    in: 0.3...0.6
                )
                Image(systemName: "hare.fill")
            }
            .foregroundStyle(.secondary)
            .accessibilityLabel("읽기 속도")
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var deniedMessage: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.fill").font(.largeTitle)
            Text("책을 보려면 카메라 권한이 필요합니다.\n설정 > 개인정보 보호 > 카메라에서 허용해 주십시오.")
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding()
    }
}

/// 아이도 누르기 쉽게 큰 터치 영역을 가진 버튼
private struct ControlButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage).font(.title2)
                Text(title)
                    .font(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, minHeight: 56)
        }
        .buttonStyle(.bordered)
    }
}

#Preview {
    ContentView()
}
