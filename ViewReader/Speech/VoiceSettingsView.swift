import SwiftUI

/// 한국어 목소리를 고르고 바로 들어 보는 화면
struct VoiceSettingsView: View {
    let model: ReaderViewModel
    @State private var voices: [VoiceOption] = []
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(voices) { voice in
                        Button {
                            model.selectVoice(voice.id)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(voice.name).foregroundStyle(.primary)
                                    Text(voice.quality.label)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if isSelected(voice) {
                                    Image(systemName: "checkmark").foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                    }
                } header: {
                    Text("누르면 그 목소리로 들어 볼 수 있습니다")
                } footer: {
                    Text("더 자연스러운 목소리는 iPhone의 설정 > 손쉬운 사용 > 읽기 및 말하기 > 음성 > 한국어에서 '고품질'·'프리미엄' 음성을 내려받으면 이 목록에 나타납니다. Siri 목소리는 다른 앱에서 쓸 수 없습니다.")
                }
            }
            .navigationTitle("목소리")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") { dismiss() }
                }
            }
            // 설정 앱에서 음성을 내려받고 돌아온 경우에도 새 목록이 보이도록 열 때마다 다시 읽는다
            .onAppear { voices = SpeechReader.koreanVoices() }
        }
    }

    /// 고른 적이 없으면 기기의 기본 한국어 음성을 쓰는데, 그 식별자는 기기마다 달라 체크 표시를 하지 않는다
    private func isSelected(_ voice: VoiceOption) -> Bool {
        model.speech.voiceIdentifier == voice.id
    }
}
